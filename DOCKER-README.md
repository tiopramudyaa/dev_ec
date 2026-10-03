# Docker

| Service   | Container                          | Port server |
|-----------|------------------------------------|-------------|
| EcoSystem | `ecosystem-app`, `ecosystem-nginx` | 3001        |
| JARVIES   | `jarvies-app`, `jarvies-nginx`     | 3002        |
| MySQL     | `mysql`                            | 3306        |

Container `*-app` menjalankan php-fpm, queue worker & scheduler
(lihat `docker/supervisord.*.conf`), jadi tidak perlu cron di server.

## Persiapan

Sudah disiapkan (cek saja):

- `.env.mysql`: password root & user `appuser` (acak), database `new`
- `docker/mysql-init/01-databases.sh`: membuat database `prod` + akses `appuser`
  (otomatis, hanya saat volume `mysql_data` masih kosong)
- `ecosystem/.env` (DB `new`) & `jarvies/.env` (DB `prod`):
  `DB_HOST=mysql`, `DB_USERNAME=appuser`, `APP_ENV=production`, `APP_DEBUG=false`
- Antar aplikasi lewat network Docker: `JARVIES_URL=http://jarvies-nginx`,
  `ECOSYSTEM_URL=http://ecosystem-nginx/api`
- Backup `.env` versi XAMPP: `ecosystem/.env.xampp.bak`, `jarvies/.env.xampp.bak`

Saat pindah ke server, ganti alamat publik (`APP_URL`, `ECOSYSTEM_BASE_URL`,
redirect URI OAuth) dari `localhost` ke IP/domain server.

## Jalankan (mysql dulu)

```bash
docker compose -f docker-compose.mysql.yml up -d
docker compose -f docker-compose.ecosystem.yml up -d --build
docker compose -f docker-compose.jarvies.yml up -d --build
```

Pertama kali, jalankan migrasi:

```bash
docker exec ecosystem-app php artisan migrate --force
docker exec jarvies-app php artisan migrate --force
```

## Perintah berguna

```bash
# Log aplikasi (php-fpm, queue, scheduler)
docker logs -f ecosystem-app

# Status queue worker & scheduler
docker exec ecosystem-app supervisorctl status

# Setelah mengubah .env: buat ulang container
docker compose -f docker-compose.ecosystem.yml up -d --force-recreate
```
