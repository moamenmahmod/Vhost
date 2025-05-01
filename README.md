
# Recursive Vhost Pro  
**Fully Automated Vhost Enumerator**  
_By: Moamen Mahmoud_

---

## 🚀 Overview

**Recursive Vhost Pro** is an advanced, fully automated script designed for recursive virtual host (vhost) enumeration during web application reconnaissance and penetration testing. It uses recursive fuzzing to uncover hidden subdomains and virtual hosts up to multiple levels deep. It works by intelligently filtering out wildcard responses and valid vhosts, and automatically populates the `/etc/hosts` file for quick testing.

This script is perfect for bug bounty hunters and penetration testers who want a deep, structured, and automated vhost discovery workflow.

---

## 🎯 Features

- ✅ **Recursive vhost enumeration** up to user-defined levels.
- ✅ **Auto-handles False-Positives** by size comparison.
- ✅ **Parallel processing** for multiple wildcard domains (multi-threaded using xargs).
- ✅ **Auto-adds discovered vhosts** into your `/etc/hosts` file.
- ✅ **Backup of `/etc/hosts`** to prevent accidental loss.
- ✅ **Resumable** — skips already completed levels for efficiency.
- ✅ Generates **CSV reports** for every domain processed.
- ✅ Uses **ffuf** (fast web fuzzer) and **jq** for JSON parsing.

---

## 💻 Pro Features Explained

- **Recursive Levels**: Each level performs fuzzing on valid vhosts discovered from the previous level, allowing you to go deep into the vhost chain (`a.b.c.target.com`).
- **Size Filtering**: It detects valid domains by sending `curl` request with random subdomain name which is not exist and compare its size with the fuzzing result.
- **Resumable**: If you rerun the script, it will skip levels already completed.
- **CSV Reports**: Each processed domain gets a `report.csv` summarizing valid vhosts by level and protocol.
- **Automatic Hosts Update**: All valid vhosts get added to `/etc/hosts` pointing to the target IP for easy browser testing.

---

## 🛠️ Requirements

Make sure the following tools are installed:

- `ffuf` — Fast web fuzzer (https://github.com/ffuf/ffuf)
- `jq` — Lightweight and flexible command-line JSON processor
- `dig`, `curl`, `sed`, `xargs`, `head`, `sort`, and other basic Unix tools.

---

## 📦 Script Workflow (How it works)

1. **Takes your target domains** (wildcard domains list) and wordlist as input.
2. **Performs DNS resolution** to get the target IP.
3. **Detects wildcard responses** using `curl` size filtering.
4. For each level:
   - Uses **ffuf** to fuzz virtual hosts using the wordlist.
   - Filters valid results by comparing response size and random subdomains.
   - Saves valid vhosts to per-level files.
5. **Recurses deeper** on newly found vhosts up to the specified level.
6. **Updates `/etc/hosts`** with newly discovered vhosts for quick access.
7. Generates a detailed CSV report with valid vhosts by level and protocol (http/https).

---

## 📚 Usage Tutorial

### 📝 Command Syntax

```bash
./recursive_vhost_pro.sh -t TARGET -b BASE_DIR -w WORDLIST -a DOMAINS_FILE -l MAX_LEVEL
```

### 🏴 Required Flags

| Flag | Description                          | Example                           |
|------|--------------------------------------|-----------------------------------|
| `-t` | Target name                           | `google`                          |
| `-b` | Base directory path                   | `~/bugbounty/targets`             |
| `-w` | Wordlist file                         | `~/wordlists/dns.txt`             |
| `-a` | Wildcard domains file (list of domains)| `wildcard_domains.txt`           |
| `-l` | Max recursion level                   | `5`                               |

### 🟢 Example Command

```bash
./recursive_vhost_pro.sh -t google -b ~/bugbounty/targets -w ~/wordlists/dns.txt -a wildcard_domains.txt -l 5
```

---

## 📂 Example Directory Structure

```
~/bugbounty/targets/google/subdomains/
├── wildcard_domains.txt
├── vhosts/
│   ├── sub1.google.com/
│   │   ├── valid_vhosts_level0.txt
│   │   ├── valid_vhosts_level1.txt
│   │   ├── ...
│   │   ├── report.csv
│   │   └── all_vhosts.txt
│   └── ...
```

---



## ⚠️ Important Notes

- Always check the `/etc/hosts.bak` backup if you want to restore your original hosts file.
- Requires `sudo` access because it modifies `/etc/hosts`.
- Don’t forget to install `ffuf` and `jq` before running the script.
- Intended for ethical hacking and authorized penetration testing only. 🚨

---

## ◎ Dependencies

- **ffuf**  
  Install:  
  ```bash
  go install github.com/ffuf/ffuf/v2@latest
  ```

- **jq**  
  Install on Debian/Ubuntu:  
  ```bash
  sudo apt-get install jq
  ```

---

## © Author

**Moamen Mahmoud**  
_Fully automated vhost enumeration tool for bug bounty hunters and pentesters._

---

## ✅ License

For educational and authorized security testing only.  
Use at your own risk.
