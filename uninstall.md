# Uninstall Panel (panel-auto)

Dokumen ini menjelaskan fungsi, cakupan, dan cara penggunaan skrip `uninstall.sh` yang disiapkan untuk membalik (sebisa mungkin) perubahan yang dibuat oleh `setup.sh` pada sistem Linux berbasis Debian/Ubuntu.

---

## 1. Ringkasan Fungsi Skrip

Skrip `uninstall.sh` melakukan hal-hal berikut:

| Kategori | Aksi Utama |
|----------|------------|
| Service systemd | Stop, disable, dan hapus unit kustom (vmess, vless, trojan, shadowsocks, ws, udp, limitip, limitquota, badvpn, dll) |
| Cron job | Menghapus cron: `xp_all`, `daily_reboot`, `logclear` |
| Firewall / Kernel | Menghapus rule iptables yang ditambahkan & menonaktifkan `net.ipv4.ip_forward` (jika diaktifkan oleh install) |
| Konfigurasi aplikasi | Menghapus direktori dan file: `/etc/xray`, OpenVPN configs, hapus `xray.conf` di nginx, hapus file ovpn di web root |
| Sertifikat | Menghapus direktori ACME `.acme.sh` (Let’s Encrypt) |
| Binary tambahan | Hapus `ws.py`, `udp`, `badvpn`, `gotop`, `config.json`, node_modules “liar” di `/usr/bin` |
| Swap file | Menghapus `/swapfile` yang dibuat installer (jika ada dan tercatat di `/etc/fstab`) |
| Modifikasi shell | Membersihkan entri `menu` di `~/.profile` & pembersihan history injection di `.bashrc` |
| Xray UUID / Key | Menghapus file domain & konfigurasi Xray (tidak menyimpan backup) |

---

## 2. Hal yang TIDAK / BELUM Otomatis Dipulihkan

| Item | Penjelasan |
|------|------------|
| Konfigurasi asli `/etc/nginx/nginx.conf` | Jika sebelumnya ditimpa, Anda harus restore manual (misal dari paket default `nginx-core` atau backup pribadi). |
| Konfigurasi `/etc/ssh/sshd_config` | Jika sudah dimodifikasi oleh setup, restore manual jika diperlukan. |
| File PAM `/etc/pam.d/common-password` | Dihapus hanya jika terdeteksi string “Alrescha”. Restore via: `apt-get install --reinstall libpam-modules libpam-modules-bin libpam-runtime`. |
| Paket sistem (nginx, haproxy, dropbear, dll) | Hanya dihapus jika Anda mengaktifkan blok “Purge paket” (opsional). |
| Rule firewall lain | Hanya rule spesifik panel yang dicoba dihapus. Rule lainnya dibiarkan. |
| User / akun SSH | Tidak disentuh. |
| Log lama | Tidak ada pembersihan agresif. |

---

## 3. Prasyarat

- Jalankan sebagai `root` (skrip sudah melakukan pengecekan).
- Pastikan tidak ada proses penting Anda yang kebetulan memakai nama service sama.
- Backup sebelum uninstall (jika perlu):
  ```bash
  mkdir -p /root/backup-panel
  cp -r /etc/xray /root/backup-panel/ 2>/dev/null || true
  cp -r /etc/openvpn /root/backup-panel/ 2>/dev/null || true
  cp /etc/nginx/nginx.conf /root/backup-panel/nginx.conf.bak 2>/dev/null || true
  ```

---

## 4. Cara Menggunakan

### Langkah Cepat

```bash
wget -O uninstall.sh https://raw.githubusercontent.com/<owner>/<repo>/main/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

Saat diminta konfirmasi, ketik:
```
YES
```

### Menjalankan dengan Mode Debug
Jika ingin melihat perintah yang dieksekusi:
```bash
bash -x ./uninstall.sh
```

### Jika File Sudah Ada Secara Lokal
Pastikan permission:
```bash
chmod 700 uninstall.sh
./uninstall.sh
```

---

## 5. Struktur Logika Skrip

1. Validasi root + konfirmasi.
2. Stop & disable service terkait panel.
3. Hapus unit systemd kustom.
4. Hapus cron job milik panel.
5. Revert `net.ipv4.ip_forward` jika diaktifkan.
6. Hapus rule NAT & DNS redirect panel di iptables.
7. Hapus direktori dan file konfigurasi (Xray, OpenVPN, xray.conf nginx).
8. Hapus binary tambahan.
9. Hapus ACME `.acme.sh` (sertifikat Let’s Encrypt yang dikelola installer).
10. Hapus swapfile khusus (jika dibuat).
11. Bersihkan modifikasi `.profile` & `.bashrc`.
12. (Opsional) Purge paket (blok dikomentari).
13. Restart layanan dasar `ssh` dan `cron`.
14. Tampilkan rekomendasi langkah lanjutan.

---

## 6. Opsi: Purge Paket

Di dalam skrip terdapat blok:
```bash
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
```

Aktifkan dengan menghapus tanda `#` jika Anda yakin tidak memerlukan paket tersebut lagi.

---

## 7. Validasi Setelah Uninstall

Jalankan:
```bash
systemctl daemon-reload
systemctl list-units --type=service | egrep "vmess|vless|trojan|shadowsocks|ws|udp|badvpn|limitip|limitquota" || echo "Service panel sudah tidak aktif."
ls /etc/xray && echo "Masih ada /etc/xray (periksa manual!)" || echo "/etc/xray sudah hilang."
```

Periksa iptables:
```bash
iptables -t nat -L -n | grep -E '53|10.8.0.0|20.8.0.0' || echo "Rule NAT panel sudah tidak ada."
```

Periksa swap:
```bash
swapon --show
grep swapfile /etc/fstab || echo "Tidak ada entri swapfile panel di fstab."
```

---

## 8. Mengembalikan File PAM (Jika Perlu)

Jika login jadi bermasalah dan Anda menghapus `common-password`:
```bash
apt-get update
apt-get install --reinstall -y libpam-modules libpam-modules-bin libpam-runtime
```

---

## 9. Mengembalikan ip_forward (Jika Butuh Routing / VPN Lain)

```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

---

## 10. Restore Nginx Default (Contoh)

Untuk Debian/Ubuntu:
```bash
apt-get install --reinstall -y nginx
# atau:
cp /usr/share/nginx/nginx.conf /etc/nginx/nginx.conf
systemctl restart nginx
```

---

## 11. Troubleshooting

| Masalah | Solusi Cepat |
|---------|--------------|
| Service “failed to stop” | Abaikan jika sudah disabled, lanjutkan. |
| file /etc/haproxy/haproxy.cfg hilang tapi butuh haproxy | Reinstall: `apt-get install --reinstall haproxy` |
| iptables rule masih muncul | Hapus manual: `iptables -t nat -D PREROUTING ...` |
| Tidak bisa login SSH setelah uninstall | Pastikan `sshd_config` valid & service berjalan: `systemctl status ssh` |
| Sertifikat hilang tapi ingin pakai kembali | Issuance ulang via acme / certbot sesuai kebutuhan. |

---

## 12. Keamanan

- Skrip tidak melakukan `flush` penuh firewall untuk menjaga konfigurasi lain.
- Tidak menyentuh user / home directory selain root profile.
- Tidak memaksa reboot (Anda boleh reboot untuk memastikan memori & service clean).

---

## 13. Rekomendasi Setelah Uninstall

1. Reboot (opsional tapi disarankan):
   ```bash
   reboot
   ```
2. Audit port terbuka:
   ```bash
   ss -tulpn
   ```
3. Cek log sistem untuk error residual:
   ```bash
   journalctl -p 3 -xb
   ```

---

## 14. Changelog Dokumen

| Versi | Tanggal | Perubahan |
|-------|---------|-----------|
| 1.0 | 2025-09-25 | Rilis awal dokumentasi uninstall |

---

## 15. Kontak / Bantuan

Jika Anda memerlukan reinstall atau modifikasi lanjutan, jalankan ulang `setup.sh` sesuai panduan repositori ini.

---

Semoga membantu. Gunakan dengan penuh kehati-hatian.
