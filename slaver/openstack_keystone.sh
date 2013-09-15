read -p "Enter a token for the OpenStack services to auth with keystone: " token
read -p "Enter the password you used for the MySQL users (nova, glance, keystone): " password
read -p "Enter the email address for service accounts (nova, glance, keystone): " email
read -p "Enter the Controller Server IP: " host_ip_entry
# set up env variables for testing
cat > /root/novarc <<EOF
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_AUTH_URL="$host_ip_entry:5000/v2.0/" 
export ADMIN_PASSWORD=$password
export SERVICE_PASSWORD=$password
export SERVICE_TOKEN=$token
export SERVICE_ENDPOINT="$host_ip_entry:35357/v2.0"
export SERVICE_TENANT_NAME=service
EOF

source /root/novarc
echo "source novarc">>/root/.bashrc
