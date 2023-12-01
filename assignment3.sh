#Name- Abdul Ahad Latif
Student ID- 200540032
#Subject- Linux Assignment3


#!/bin/bash

# Function to execute commands via SSH on target1-mgmt
function ssh_target1 {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null remoteadmin@172.16.1.10 "$@"
}

# Function to execute commands via SSH on target2-mgmt
function ssh_target2 {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null remoteadmin@172.16.1.11 "$@"
}

# Function to check if a command was successful
function check_success {
    if [ $? -eq 0 ]; then
        echo "Success"
    else
        echo "Failed"
    fi
}

# Execute commands on target1-mgmt
ssh_target1 '
    # Change hostname to loghost
    sudo hostnamectl set-hostname loghost
    sudo sed -i "s/target1/loghost/g" /etc/hosts

    # Change IP address on the lan
    sudo sed -i "s/172.16.1.10/172.16.1.3/g" /etc/netplan/*.yaml
    sudo netplan apply

    # Add webhost to /etc/hosts
    echo "172.16.1.4 webhost" | sudo tee -a /etc/hosts > /dev/null

    # Install and configure ufw
    sudo apt update
    sudo apt install ufw -y
    sudo ufw allow from 172.16.1.0/24 to any port 514/udp

    # Configure rsyslog to listen for UDP connections
    sudo sed -i "/^#module(load=\"imudp\"/s/^#//g" /etc/rsyslog.conf
    sudo sed -i "/^#input(type=\"imudp\"/s/^#//g" /etc/rsyslog.conf
    sudo systemctl restart rsyslog
'
check_success

# Execute commands on target2-mgmt
ssh_target2 '
    # Change hostname to webhost
    sudo hostnamectl set-hostname webhost
    sudo sed -i "s/target2/webhost/g" /etc/hosts

    # Change IP address on the lan
    sudo sed -i "s/172.16.1.11/172.16.1.4/g" /etc/netplan/*.yaml
    sudo netplan apply

    # Add loghost to /etc/hosts
    echo "172.16.1.3 loghost" | sudo tee -a /etc/hosts > /dev/null

    # Install and configure ufw
    sudo apt update
    sudo apt install ufw -y
    sudo ufw allow 80/tcp

    # Install Apache
    sudo apt install apache2 -y

    # Configure rsyslog on webhost
    echo ". @loghost" | sudo tee -a /etc/rsyslog.conf > /dev/null
    sudo systemctl restart rsyslog
'
check_success

# Update NMS /etc/hosts file
sudo sed -i '/loghost/d' /etc/hosts
sudo sed -i '/webhost/d' /etc/hosts
echo "172.16.1.3 loghost" | sudo tee -a /etc/hosts > /dev/null
echo "172.16.1.4 webhost" | sudo tee -a /etc/hosts > /dev/null

# Verify configurations using curl
curl -IsS http://webhost >/dev/null 2>&1
check_success

# Check if configurations were successful
if [ "$(check_success)" == "Success" ]; then
    echo "Configuration update succeeded. Web server is accessible."
else
    echo "Configuration update failed or web server is not accessible."
fi

# Check logs on loghost
ssh_target1 'grep webhost /var/log/syslog'
