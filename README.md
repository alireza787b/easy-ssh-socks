# 🚀 Enhanced SSH SOCKS Proxy v2.0

**The bulletproof SOCKS5 proxy that never gives up!**

Transform any SSH server into a reliable, self-healing SOCKS5 proxy with automatic reconnection, health monitoring, and zero-maintenance operation.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

## ✨ What Makes This Special?

Unlike basic SSH tunneling scripts, this enhanced version includes:

- 🔄 **Auto-Reconnection** - Handles network drops, server reboots, and connection timeouts
- 🏥 **Health Monitoring** - Multi-layer health checks every 30 seconds
- 🧠 **Smart Retry Logic** - Exponential backoff prevents server overload
- 📊 **Statistics Tracking** - Monitor uptime, reconnections, and performance
- 🛡️ **Bulletproof Design** - Survives terminal closures and system hibernation
- 📝 **Comprehensive Logging** - Know exactly what's happening

## 🚀 Quick Start (30 seconds)

### 1. Download & Setup
```bash
# Clone the repository
git clone https://github.com/alireza787b/easy-ssh-socks.git
cd easy-ssh-socks
chmod +x socks-proxy.sh
```

### 2. Configure (Edit these 2 lines)
```bash
# Open the script and change these variables:
REMOTE_USER="your-username"          # Your SSH username
REMOTE_HOST="your-server.com"        # Your server IP or hostname
```

### 3. Setup SSH Keys (Recommended)
```bash
./socks-proxy.sh setup
```

### 4. Start the Magic ✨
```bash
./socks-proxy.sh start
```

**That's it!** Your proxy is now running with automatic reconnection and health monitoring.

## 📱 Configure Your Apps

Use these settings in any application:

| Setting | Value |
|---------|-------|
| **Proxy Type** | SOCKS5 |
| **Server** | `127.0.0.1` |
| **Port** | `1337` |
| **Authentication** | None |

### Popular Apps Setup

<details>
<summary><strong>🦊 Firefox</strong></summary>

1. Settings → General → Network Settings
2. Select "Manual proxy configuration"
3. SOCKS Host: `127.0.0.1` Port: `1337`
4. Select "SOCKS v5"
5. Check "Proxy DNS when using SOCKS v5"
</details>

<details>
<summary><strong>🌐 Chrome/Edge</strong></summary>

Install a proxy extension like:
- [Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif)
- [FoxyProxy](https://chrome.google.com/webstore/detail/foxyproxy-standard/gcknhkkoolaabfmlnjonogaaifnjlfnp)
</details>

<details>
<summary><strong>💻 Command Line</strong></summary>

```bash
# Test your proxy
curl --socks5 127.0.0.1:1337 http://httpbin.org/ip

# Use with any curl command
curl --socks5 127.0.0.1:1337 https://api.example.com

# Set as environment variable
export ALL_PROXY=socks5://127.0.0.1:1337
```
</details>

## 🎮 Commands

| Command | Description |
|---------|-------------|
| `./socks-proxy.sh start` | Start the robust proxy with health monitoring |
| `./socks-proxy.sh status` | Show detailed status and statistics |
| `./socks-proxy.sh stop` | Stop the proxy and health monitor |
| `./socks-proxy.sh restart` | Restart the entire system |
| `./socks-proxy.sh logs` | View recent log entries |
| `./socks-proxy.sh setup` | Setup SSH keys for passwordless auth |

## 🔍 What's Under the Hood?

### The Health Monitoring System

The enhanced version runs a **background health monitor** that:

1. **Process Check** - Verifies SSH tunnel is running
2. **Port Check** - Confirms SOCKS5 port is listening  
3. **Functionality Test** - Actually tests proxy with HTTP requests
4. **Auto-Healing** - Restarts failed connections immediately

### Smart Reconnection Logic

When issues are detected:
- **Attempt 1**: Reconnect in 5 seconds
- **Attempt 2**: Wait 10 seconds, then try
- **Attempt 3**: Wait 20 seconds, then try
- **Continues**: Up to 5 minutes maximum delay

This prevents overwhelming your server while ensuring quick recovery.

## 📊 Status Dashboard

Run `./socks-proxy.sh status` to see:

```
🚀 Enhanced SSH SOCKS Proxy Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📡 Configuration:
   Remote: user@server.com:22
   Local:  127.0.0.1:1337

🏥 Health Status:
   Proxy Status:     ✅ Running & Healthy
   Monitor Status:   ✅ Active
   Last Check:       2 seconds ago

📊 Statistics:
   Uptime:          2h 34m 12s
   Reconnections:   3
   Success Rate:    99.2%
```

## 🆚 v1.0 vs v2.0 Enhanced

| Feature | v1.0 Basic | v2.0 Enhanced |
|---------|------------|---------------|
| Manual restart needed | ❌ | ✅ Automatic |
| Connection monitoring | ❌ | ✅ Every 30s |
| Network interruption handling | ❌ | ✅ Smart retry |
| Statistics tracking | ❌ | ✅ Detailed stats |
| Background persistence | ❌ | ✅ Daemon mode |
| Health validation | Basic | ✅ Multi-layer |

## 🛠️ Troubleshooting

<details>
<summary><strong>❌ "Port already in use"</strong></summary>

Change the `PROXY_PORT` in the script to a different number:
```bash
PROXY_PORT="8080"  # or 1338, 9050, etc.
```
</details>

<details>
<summary><strong>❌ "SSH connection failed"</strong></summary>

```bash
# Test your SSH connection
./socks-proxy.sh test

# Re-setup SSH keys
./socks-proxy.sh setup

# Check SSH manually
ssh your-username@your-server.com
```
</details>

<details>
<summary><strong>❌ "Proxy not working"</strong></summary>

```bash
# Check detailed status
./socks-proxy.sh status

# View recent logs
./socks-proxy.sh logs

# Test proxy directly
curl --socks5 127.0.0.1:1337 http://httpbin.org/ip
```
</details>

## ⚙️ Advanced Configuration

Want to customize the behavior? Edit these optional settings:

```bash
# Robustness settings
HEALTH_CHECK_INTERVAL=30        # Health check frequency (seconds)
MAX_RETRY_ATTEMPTS=5            # Max consecutive retries
INITIAL_RETRY_DELAY=5           # Starting retry delay
MAX_RETRY_DELAY=300             # Maximum retry delay (5 minutes)

# Network settings
LOCAL_BIND_IP="127.0.0.1"       # "0.0.0.0" for remote access
CONNECTION_TIMEOUT=15           # SSH connection timeout
```

## 📋 Requirements

- **Linux/macOS** with Bash
- **SSH client** (usually pre-installed)
- **Network access** to a remote server
- **SSH access** to that server

## 📚 Documentation

- **[📖 Complete Documentation](docs.md)** - Detailed setup, configuration, and troubleshooting
- **[🔒 Security Guide](docs.md#security-considerations)** - Best practices and hardening
- **[🚀 Production Setup](docs.md#production-deployment)** - Systemd services and monitoring

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ for the Linux community
- Thanks to all contributors and users
- Inspired by the need for bulletproof proxy solutions

---

**⭐ If this project helped you, please give it a star!**

**Made with ❤️ by [Alireza Ghaderi](https://linkedin.com/in/alireza787b)**