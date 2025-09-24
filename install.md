# ⚡ Auto Installer Panel VPN (Xray, OVPN, SSH, SlowDNS)

![Panel VPN Auto Installer: Xray | OVPN | SSH | SlowDNS](https://readme-typing-svg.demolab.com?font=Capriola&size=40&duration=4000&pause=450&color=F70069&background=FFFFAA00&center=true&random=false&width=600&height=100&lines=Panel+VPN+Auto+Installer;Xray+%7C+OVPN+%7C+SSH+%7C+SlowDNS)

## 📋 Table of Contents

- [Installation](#-installation)
- [Features](#-features)
- [Supported Protocols](#-supported-protocols)
- [API Management](#-api-management)
- [Auto Reboot Configuration](#-auto-reboot-configuration)
- [System Requirements](#️-system-requirements)
- [Support](#-support)

## 🚀 Installation

### Change to root user

```bash
sudo -i
```

atau

```bash
sudo su
```

### Step 1: Run the Setup Script

```bash
apt-get update && \
apt-get --reinstall --fix-missing install -y whois bzip2 gzip coreutils wget screen nscd && \
wget --inet4-only --no-check-certificate -O setup.sh https://raw.githubusercontent.com/alrescha79-cmd/panel-auto/refs/heads/main/setup.sh && \
chmod +x setup.sh && \
screen -S setup ./setup.sh
```

### ⚠️ Important Information

- If during the installation process in [Step 1](#-installation), a disconnection occurs in the terminal, do not re-enter the installation command. Please use the command `screen -r setup` to view the ongoing process.
- Then run the command `./setup.sh` again to continue the installation.
- To view the installation log, check `/root/syslog.log`.

## ✨ Features

- Automated installation of SSH/VPN services
- Support for multiple protocols (Shadowsocks, Trojan, VLESS, VMess)
- User account creation, renewal, and deletion
- Auto-reboot configuration via cron
- Modular structure for extensibility
- Web-based backup and restore interface
- BBR congestion control optimization
- Trial account management system

## 🔌 Supported Protocols

This script supports the following tunneling protocols:

1. **SSH** - Secure Shell protocol for secure network services
2. **VMess** - Encrypted transmission protocol for high-performance scenarios
3. **VLESS** - Next-generation proxy protocol with simplified design
4. **Trojan** - Stealthy proxy protocol that mimics HTTPS traffic
5. **Shadowsocks** - Secure socks5 proxy for circumventing censorship

## 🌐 API Management

The project includes a Go-based REST API for managing VPN accounts:

### Installation

```bash
wget https://raw.githubusercontent.com/alrescha79-cmd/panel-auto/refs/heads/main/golang/rest-go.sh
chmod +x rest-go.sh
bash rest-go.sh
```

### Package Installation (from package-gohide.sh)

The [package-gohide.sh](package-gohide.sh) script installs essential command-line tools for account management:

#### Account Creation Commands

- `/usr/local/bin/add-vmess` - Create VMess accounts
- `/usr/local/bin/add-vless` - Create VLESS accounts
- `/usr/local/bin/add-trojan` - Create Trojan accounts
- `/usr/local/bin/add-shadowsocks` - Create Shadowsocks accounts
- `/usr/local/bin/add-ssh` - Create SSH accounts

#### Account Deletion Commands

- `/usr/local/bin/del-vmess` - Delete VMess accounts
- `/usr/local/bin/del-trojan` - Delete Trojan accounts
- `/usr/local/bin/del-vless` - Delete VLESS accounts
- `/usr/local/bin/del-shadowsocks` - Delete Shadowsocks accounts
- `/usr/local/bin/del-ssh` - Delete SSH accounts

#### Account Check Commands

- `/usr/local/bin/check-vless` - Check VLESS account status
- `/usr/local/bin/check-trojan` - Check Trojan account status
- `/usr/local/bin/check-shadowsocks` - Check Shadowsocks account status
- `/usr/local/bin/check-ssh` - Check SSH account status
- `/usr/local/bin/check-vmess` - Check VMess account status

#### Account Renewal Commands

- `/usr/local/bin/renew-vmess` - Renew VMess accounts
- `/usr/local/bin/renew-ssh` - Renew SSH accounts
- `/usr/local/bin/renew-vless` - Renew VLESS accounts
- `/usr/local/bin/renew-trojan` - Renew Trojan accounts
- `/usr/local/bin/renew-shadowsocks` - Renew Shadowsocks accounts

## ⏰ Auto Reboot Configuration

By default, this script does not include an auto-reboot system because not all users need it. If you want to install auto-reboot on your VPS, use the following command:

```bash
crontab -l > /tmp/cron.txt
sed -i "/reboot$/d" /tmp/cron.txt
echo -e "\n"'0 4 * * * '"$(which reboot)" >> /tmp/cron.txt
crontab /tmp/cron.txt
rm -rf /tmp/cron.txt
```

The above command will install an auto-reboot every day at 04:00.

### To Cancel Auto Reboot

```bash
crontab -l > /tmp/cron.txt
sed -i "/reboot$/d" /tmp/cron.txt
crontab /tmp/cron.txt
rm -rf /tmp/cron.txt
```

## 🖥️ System Requirements

### Supported Operating Systems

![Ubuntu 20.04](https://img.shields.io/badge/Ubuntu-20.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Ubuntu 22.04](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian 10](https://img.shields.io/badge/Debian-10-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Debian 11](https://img.shields.io/badge/Debian-11-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Other Distros](https://img.shields.io/badge/Other-Distros-4D4D4D?style=for-the-badge&logo=linux&logoColor=white)

### Required Packages

- whois
- bzip2
- gzip
- coreutils
- wget
- screen
- nscd

## 🆘 Support

For support and bug reporting, please contact:

[![Telegram: Click Here](https://img.shields.io/badge/Telegram-Click%20Here-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/Alrescha79)
[![Email: Click Here](https://img.shields.io/badge/Email-Click%20Here-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:anggun@cakson.my.id)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

Copyright © 2025 [Alrescha79](https://github.com/alrescha79-cmd). All rights reserved.

---
