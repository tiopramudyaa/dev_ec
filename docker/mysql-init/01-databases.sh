#!/bin/bash
# Dijalankan otomatis oleh image MySQL HANYA saat pertama kali
# (volume mysql_data masih kosong).
# MYSQL_DATABASE (new, untuk EcoSystem) sudah dibuat otomatis,
# script ini menambah database JARVIES (prod) dan memberi akses
# ke user aplikasi (MYSQL_USER dari .env.mysql).
set -e

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS \`prod\`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`prod\`.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
SQL
