#!/bin/bash
# Uninstaller untuk panel-auto (kebalikan dari setup.sh)
# Gunakan dengan hati-hati.

set -euo pipefail

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Harus dijalankan sebagai root.${NC}"
    exit 1
  fi
}

confirm() {
  echo -e "${YELLOW}Skrip ini akan mencoba menghapus instalasi panel-auto & komponen terkait."
  echo -e "Lanjutkan? (ketik: YES)${NC}"
  read -r ans
  [[ "$ans" == "YES" ]] || { echo "Dibatalkan."; exit 1; }
}

msg() { echo -e "${GREEN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

need_root
confirm

############################################
# 1. Hentikan & disable service terkait
############################################
msg "Menghentikan service systemd kustom..."

services_stop=(
  "vmess@config.service"
  "vless@config.service"
  "trojan@config.service"
  "shadowsocks@config.service"
  "haproxy.service"
  "ws.service"
  "udp.service"
  "limitip.service"
  "limitquota.service"
  "badvpn.service"
  "nginx.service"
  "dropbear.service"
  "openvpn@server.service"
  "openvpn.service"
  "xray.service"
)

for svc in "${services_stop[@]}"; do
  if systemctl list-units --type=service --all | grep -q "^${svc}"; then
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
    msg "Stop + disable $svc"
  fi
done

############################################
# 2. Hapus unit file systemd kustom
############################################
msg "Menghapus unit systemd kustom..."
rm -f /etc/systemd/system/vmess@config.service
rm -f /etc/systemd/system/vless@config.service
rm -f /etc/systemd/system/trojan@config.service
rm -f /etc/systemd/system/shadowsocks@config.service
rm -f /etc/systemd/system/ws.service
rm -f /etc/systemd/system/udp.service
rm -f /etc/systemd/system/limitip.service
rm -f /etc/systemd/system/limitquota.service
rm -f /etc/systemd/system/badvpn.service
rm -f /etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf 2>/dev/null || true
rmdir /etc/systemd/system/xray@.service.d 2>/dev/null || true

systemctl daemon-reload

############################################
# 3. Hapus cron jobs yang ditambahkan
############################################
msg "Menghapus cron jobs..."
rm -f /etc/cron.d/xp_all
rm -f /etc/cron.d/daily_reboot
rm -f /etc/cron.d/logclear

############################################
# 4. Revert sysctl ip_forward bila sebelumnya belum aktif
############################################
if grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  # Komentar baris itu (tidak hapus total)
  sed -i 's/^net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1 # removed by uninstall panel-auto/' /etc/sysctl.conf || true
  sysctl -p || true
  msg "Menonaktifkan ip_forward (silakan cek kebutuhan lain)."
fi

############################################
# 5. Hapus rules iptables spesifik
############################################
msg "Menghapus iptables rules yang ditambahkan..."
# Cari interface default
iface=$(ip -4 route ls | awk '/default/ {print $5; exit}')
# Rules yang mungkin ditambahkan (delete jika ada)
iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null && \
  iptables -t nat -D PREROUTING -i "$iface" -p udp --dport 53 -j REDIRECT --to-ports 5300 || true

iptables -t nat -C POSTROUTING -s 10.8.0.0/24 -o "$iface" -j MASQUERADE 2>/dev/null && \
  iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o "$iface" -j MASQUERADE || true

iptables -t nat -C POSTROUTING -s 20.8.0.0/24 -o "$iface" -j MASQUERADE 2>/dev/null && \
  iptables -t nat -D POSTROUTING -s 20.8.0.0/24 -o "$iface" -j MASQUERADE || true

# Simpan ulang bila iptables-persistent ada
if command -v iptables-save >/dev/null && [ -d /etc/iptables ]; then
  iptables-save > /etc/iptables/rules.v4 || true
fi

############################################
# 6. Hapus file & direktori konfigurasi
############################################
msg "Menghapus direktori & file konfigurasi panel..."

# Direktori utama Xray & terkait
rm -rf /etc/xray
rm -rf /etc/vmess /etc/vless /etc/trojan /etc/shadowsocks 2>/dev/null || true

# Haproxy & cert chain khusus
rm -f /etc/haproxy/yha.pem

# Jika haproxy.cfg diduga khusus (tidak selalu aman untuk hapus)
if grep -q "frontend" /etc/haproxy/haproxy.cfg 2>/dev/null; then
  warn "Menghapus /etc/haproxy/haproxy.cfg (diasumsikan milik panel)."
  rm -f /etc/haproxy/haproxy.cfg
fi

# Nginx: hapus xray.conf kustom
rm -f /etc/nginx/conf.d/xray.conf
# Jangan hapus /etc/nginx/nginx.conf (bisa modifikasi manual). Bila ingin revert:
# cp /usr/share/nginx/nginx.conf /etc/nginx/nginx.conf

# OpenVPN config
rm -rf /etc/openvpn

# File client ovpn di webroot
for f in client-tcp.ovpn client-udp.ovpn client-ssl.ovpn allovpn.zip; do
  rm -f "/var/www/html/$f"
done

# Banner & pam custom
rm -f /etc/Alrescha79.txt
# Hati-hati common-password — hanya hapus jika yakin bukan milik lain
if grep -q "Alrescha" /etc/pam.d/common-password 2>/dev/null; then
  rm -f /etc/pam.d/common-password
  warn "common-password dihapus (pastikan restore file default PAM bila perlu)."
fi

# Domain file
rm -f /etc/xray/domain 2>/dev/null || true

############################################
# 7. Hapus binary / script yang diunduh
############################################
msg "Menghapus binary / script tambahan..."
rm -f /usr/bin/ws.py
rm -f /usr/bin/udp
rm -f /usr/bin/badvpn
rm -f /usr/bin/gotop
rm -f /usr/bin/config.json

# Node modules yang dipasang di /usr/bin (tidak lazim)
if [ -d /usr/bin/node_modules ]; then
  rm -rf /usr/bin/node_modules
  msg "Menghapus /usr/bin/node_modules (express, express-fileupload)."
fi

# Xray binary
if [ -x /usr/local/bin/xray ]; then
  rm -f /usr/local/bin/xray
  msg "Menghapus /usr/local/bin/xray"
fi

############################################
# 8. ACME & cert
############################################
if [ -d /root/.acme.sh ]; then
  warn "Menghapus direktori ACME /root/.acme.sh (akan menghapus semua sertifikat Let’s Encrypt yang dikelola acme.sh)."
  rm -rf /root/.acme.sh
fi

############################################
# 9. Swap file (dibuat oleh setup?)
############################################
if grep -q "/swapfile swap swap" /etc/fstab 2>/dev/null; then
  if [ -f /swapfile ]; then
    swapoff /swapfile || true
    sed -i '\|/swapfile swap swap|d' /etc/fstab
    rm -f /swapfile
    msg "Swapfile /swapfile dihapus."
  fi
fi

############################################
# 10. Bersihkan modifikasi shell (parsial)
############################################
if grep -q "menu" /root/.profile 2>/dev/null; then
  sed -i '/menu$/d' /root/.profile || true
fi
if grep -q "bash_history" /root/.bashrc 2>/dev/null; then
  sed -i '/bash_history/d' /root/.bashrc || true
fi

############################################
# 11. Opsional: Purge paket (UNCOMMENT bila yakin)
############################################
PACKAGES_OPTIONAL=(
  xray
  haproxy
  nginx
  dropbear
  openvpn
  easy-rsa
)

# for p in "${PACKAGES_OPTIONAL[@]}"; do
#   if dpkg -s "$p" >/dev/null 2>&1; then
#     apt-get remove --purge -y "$p" || true
#     msg "Purged package: $p"
#   fi
# done
# apt-get autoremove -y || true

############################################
# 12. Restart layanan inti yang mungkin diperlukan
############################################
systemctl restart ssh 2>/dev/null || true
systemctl restart cron 2>/dev/null || true

############################################
# 13. Informasi akhir
############################################
msg "Proses uninstall selesai."
echo
warn "Langkah lanjutan yang disarankan:"
echo "- Periksa kembali /etc/nginx/nginx.conf & /etc/ssh/sshd_config (restore bila perlu)."
echo "- Jalankan: systemctl status untuk memastikan tidak ada service gagal."
echo "- Jika tadi menghapus common-password, restore dari paket libpam-common."
echo "- Pertimbangkan reboot untuk memastikan semua bersih."
echo
msg "Selesai."