# 🚀 Easy SSH SOCKS

**Simple SOCKS5 Proxy Manager via SSH Tunnels**

Create secure proxy connections with just one command! Perfect for bypassing restrictions, securing your internet connection, or accessing remote networks.

## ✨ Features

- 🎯 **Super Simple** - One script, zero configuration files
- 🔐 **Secure** - Uses SSH tunnels for encrypted connections
- 🚀 **Fast Setup** - Get running in under 2 minutes
- 🛠️ **User Friendly** - Interactive menu and command-line interface
- 🔑 **SSH Key Support** - Automated SSH key setup
- 📊 **Status Monitoring** - Real-time proxy status and health checks
- 🔄 **Process Management** - Clean start/stop/restart functionality
- 📝 **Comprehensive Logging** - Track all proxy activities
- 🌐 **Cross-Platform** - Works on any Linux distribution

## 🚀 Quick Start

### 1. Download the Script
```bash
wget https://raw.githubusercontent.com/yourusername/easy-ssh-socks/main/socks-proxy.sh
chmod +x socks-proxy.sh
```

### 2. Configure Your Server
Edit the script and update these variables:
```bash
REMOTE_USER="your-username"     # Your SSH username
REMOTE_HOST="your-server.com"   # Your server IP or hostname
```

### 3. Setup SSH Key (Recommended)
```bash
./socks-proxy.sh setup
```

### 4. Start the Proxy
```bash
./socks-proxy.sh start
```

### 5. Configure Your Applications
Use these settings in your browser or applications:
- **Proxy Type:** SOCKS5
- **Server:** 127.0.0.1 (or your local IP)
- **Port:** 1337 (or your configured port)
- **Authentication:** None

## 📋 Prerequisites

- **SSH Client** (openssh-client) - Usually pre-installed on Linux
- **Network Access** to your remote server
- **SSH Access** to a remote server with internet connection

### Install SSH Client (if needed)
```bash
# Ubuntu/Debian
sudo apt-get install openssh-client

# CentOS/RHEL/Rocky Linux
sudo yum install openssh-clients

# Arch Linux
sudo pacman -S openssh

# Alpine Linux
sudo apk add openssh-client
```

## 🎮 Usage

### Interactive Menu
Simply run the script without arguments for an interactive menu:
```bash
./socks-proxy.sh
```

### Command Line Interface
```bash
./socks-proxy.sh [COMMAND]

Commands:
  start    - Start the SOCKS5 proxy tunnel
  stop     - Stop the running proxy tunnel
  restart  - Restart the proxy tunnel
  status   - Show current proxy status
  setup    - Setup SSH key authentication
  help     - Show help information
```

### Examples
```bash
# Start the proxy
./socks-proxy.sh start

# Check status
./socks-proxy.sh status

# Setup SSH keys for passwordless login
./socks-proxy.sh setup

# Stop the proxy
./socks-proxy.sh stop
```

## ⚙️ Configuration

Edit these variables at the top of the script:

```bash
# Remote SSH server details
REMOTE_USER="root"                    # SSH username
REMOTE_HOST="your-server.com"         # Server IP or hostname
REMOTE_PORT="22"                      # SSH port

# Local proxy settings
PROXY_PORT="1337"                     # Local SOCKS5 port
LOCAL_BIND_IP="0.0.0.0"              # Bind IP address
```

### Configuration Options

| Variable | Description | Default | Notes |
|----------|-------------|---------|--------|
| `REMOTE_USER` | SSH username | `root` | Must have SSH access |
| `REMOTE_HOST` | Server hostname/IP | `your-server.com` | **Must be changed** |
| `REMOTE_PORT` | SSH port | `22` | Standard SSH port |
| `PROXY_PORT` | Local SOCKS5 port | `1337` | Use 1024-65535 |
| `LOCAL_BIND_IP` | Bind interface | `0.0.0.0` | `127.0.0.1` for localhost only |

## 🌐 Application Setup

### Firefox
1. Open Firefox Settings
2. Go to Network Settings
3. Select "Manual proxy configuration"
4. Set SOCKS Host: `127.0.0.1` Port: `1337`
5. Select "SOCKS v5"
6. Check "Proxy DNS when using SOCKS v5"

### Chrome/Chromium
Use with extensions like:
- FoxyProxy
- Proxy SwitchyOmega
- SwitchyOmega

### Command Line Tools
```bash
# Using curl
curl --socks5 127.0.0.1:1337 http://ipinfo.io

# Using wget
wget -e use_proxy=yes -e socks_proxy=127.0.0.1:1337 http://ipinfo.io

# Export for all applications
export ALL_PROXY=socks5://127.0.0.1:1337
```

### System-wide Proxy (Ubuntu/Debian)
```bash
# Add to ~/.bashrc or ~/.profile
export http_proxy=socks5://127.0.0.1:1337
export https_proxy=socks5://127.0.0.1:1337
export ftp_proxy=socks5://127.0.0.1:1337
```

## 🔐 SSH Key Authentication

For secure, passwordless authentication:

### Automatic Setup
```bash
./socks-proxy.sh setup
```

### Manual Setup
```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copy to server
ssh-copy-id user@your-server.com

# Test connection
ssh user@your-server.com exit
```

## 🛠️ Troubleshooting

### Common Issues

#### "Port already in use"
```bash
# Find what's using the port
sudo netstat -tulpn | grep :1337
# or
sudo ss -tulpn | grep :1337

# Kill the process or change PROXY_PORT
```

#### "SSH connection failed"
```bash
# Test SSH connection manually
ssh -v user@your-server.com

# Common solutions:
# 1. Check SSH service: sudo systemctl status sshd
# 2. Verify firewall: sudo ufw status
# 3. Check SSH config: /etc/ssh/sshd_config
```

#### "Permission denied"
```bash
# Make script executable
chmod +x socks-proxy.sh

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### "Proxy not working"
```bash
# Test the proxy
curl --socks5 127.0.0.1:1337 http://ipinfo.io

# Check if tunnel is active
./socks-proxy.sh status

# View logs
tail -f /tmp/socks_proxy_1337.log
```

### Debug Mode
Enable verbose SSH output by editing the script:
```bash
SSH_OPTIONS="-v -o ConnectTimeout=10 -o ServerAliveInterval=60"
```

## 📊 Advanced Usage

### Multiple Proxies
Run multiple instances with different ports:
```bash
# Copy script for different configs
cp socks-proxy.sh socks-proxy-server1.sh
cp socks-proxy.sh socks-proxy-server2.sh

# Edit each with different PROXY_PORT and REMOTE_HOST
```

### Background Service
Create a systemd service:
```bash
# Create service file
sudo tee /etc/systemd/system/socks-proxy.service > /dev/null <<EOF
[Unit]
Description=SOCKS5 SSH Proxy
After=network.target

[Service]
Type=forking
User=your-username
ExecStart=/path/to/socks-proxy.sh start
ExecStop=/path/to/socks-proxy.sh stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable socks-proxy
sudo systemctl start socks-proxy
```

### Monitoring and Alerts
```bash
# Check if proxy is running
if ! ./socks-proxy.sh status | grep -q "Running"; then
    echo "Proxy is down!" | mail -s "Proxy Alert" admin@example.com
fi
```

## 🔒 Security Considerations

### Best Practices
- ✅ Use SSH key authentication instead of passwords
- ✅ Change default SSH port (22) to a non-standard port
- ✅ Configure firewall to only allow necessary connections
- ✅ Regularly update your server and SSH software
- ✅ Use strong SSH key passphrases
- ✅ Monitor SSH logs for suspicious activity

### Server Hardening
```bash
# Disable password authentication (after setting up keys)
# Edit /etc/ssh/sshd_config:
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no  # Use non-root user

# Restart SSH service
sudo systemctl restart sshd
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup
```bash
git clone https://github.com/yourusername/easy-ssh-socks.git
cd easy-ssh-socks
./socks-proxy.sh help
```

### Reporting Issues
Please include:
- Your Linux distribution and version
- Error messages from the script
- Log file contents (`/tmp/socks_proxy_1337.log`)
- Steps to reproduce the issue

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ for the Linux community
- Inspired by the need for simple, secure proxy solutions
- Thanks to all contributors and users

## 📞 Support

- 🐛 **Bug Reports:** [GitHub Issues](https://github.com/alireza787b/easy-ssh-socks/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/alireza787b/easy-ssh-socks/discussions)
---

**Made with ❤️ by [Alireza Ghaderi](https://linkedin.com/in/alireza787b)**


*If this project helped you, please give it a ⭐ star!*
