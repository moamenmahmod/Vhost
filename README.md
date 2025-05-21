
# Recursive Vhost Enumerator

**Recursive Vhost Enumerator** is a powerful Bash-based tool designed for automated and recursive virtual host (vhost) enumeration. It supports advanced false positive detection through response hash comparison and is ideal for penetration testers, bug bounty hunters, and red teamers working with misconfigured virtual hosts.

---

## 🚀 Features

- 🔁 Recursive vhost fuzzing with unlimited depth (configurable)
- 🎯 Targets wildcard domains with accurate IP resolution
- 💥 FFUF-powered subdomain fuzzing for speed and precision
- 🧠 False-positive detection using SHA-1 hash comparison (bypasses wildcard DNS traps)
- 📊 CSV reporting of all discovered vhosts
- 🧾 Automatically updates `/etc/hosts` with resolved entries
- 💡 Intelligent wildcard and duplicate filtering
- 💻 Designed for automation in large-scale recon workflows

---

## 📦 Requirements

- `bash`
- `ffuf`
- `curl`
- `jq`
- `dig` (from `dnsutils`)
- `sha1sum` (from `coreutils`)
- `sudo` (for modifying `/etc/hosts`)

---

## 🔧 Usage

```bash
./vhostenum.sh -t TARGET -b BASE_DIR -w WORDLIST -a DOMAINS_FILE -l MAX_LEVEL
```

### Required Flags

| Flag | Description                          |
|------|--------------------------------------|
| `-t` | Target name (used as folder name)    |
| `-b` | Base directory for storing results   |
| `-w` | Path to wordlist (e.g. `dns.txt`)    |
| `-a` | File containing wildcard domains     |
| `-l` | Max recursion level (e.g. `5`)       |

### Example

```bash
./vhostenum.sh \
  -t example \
  -b ~/bugbounty/targets \
  -w ~/wordlists/vhosts.txt \
  -a wildcard_domains.txt \
  -l 3
```

---

## 🧪 False Positive Detection

To avoid wildcard DNS traps, the script uses the following detection logic:

- Sends a request to the discovered vhost.
- Sends a request to a random non-existent subdomain of the same base domain.
- Compares the **SHA-1 hash of response bodies**.
- If hashes match, the response is considered a wildcard or mirror, and is **discarded**.

---

## 📂 Output Structure

Results are saved under:

```
$BASE_DIR/$TARGET_NAME/subdomains/vhosts/$DOMAIN/
```

Each directory contains:

- `valid_vhosts_level*.txt` – Discovered vhosts per recursion level
- `all_vhosts.txt` – All unique vhosts
- `report.csv` – Detailed report with protocol and level info

---

## ⚠️ `/etc/hosts` Safety

- Automatically backs up `/etc/hosts` to `/etc/hosts.bak` before editing
- Appends new valid vhosts for local testing

---

## 📌 Notes

- Ensure your wordlist includes relevant vhost patterns (e.g., `admin`, `dev`, `internal`).
- Use responsibly on authorized domains only.
- For HTTPS, ensure your target IP supports virtual hosts over SSL or uses a wildcard cert.

---

## 🧑‍💻 Author

**Mo'a**

- Bug Bounty Hunter | Pentester | Recon Enthusiast
- GitHub: [your-profile](https://github.com/your-profile)

---

## 📜 License

MIT License – free to use and modify. Attribution appreciated.
