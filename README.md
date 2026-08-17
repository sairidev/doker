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
| `ENABLE_PHP_WEB` | Set `true`/`1` untuk menyalakan nginx + php-fpm otomatis saat start | `true` |
| `SERVER_PORT` | Port yang dipakai nginx buat serve web (biasanya auto-inject dari panel Pterodactyl/Pelican) | `8080` |

## Testing PHP Web App (nginx + php-fpm)

Image ini sekarang include `php8.3-fpm` dan `nginx`, dikonfigurasi supaya bisa
jalan **tanpa root** (soalnya container jalan sebagai user `container`, bukan
root) — nginx listen di port non-privileged, php-fpm komunikasi lewat unix
socket, log & pid disimpan di `/home/container/logs` dan `/home/container/run`
yang writable.

Docroot web app ada di `/home/container/public` — taruh `index.php` (atau
project Laravel/CodeIgniter) di situ.

### Jalanin buat testing lokal

```bash
docker build -t sairi-php .

docker run -it \
  -e ENABLE_PHP_WEB=true \
  -e SERVER_PORT=8080 \
  -p 8080:8080 \
  sairi-php
```

Lalu buka `http://localhost:8080` — defaultnya bakal muncul halaman
`phpinfo()` (file contoh `index.php` udah dibuat otomatis pas build).
Ganti/isi `/home/container/public` dengan project PHP lo (Laravel: arahkan
`root` di `docker/nginx.conf.template` ke folder `public/` Laravel-nya).

### Di Pterodactyl/Pelican

Set env `ENABLE_PHP_WEB=true` di startup variables egg, `SERVER_PORT` biasanya
udah otomatis di-inject panel — nginx bakal ikut listen di port yang di-allocate
ke server tersebut.

> Catatan: setup ini belum pernah di-build & di-run beneran (sandbox testing
> ini gak ada akses Docker daemon) — cek dulu log `/home/container/logs/`
> kalau ada yang error pas testing pertama kali, terutama permission socket
> php-fpm & path nginx.

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
