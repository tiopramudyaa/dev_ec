# Image resmi MySQL 8.0
FROM mysql:8.0

# Script pembuatan database prod (JARVIES), dijalankan otomatis
# sekali saat volume mysql_data masih kosong.
# Disalin ke image (bukan di-mount) agar jalan di server mana pun.
COPY mysql-init/ /docker-entrypoint-initdb.d/
