#!/bin/bash

# Skapa Nginx-konfiguration för load balancing
tee /etc/nginx/sites-available/default > /dev/null <<EOL
upstream myapp {
    server 192.168.2.10;
    server 192.168.2.11;
}

server {
    listen 80;

    location / {
        proxy_pass http://myapp/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Testa Nginx-konfigurationen för syntaxfel
nginx -t

# Om testet lyckas, starta om Nginx-tjänsten
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo "Nginx has been restarted successfully."
else
    echo "Nginx configuration test failed. Please check the configuration."
fi
