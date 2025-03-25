#!/bin/bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Değişkenlerin tanımlı olduğu .env dosyasını kontrol et ve yükle
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Hata: $ENV_FILE dosyası bulunamadı!${NC}"
    echo "Örnek .env dosyası oluşturuluyor..."
    cat > "$ENV_FILE" << EOL
DOMAIN="your_domain.com"
PORTAINER_ADMIN_NAME="your_portainer_admin_name"
PORTAINER_PASSWORD="your_portainer_password"
NETWORK_NAME="your_docker_network"
NPM_ADMIN_NAME="your_npm_email"
NPM_ADMIN_PASS="your_npm_password"
COMPOSE_DIR="/opt/docker/<your_domain.com>"
DB_MYSQL_USER="your_mysql_user"
DB_MYSQL_PASSWORD="your_mysql_password"
DUPLICATI_SECRET_KEY="your_duplicati_secret_key"
DUPLICATI_ADMIN_PASSWORD="your_duplicati_password"
DB_MYSQL_NAME="your_npm_table_name"
EOL
    echo -e "${GREEN}$ENV_FILE oluşturuldu. Lütfen değişkenleri gözden geçirin ve tekrar çalıştırın.${NC}"
    exit 1
fi

# .env dosyasını yükle
source "$ENV_FILE"

# Değişkenlerin kontrolü
check_variable() {
    if [ -z "${!1}" ]; then
        echo -e "${RED}Hata: $1 değişkeni tanımlı değil!${NC}"
        exit 1
    fi
}

# Gerekli değişkenlerin kontrolü
VARIABLES=(DOMAIN PORTAINER_ADMIN_NAME PORTAINER_PASSWORD NETWORK_NAME NPM_ADMIN_NAME 
           NPM_ADMIN_PASS COMPOSE_DIR DB_MYSQL_USER DB_MYSQL_PASSWORD DB_MYSQL_NAME DUPLICATI_ADMIN_PASSWORD)
for var in "${VARIABLES[@]}"; do
    check_variable "$var"
done

# Sistem bilgisi alma
IP=$(curl -4 -s ifconfig.me || echo "IP alınamadı")
HOSTNAME=$(hostname)

# Docker kontrol ve düzeltme fonksiyonu
ensure_docker_running() {
    if ! systemctl is-active docker &> /dev/null; then
        echo "Docker servisi çalışmıyor, başlatılıyor..."
        systemctl start docker || {
            echo -e "${RED}Hata: Docker servisi başlatılamadı!${NC}"
            echo "Detaylar için: systemctl status docker.service"
            echo "Ve: journalctl -xeu docker.service"
            return 1
        }
        sleep 2  # Servisin başlaması için kısa bir bekleme
        if ! systemctl is-active docker &> /dev/null; then
            echo -e "${RED}Hata: Docker servisi hala çalışmıyor!${NC}"
            return 1
        fi
    fi
    return 0
}

# Hashed password oluşturma
check_htpasswd() {
    if ! command -v htpasswd &> /dev/null; then
        echo "htpasswd bulunamadı, kuruluyor..."
        apt-get update && apt-get install -y apache2-utils || {
            echo -e "${RED}htpasswd kurulumu başarısız!${NC}"
            exit 1
        }
    fi
}
check_htpasswd
HASHED_PASSWORD=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin YourPassword | cut -d ":" -f 2 | sed 's/\$/\$\$/g')

# Compose dosyasını oluşturma (version kaldırıldı)
create_compose_file() {
    mkdir -p "$COMPOSE_DIR"
    cat > "$COMPOSE_DIR/docker-compose.yml" << EOL
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
    command: --admin-password '$HASHED_PASSWORD'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - app_network

  nginx:
    image: nginx:latest
    container_name: nginx
    restart: always
    ports:
      - "8080:80"
    networks:
      - app_network

  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    environment:
      INITIAL_ADMIN_EMAIL: ${NPM_ADMIN_NAME}
      INITIAL_ADMIN_PASSWORD: ${NPM_ADMIN_PASS}
      DB_MYSQL_HOST: "mariadb"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: ${DB_MYSQL_USER}
      DB_MYSQL_PASSWORD: ${DB_MYSQL_PASSWORD}
      DB_MYSQL_NAME: ${DB_MYSQL_NAME}
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - mariadb
    networks:
      - app_network

  mariadb:
    image: mariadb:latest
    container_name: mariadb
    volumes:
      - /var/docker/mariadb/conf:/etc/mysql
    ports:
      - "3306:3306"
    networks:
      - app_network
    environment:
      MYSQL_USER: ${DB_MYSQL_USER}
      MYSQL_PASSWORD: ${DB_MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_MYSQL_PASSWORD}
      MYSQL_DATABASE: ${DB_MYSQL_NAME}

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: dev_pma
    links:
      - mariadb
    ports:
      - "8183:80"
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      PMA_ARBITRARY: 0
    restart: always
    networks:
      - app_network

  duplicati:
    image: lscr.io/linuxserver/duplicati:latest
    container_name: duplicati
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SETTINGS_ENCRYPTION_KEY=${DUPLICATI_SECRET_KEY}
      - DUPLICATI__WEBSERVICE_PASSWORD=${DUPLICATI_ADMIN_PASSWORD}
    volumes:
      - /path/to/duplicati/config:/config
      - /path/to/backups:/backups
      - /path/to/source:/source
    ports:
      - "8200:8200"
    restart: unless-stopped
    networks:
      - app_network

volumes:
  portainer_data:

networks:
  app_network:
    name: ${NETWORK_NAME}
    driver: bridge
EOL
}

# Kurulum bilgilerini yazdırma
print_info() {
    echo -e "\n${GREEN}Kurulum Bilgileri:${NC}"
    echo "Sunucu IP: $IP"
    echo "Hostname: $HOSTNAME"
    echo "Portainer: http://$IP:9000"
    echo "Portainer Admin: $PORTAINER_ADMIN_NAME"
    echo "Nginx: http://$IP:8080"
    echo "Nginx Proxy Manager: http://$IP:81"
    echo "NPM Admin Email: $NPM_ADMIN_NAME"
    echo "NPM Admin Password: $NPM_ADMIN_PASS"
    echo "phpMyAdmin: http://$IP:8183"
    echo "Duplicati: http://$IP:8200"
    echo "Duplicati Password: $DUPLICATI_ADMIN_PASSWORD"
    echo "MariaDB User: $DB_MYSQL_USER"
    echo "MariaDB Database: $DB_MYSQL_NAME"
}

# Menü fonksiyonu
show_menu() {
    clear
    echo -e "${GREEN}Mavedda Docker Yönetim Scripti${NC}"
    echo "Lütfen bir seçenek seçin:"
    echo "1) Yeni Kurulum (fresh_setup)"
    echo "2) Onarım (repair)"
    echo "3) Portainer Sıfırlama (reset_portainer)"
    echo "4) Kontrol ve Güncelleme (check_and_install)"
    echo "5) Her Şeyi Sil ve Yeniden Yükle (full_reset)"
    echo "6) Çıkış"
    echo -n "Seçiminiz [1-6]: "
}

# Kullanıcı girdisine göre işlem yapma
handle_choice() {
    local error=0
    case $1 in
        1)
            if systemctl is-active docker &> /dev/null; then
                echo -e "${RED}Docker zaten kurulu. 'Onarım' seçeneğini kullanın.${NC}"
                return 1
            fi
            echo "Docker kurulumu yapılıyor..."
            apt-get update && apt-get install -y docker.io docker-compose || {
                echo -e "${RED}Docker kurulumu başarısız!${NC}"
                return 1
            }
            systemctl enable docker
            ensure_docker_running || return 1
            create_compose_file
            cd "$COMPOSE_DIR" || return 1
            docker-compose up -d || return 1
            print_info
            ;;
        2)
            echo "Tüm Docker verileri temizleniyor..."
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm $(docker ps -aq) 2>/dev/null || true
            docker volume rm $(docker volume ls -q) 2>/dev/null || true
            docker network prune -f
            ensure_docker_running || return 1
            create_compose_file
            cd "$COMPOSE_DIR" || return 1
            docker-compose up -d || return 1
            print_info
            ;;
        3)
            echo "Portainer verileri sıfırlanıyor..."
            docker stop portainer 2>/dev/null || true
            docker rm portainer 2>/dev/null || true
            docker volume rm portainer_data 2>/dev/null || true
            ensure_docker_running || return 1
            cd "$COMPOSE_DIR" || return 1
            docker-compose up -d portainer || return 1
            print_info
            ;;
        4)
            echo "Compose dosyası kontrol ediliyor ve güncelleniyor..."
            ensure_docker_running || return 1
            cd "$COMPOSE_DIR" || return 1
            docker-compose pull || return 1
            docker-compose up -d || return 1
            print_info
            ;;
        5)
            echo "Docker tamamen kaldırılıyor ve yeniden yükleniyor..."
            apt-get purge -y docker.io docker-compose || return 1
            apt-get autoremove -y --purge || return 1
            rm -rf /var/lib/docker /etc/docker "$COMPOSE_DIR"
            apt-get update && apt-get install -y docker.io docker-compose || {
                echo -e "${RED}Docker yeniden kurulumu başarısız!${NC}"
                return 1
            }
            systemctl enable docker
            ensure_docker_running || return 1
            create_compose_file
            cd "$COMPOSE_DIR" || return 1
            docker-compose up -d || return 1
            print_info
            ;;
        6)
            echo "Çıkılıyor..."
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim! Lütfen 1-6 arasında bir sayı girin.${NC}"
            return 1
            ;;
    esac
    echo -e "${GREEN}İşlem tamamlandı!${NC}"
    return 0
}

# Ana döngü
while true; do
    show_menu
    read choice
    if handle_choice "$choice"; then
        sleep 2
        exit 0
    else
        echo "Tekrar denemek için bir tuşa basın veya 'q' ile çıkın..."
        read -n 1 input
        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            exit 0
        fi
    fi
done
