#! /bin/bash
echo "Welcome to Concur Autoscale Endpoint Demo" > /var/www/html/demo.txt
sudo apt update
sudo apt -y install apache2
sudo ufw allow 'Apache'
sudo systemctl start apache2
