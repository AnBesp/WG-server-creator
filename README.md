# README for WireGuard VPN Server Script

## Introduction
This repository contains a script to create a WireGuard VPN server on a VPS using OpenVZ/LXC with Ubuntu 22.04 LTS as the operating system. It utilizes `wireguard-go` and `wireguard-ui` to facilitate a user-friendly, secure VPN service.

## Why `wireguard-go`?
We use `wireguard-go` instead of the standard WireGuard kernel module because, on some OpenVZ/LXC servers, the necessary kernel module for WireGuard is not available. `wireguard-go` is a userspace implementation of WireGuard that bypasses this limitation, ensuring wider compatibility across various server environments.

## Prerequisites
- A VPS with OpenVZ/LXC support.
- Ubuntu 22.04 LTS installed on your VPS.
- Root or sudo privileges on the VPS.

## Precheck - Default Interface and IP Forwarding
Before installation, check the default network interface and enable IP forwarding for both IPv4 and IPv6.

### Checking Default Interface
Find your default network interface using:
```bash
ip route | grep default
```
Note the interface name, typically `eth0`, `ens3`, etc.

### Enabling IP Forwarding for IPv4 and IPv6
IP forwarding is essential for routing VPN traffic. Enable it for both IPv4 and IPv6.

#### IPv4
Edit the sysctl configuration:
```bash
sudo nano /etc/sysctl.conf
```
Add or uncomment:
```
net.ipv4.ip_forward=1
```

#### IPv6
In the same file, add or uncomment:
```
net.ipv6.conf.all.forwarding=1
```

Apply the changes:
```bash
sudo sysctl -p
```

## Installation & Configuration

### Step 1: Clone the Repository
Clone this repository to your VPS. Ensure you have git installed.
```bash
git clone [repository URL]
cd [repository directory]
```

### Step 2: Install
Run the installation script. It will install `wireguard-go` and set up necessary configurations.
`wireguard-ui` provides a web interface for easier management.

```bash
sudo bash wg.sh
```

## Usage
Access the WireGuard UI through your web browser at `http://[your-vps-ip]:[port]`. From here, you can manage your VPN, including adding/removing clients and configuring network settings.

## Security
- Change the default passwords immediately after installation.
- Regularly update your system and WireGuard packages.
- Configure firewalls and restrict access to necessary ports only.

## Contributing
Contributions to the script are welcome. Please fork the repository, make your changes, and submit a pull request.

## Disclaimer
The use of this script and WireGuard VPN is subject to local laws and regulations. The creator is not responsible for any misuse or legal repercussions.
