# SAIRI

Docker image serbaguna berbasis `debian:bullseye-slim` yang sudah dilengkapi banyak runtime dan tools populer, siap pakai untuk development, automation, atau environment container (mis. panel hosting berbasis container seperti Pterodactyl/Pelican).

## Fitur / Yang Terpasang
 
- **Bahasa & Runtime**
  - Node.js (versi dapat diatur lewat env `NODE_VERSION`, terinstall otomatis saat container start)
  - Bun
  - Go `1.24.0`
  - Python `3.13.0`
  - PHP `8.3` (via repo Sury/Ondřej, mendukung multi-versi PHP)
  - Java (Eclipse Temurin/Adoptium) `21`
- **Package manager**: npm, pnpm, yarn, pm2, Composer
- **Database client**: `mysql` — hanya client, tidak menjalankan server database di dalam container
- **Tools umum**: git, curl, wget, zip/unzip, tar, jq, nano, vim, figlet, net-tools, dll
- **Media**: ffmpeg, imagemagick, graphicsmagick, webp, mediainfo
- **Automation/Browser**: Playwright (beserta dependency browser)
- **Networking**: Cloudflare Tunnel (`cloudflared`)

## Environment Variables

| Variabel | Deskripsi | Contoh |
|---|---|---|
| `NODE_VERSION` | Versi Node.js yang ingin diinstall/diaktifkan saat container start | `20`, `v20.11.0` |
| `ENABLE_CF_TUNNEL` | Set `true`/`1` untuk mengaktifkan Cloudflare Tunnel otomatis | `true` |
| `CF_TOKEN` | Token tunnel Cloudflare (wajib jika `ENABLE_CF_TUNNEL` aktif) | `xxxxxxxx` |

## Cara Pakai

### Build image

```bash
docker build -t sairi .
```

### Jalankan container

```bash
docker run -it \
  -e NODE_VERSION=20 \
  -e ENABLE_CF_TUNNEL=false \
  sairi
```

Saat container berjalan, `entrypoint.sh` akan:
1. Menyiapkan/menginstall Node.js sesuai `NODE_VERSION` (jika diset).
2. Menjalankan Cloudflare Tunnel jika diaktifkan.
3. Menampilkan banner info sistem (OS, CPU, RAM, disk, dan versi masing-masing runtime).
4. Masuk ke shell interaktif (`bash`).

### Connect ke database eksternal

Client `mysql` dipakai untuk connect ke database MySQL/MariaDB yang jalan di luar container (mis. fitur Databases di Pterodactyl, atau database cloud lain):

```bash
mysql -h db-host -u user -p -e "SHOW DATABASES;"
```

## CI/CD

Repository ini menggunakan GitHub Actions (`.github/workflows/docker-publish.yml`) untuk build & push image secara otomatis ke GitHub Container Registry (`ghcr.io`) setiap kali ada push ke branch `main`, tag versi baru, atau sesuai jadwal harian.

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

## Author

**SairiDev**
Email: sairidev@gmail.com 
