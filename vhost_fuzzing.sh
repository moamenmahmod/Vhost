#!/bin/bash

# === Banner ===
echo -e "\n\e[1;35m[ Recursive Vhost Pro ]\e[0m"
echo -e "\e[1;36mBy: Mo'a  |  Fully Automated Vhost Enumerator\e[0m\n"


# === FLAG PARSING ===
while getopts "t:b:w:a:l:h" opt; do
  case $opt in
    t) TARGET_NAME="$OPTARG" ;;
    b) BASE_DIR="$OPTARG" ;;
    w) WORDLIST="$OPTARG" ;;
    a) WILDCARD_DOMAINS_FILE="$OPTARG" ;;
    l) MAX_LEVEL="$OPTARG" ;;
    h)
         echo -e "\e[1;32mUsage:\e[0m $0 -t TARGET -b BASE_DIR -w WORDLIST -a DOMAINS_FILE -l MAX_LEVEL"
         echo -e "\n\e[1;33mRequired Flags:\e[0m"
         echo -e "  \e[1;32m-t\e[0m  Target name            (e.g., google)"
         echo -e "  \e[1;32m-b\e[0m  Base directory path    (e.g., ~/bugbounty/targets)"
         echo -e "  \e[1;32m-w\e[0m  Wordlist file          (e.g., ~/wordlists/dns.txt)"
         echo -e "  \e[1;32m-a\e[0m  Wildcard domains file  (e.g., wildcard_domains.txt)"
         echo -e "  \e[1;32m-l\e[0m  Max recursion level    (e.g., 5)"
         echo -e "  \e[1;32m-h\e[0m  Show this help menu"
         echo -e "\n\e[1;33mExample:\e[0m"
         echo -e "  $0 -t google -b ~/bugbounty/targets -w ~/wordlists/dns.txt -a wildcard_domains.txt -l 5"
         echo -e ""
         exit 0
         ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

# === VALIDATION ===
if [ -z "$TARGET_NAME" ] || [ -z "$BASE_DIR" ] || [ -z "$WORDLIST" ] || [ -z "$WILDCARD_DOMAINS_FILE" ] || [ -z "$MAX_LEVEL" ]; then
  echo "[!] Missing required flags"
  echo "Usage: $0 -t TARGET_NAME -b BASE_DIR -w WORDLIST -a WILDCARD_DOMAINS_FILE -l MAX_LEVEL"
  exit 1
fi

# === CALCULATED DIRS ===
SUBDOMAINS_DIR="$BASE_DIR/$TARGET_NAME/subdomains"
THREADS=5  # Parallel threads

# === CD TO TARGET DIR ===
cd "$SUBDOMAINS_DIR" || { echo "[!] Failed to cd to $SUBDOMAINS_DIR"; exit 1; }

# === BACKUP /etc/hosts ===
if [ ! -f "/etc/hosts.bak" ]; then
    echo "[*] Backing up /etc/hosts to /etc/hosts.bak"
    sudo cp /etc/hosts /etc/hosts.bak
else
    echo "[*] Backup /etc/hosts.bak already exists"
fi

# === INIT VHOSTS DIR ===
mkdir -p "$SUBDOMAINS_DIR/vhosts"

process_domain() {
    TARGET_DOMAIN="$1"

    echo -e "\n[***] Processing $TARGET_DOMAIN ***]"

    TARGET_IP=$(dig +short "$TARGET_DOMAIN" | head -n1)
    if [ -z "$TARGET_IP" ]; then
        echo "[!] Failed to resolve $TARGET_DOMAIN. Skipping."
        return
    fi
    echo "[*] $TARGET_DOMAIN resolved to $TARGET_IP"

    DOMAIN_VHOST_DIR="$SUBDOMAINS_DIR/vhosts/$TARGET_DOMAIN"
    mkdir -p "$DOMAIN_VHOST_DIR"

    if [ ! -f "$DOMAIN_VHOST_DIR/valid_vhosts_level0.txt" ]; then
        echo "$TARGET_DOMAIN" > "$DOMAIN_VHOST_DIR/valid_vhosts_level0.txt"
        echo "level,protocol,vhost" > "$DOMAIN_VHOST_DIR/report.csv"
    fi

    echo "[*] Detecting filter sizes (baseline response sizes)..."
    HTTP_SIZE=$(curl -s -o /dev/null -w "%{size_download}" "http://$TARGET_DOMAIN")
    HTTPS_SIZE=$(curl -s -o /dev/null -w "%{size_download}" "https://$TARGET_DOMAIN")
    echo "[*] HTTP size: $HTTP_SIZE | HTTPS size: $HTTPS_SIZE"

    LEVEL=1

    while [ $LEVEL -le $MAX_LEVEL ]; do
        echo -e "\n[***] Level $LEVEL Fuzzing [***]"
        INPUT_FILE="$DOMAIN_VHOST_DIR/valid_vhosts_level$((LEVEL-1)).txt"
        OUTPUT_FILE="$DOMAIN_VHOST_DIR/valid_vhosts_level${LEVEL}.txt"

        if [ -s "$OUTPUT_FILE" ]; then
            echo "[-] Level $LEVEL already completed, skipping (resume mode)"
            ((LEVEL++))
            continue
        fi

        : > "$OUTPUT_FILE"

        while read -r BASE_VHOST; do
            echo "[*] Fuzzing on base vhost: $BASE_VHOST"

            for PROTO in http https; do
                SIZE_VAR_NAME="${PROTO^^}_SIZE"
                SIZE=${!SIZE_VAR_NAME}

                ffuf -u "$PROTO://$TARGET_IP/" \
                     -H "Host: FUZZ.$BASE_VHOST" \
                     -w "$WORDLIST" \
                     -fs "$SIZE" \
                     -of json \
                     -o temp_results.json >/dev/null

                jq -r '.results[].input.Host' temp_results.json | sed "s/FUZZ\\.//g" | sort -u | while read -r FOUND; do
                    # === Pro Tip Validation ===
                    RANDOM_SUB="$(head /dev/urandom | tr -dc a-z0-9 | head -c8).$BASE_VHOST"
                    REAL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code} %{size_download}" -H "Host: $FOUND" "$PROTO://$TARGET_IP/")
                    RANDOM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code} %{size_download}" -H "Host: $RANDOM_SUB" "$PROTO://$TARGET_IP/")

                    if [ "$REAL_RESPONSE" != "$RANDOM_RESPONSE" ]; then
                        echo "$FOUND" >> "$OUTPUT_FILE"
                        echo "$LEVEL,$PROTO,$FOUND" >> "$DOMAIN_VHOST_DIR/report.csv"
                        echo "[+] Valid vhost: $FOUND ($PROTO)"
                    else
                        echo "[-] Rejected (likely wildcard) vhost: $FOUND"
                    fi
                done

            done

        done < "$INPUT_FILE"

        sort -u -o "$OUTPUT_FILE" "$OUTPUT_FILE"
        COUNT=$(wc -l < "$OUTPUT_FILE")
        echo "[*] Level $LEVEL found $COUNT valid vhosts"

        ((LEVEL++))
    done

    cat "$DOMAIN_VHOST_DIR"/valid_vhosts_level*.txt | sort -u > "$DOMAIN_VHOST_DIR/all_vhosts.txt"

    echo "[*] Adding valid vhosts of $TARGET_DOMAIN to /etc/hosts..."

    while read -r VHOST; do
        if ! grep -q "\s$VHOST" /etc/hosts; then
            echo "$TARGET_IP $VHOST" | sudo tee -a /etc/hosts >/dev/null
            echo "[+] Added $VHOST to /etc/hosts"
        else
            echo "[-] $VHOST already exists in /etc/hosts"
        fi
    done < "$DOMAIN_VHOST_DIR/all_vhosts.txt"

    sed -i "1i$TARGET_IP" "$DOMAIN_VHOST_DIR/all_vhosts.txt"

    echo -e "\n[✔] Done with $TARGET_DOMAIN!"
}

export -f process_domain
export SUBDOMAINS_DIR WORDLIST MAX_LEVEL

cat "$WILDCARD_DOMAINS_FILE" | xargs -P $THREADS -n 1 -I {} bash -c 'process_domain "$@"' _ {}

echo -e "\n[✔] All wildcard domains processed. Check $SUBDOMAINS_DIR/vhosts/ for results."
echo "[✔] /etc/hosts backup at /etc/hosts.bak"
