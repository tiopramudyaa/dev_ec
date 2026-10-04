# =====================================================================
# Stage 1 (app): PHP-FPM + queue worker + scheduler (lewat supervisord)
# =====================================================================
FROM php:8.4-fpm AS app

# Paket sistem untuk compile ekstensi PHP:
#   git, unzip        -> dipakai composer saat download package
#   supervisor        -> menjalankan php-fpm, queue worker & scheduler
#   libzip-dev        -> ekstensi zip (excel, imap)
#   libpng/jpeg/freetype -> ekstensi gd (gambar, excel, pdf)
#   libgmp-dev        -> ekstensi gmp (web-push lebih cepat)
# Ekstensi PHP:
#   pdo_mysql -> koneksi Laravel ke MySQL
#   pcntl     -> wajib untuk queue:work (--timeout & sinyal restart)
#   zip, gd, bcmath, gmp -> kebutuhan package
# Terakhir hapus cache apt agar image lebih kecil
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git unzip supervisor \
        libzip-dev libpng-dev libjpeg62-turbo-dev \
        libfreetype6-dev libgmp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql pcntl zip gd bcmath gmp \
    && rm -rf /var/lib/apt/lists/*

# Batas upload: attachment tiket maks 25 MB per file,
# 1 request bisa membawa beberapa attachment
RUN { \
        echo 'upload_max_filesize=30M'; \
        echo 'post_max_size=80M'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

# Ambil composer dari image resmi composer v2
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Folder kerja di dalam container
WORKDIR /var/www/html

# Install dependency dulu (hanya composer.json & lock) agar layer
# ini di-cache: build ulang cepat selama dependency tidak berubah
#   --no-dev     -> tanpa package development
#   --no-scripts -> artisan belum ada, script dijalankan di bawah
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --no-scripts \
        --no-autoloader \
        --no-interaction \
        --prefer-dist

# Salin source code Laravel
# (file yang dikecualikan ada di ecosystem.Dockerfile.dockerignore)
COPY . .

# Buat autoload + jalankan package:discover,
# siapkan folder storage, link public/storage,
# lalu storage & bootstrap/cache dimiliki www-data
RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p \
        storage/app/public \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
    && ln -sfn ../storage/app/public public/storage \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# PHP-FPM mendengarkan di port 9000 (untuk nginx)
EXPOSE 9000

# supervisord menjalankan php-fpm, queue worker & scheduler.
# Config disalin dari docker/supervisord.ecosystem.conf (ubah config = build ulang)
COPY --from=dockercfg supervisord.ecosystem.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# =====================================================================
# Stage 2 (web): nginx + file statis dari folder public hasil build
# =====================================================================
FROM nginx:alpine AS web

# Salin folder public (css, js, gambar, build vite, link storage)
COPY --from=app /var/www/html/public /var/www/html/public

# Config nginx dari nginx/defaultEcosystem.conf (ubah config = build ulang)
COPY --from=nginxcfg defaultEcosystem.conf /etc/nginx/conf.d/default.conf
