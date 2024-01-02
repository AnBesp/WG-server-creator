# README for WireGuard VPN Server Script

## Introduction
This repository contains a script to create a WireGuard VPN server on a VPS using OpenVZ/LXC with Ubuntu 22.04 LTS as the operating system. It utilizes `wireguard-go` and `wireguard-ui` to facilitate a user-friendly, secure VPN service.

## Prerequisites
- A VPS with OpenVZ/LXC support.
- Ubuntu 22.04 LTS installed on your VPS.
- Root or sudo privileges on the VPS.

## Precheck - Default Interface
Before installation, ensure that your VPS's default network interface is correctly identified. The script relies on this information for proper configuration. You can check the default interface using the following command:
```bash
ip route | grep default
```
Note the interface name, usually something like `eth0` or `ens3`.

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
