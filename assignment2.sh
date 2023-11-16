#!/bin/bash

# Function to display messages with formatting
print_msg() {
    echo -e "\n--- $1 ---\n"
}

# Function to update network configuration using netplan
update_network_config() {
    print_msg "Updating network configuration"
    
    # Check if netplan directory exists
    if [ -d "/etc/netplan" ]; then
        # Create a YAML configuration file for the static interface
        cat <<EOL > /etc/netplan/01-static.yaml
network:
  version: 2
  ethernets:
    ens192:   # Change to your actual interface name
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOL

        # Apply the netplan configuration
        netplan apply
    else
        echo "Netplan directory not found. Please check your system configuration."
        exit 1
    fi
}

# Function to install required software
install_software() {
    print_msg "Installing required software"

    # Update package list
    apt update

    # Install required software
    apt install -y openssh-server apache2 squid ufw
}

# Function to configure firewall using ufw
configure_firewall() {
    print_msg "Configuring firewall"

    # Allow SSH, HTTP, HTTPS, and Squid
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 3128

    # Enable firewall
    ufw --force enable
}

# Function to create user accounts and configure ssh keys
create_user_accounts() {
    print_msg "Creating user accounts and configuring ssh keys"

    # Create users
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for user in "${users[@]}"; do
        # Create user with home directory and bash shell
        useradd -m -s /bin/bash "$user"

        # Add SSH keys for RSA and Ed25519 algorithms
        mkdir -p "/home/$user/.ssh"
        cat <<EOL > "/home/$user/.ssh/authorized_keys"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
# Add other public keys as needed
EOL

        # Set proper permissions
        chown -R "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"
        chmod 600 "/home/$user/.ssh/authorized_keys"

        # Add user to sudo group if it's dennis
        if [ "$user" == "dennis" ]; then
            usermod -aG sudo "$user"
        fi
    done
}

# Main script

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script with sudo."
    exit 1
fi

# Check if the system is Ubuntu 22.04
if [ "$(lsb_release -r -s)" != "22.04" ]; then
    echo "This script is designed for Ubuntu 22.04. Exiting."
    exit 1
fi

# Run functions
update_network_config
install_software
configure_firewall
create_user_accounts

print_msg "Script execution completed successfully."
