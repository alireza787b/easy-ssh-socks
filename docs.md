# Enhanced SSH SOCKS Proxy Manager v2.0

## 🚀 What's New in Version 2.0

This enhanced version transforms the original SSH SOCKS proxy script into a robust, production-ready solution that automatically maintains connections without user intervention.

### Key Improvements

#### 🔄 **Automatic Reconnection System**
- **Exponential Backoff**: Smart retry logic that starts with 5-second delays and increases up to 5 minutes
- **Connection Validation**: Multi-layer health checks ensure the proxy is actually working
- **Graceful Recovery**: Handles network interruptions, server restarts, and temporary connectivity issues
- **Persistent Operation**: Continues running even if the terminal is closed

#### 🏥 **Health Monitoring**
- **Real-time Monitoring**: Checks proxy health every 30 seconds (configurable)
- **Multi-layer Validation**: 
  - Process existence check
  - Port listening verification
  - Actual proxy functionality test via HTTP request
- **Automatic Healing**: Detects and fixes unhealthy connections immediately

#### 📊 **Connection Statistics**
- **Uptime Tracking**: Shows total connection time
- **Reconnection Counter**: Tracks how many times the proxy has reconnected
- **Historical Data**: Maintains statistics across restarts

#### 🛡️ **Enhanced Error Handling**
- **Timeout Protection**: All operations have sensible timeouts
- **Resource Cleanup**: Proper cleanup of processes and files
- **Detailed Logging**: Comprehensive logging with different levels (INFO, WARNING, ERROR, DEBUG)

## 📋 Installation & Setup

### 1. Download and Prepare
```bash
# Download the script
curl -O https://raw.githubusercontent.com/your-repo/socks-proxy.sh
# Make it executable
chmod +x socks-proxy.sh
```

### 2. Configure the Script
Edit the configuration section at the top of the script:

```bash
# Essential settings
REMOTE_USER="your-username"          # Your SSH username
REMOTE_HOST="your-server.com"        # Your server IP or hostname
REMOTE_PORT="22"                     # SSH port (usually 22)
PROXY_PORT="1337"                    # Local SOCKS5 port

# Robustness settings (optional)
HEALTH_CHECK_INTERVAL=30             # Health check frequency (seconds)
MAX_RETRY_ATTEMPTS=5                 # Max consecutive retry attempts
ENABLE_AUTO_RECONNECT=true           # Enable automatic reconnection
```

### 3. Setup SSH Keys (Recommended)
```bash
./socks-proxy.sh setup
```
This will:
- Generate SSH keys if needed
- Copy the public key to your server
- Test the connection
- Enable passwordless authentication

### 4. Start the Proxy
```bash
./socks-proxy.sh start
```

## 🎯 Usage Guide

### Command Line Interface

| Command | Description |
|---------|-------------|
| `start` | Start the robust proxy with health monitoring |
| `stop` | Stop the proxy and health monitor |
| `restart` | Restart the entire proxy system |
| `status` | Show detailed status and statistics |
| `setup` | Setup SSH keys for passwordless authentication |
| `test` | Test SSH connection to remote server |
| `logs` | Show recent log entries |
| `help` | Display help information |

### Interactive Menu
Run without arguments for a user-friendly menu:
```bash
./socks-proxy.sh
```

## 🔧 Advanced Configuration

### Robustness Settings

```bash
# Health check frequency (minimum 10 seconds)
HEALTH_CHECK_INTERVAL=30

# Maximum retry attempts before giving up
MAX_RETRY_ATTEMPTS=5

# Initial retry delay (grows exponentially)
INITIAL_RETRY_DELAY=5

# Maximum retry delay (caps exponential growth)
MAX_RETRY_DELAY=300

# SSH connection timeout
CONNECTION_TIMEOUT=15

# Enable/disable automatic reconnection
ENABLE_AUTO_RECONNECT=true
```

### SSH Options
The script uses optimized SSH options for stability:
```bash
SSH_OPTIONS="-o ConnectTimeout=15 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o TCPKeepAlive=yes"
```

## 📊 Monitoring & Statistics

### Status Information
The `status` command shows:
- Current configuration
- Proxy health status
- Health monitor status
- Connection statistics
- Uptime information
- Reconnection history

### Log Files
- **Location**: `/tmp/socks_proxy_[PORT].log`
- **Levels**: INFO, WARNING, ERROR, DEBUG
- **Rotation**: Logs are appended (consider log rotation for long-term use)

### Statistics File
- **Location**: `/tmp/socks_stats_[PORT].json`
- **Contains**: Start time, reconnection count, uptime data
- **Format**: JSON (can be parsed by other tools)

## 🔄 How Auto-Reconnection Works

### Health Check Process
1. **Process Check**: Verify SSH process is running
2. **Port Check**: Confirm SOCKS5 port is listening
3. **Functionality Check**: Test actual proxy functionality via HTTP request
4. **Action**: If any check fails, trigger reconnection

### Reconnection Logic
1. **Detection**: Health monitor detects failure
2. **Cleanup**: Terminate unhealthy process
3. **Retry**: Attempt reconnection with exponential backoff
4. **Validation**: Verify new connection is healthy
5. **Statistics**: Update reconnection counters

### Exponential Backoff
- **Attempt 1**: 5 seconds
- **Attempt 2**: 10 seconds
- **Attempt 3**: 20 seconds
- **Attempt 4**: 40 seconds
- **Attempt 5**: 80 seconds
- **Maximum**: 300 seconds (5 minutes)

## 🖥️ Client Configuration

### Browser Setup (Firefox)
1. Go to Settings → General → Network Settings
2. Select "Manual proxy configuration"
3. Set SOCKS Host: `127.0.0.1` Port: `1337`
4. Select "SOCKS v5"

### Browser Setup (Chrome)
Use with proxy extensions like:
- Proxy SwitchyOmega
- FoxyProxy

### Command Line Tools
```bash
# curl
curl --socks5 127.0.0.1:1337 http://httpbin.org/ip

# wget
wget -e use_proxy=yes -e socks_proxy=127.0.0.1:1337 http://httpbin.org/ip

# git (for repositories)
git config --global http.proxy socks5://127.0.0.1:1337
```

## 🐛 Troubleshooting

### Common Issues

#### "Port already in use"
```bash
# Check what's using the port
sudo netstat -tulpn | grep :1337
# Or with ss
sudo ss -tulpn | grep :1337
# Kill the process or change PROXY_PORT
```

#### "SSH connection failed"
```bash
# Test SSH connection manually
ssh -v user@server.com
# Run the built-in test
./socks-proxy.sh test
```

#### "Proxy not working"
```bash
# Check status
./socks-proxy.sh status
# View logs
./socks-proxy.sh logs
# Test proxy functionality
curl --socks5 127.0.0.1:1337 http://httpbin.org/ip
```

### Debugging Mode
Enable debug logging by modifying the script:
```bash
# Add this line after SSH_CMD definition
SSH_CMD="$SSH_CMD -v"  # Enables SSH verbose mode
```

### Network Issues
If you experience frequent disconnections:
1. **Check Network Stability**: Use `ping` to test connectivity
2. **Adjust Health Check Interval**: Increase `HEALTH_CHECK_INTERVAL`
3. **Modify SSH Keep-Alive**: Adjust `ServerAliveInterval` in SSH_OPTIONS
4. **Check Server Logs**: Look at SSH logs on the remote server

## 🔒 Security Considerations

### SSH Key Security
- Use strong SSH keys (4096-bit RSA or Ed25519)
- Protect private keys with proper file permissions (600)
- Consider using SSH agent for key management
- Regularly rotate SSH keys

### Network Security
- The SOCKS5 proxy provides encrypted tunneling via SSH
- All traffic through the proxy is encrypted end-to-end
- Consider binding to localhost only (`LOCAL_BIND_IP="127.0.0.1"`) for local use
- Use strong passwords or key-based authentication

### Server Security
- Keep SSH server updated
- Use non-standard SSH ports if possible
- Configure fail2ban for brute force protection
- Monitor SSH logs for suspicious activity

## 📁 File Locations

| File | Purpose | Location |
|------|---------|----------|
| PID File | Main process ID | `/tmp/socks_proxy_[PORT].pid` |
| Daemon PID | Health monitor process ID | `/tmp/socks_daemon_[PORT].pid` |
| Log File | Application logs | `/tmp/socks_proxy_[PORT].log` |
| Statistics | Connection statistics | `/tmp/socks_stats_[PORT].json` |
| SSH Keys | Authentication keys | `~/.ssh/id_rsa` |

## 🚀 Production Deployment

### Systemd Service (Recommended)
Create a systemd service for automatic startup:

```ini
[Unit]
Description=SSH SOCKS Proxy
After=network.target

[Service]
Type=forking
User=your-username
ExecStart=/path/to/socks-proxy.sh start
ExecStop=/path/to/socks-proxy.sh stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Cron Job Backup
Add a cron job as backup monitoring:
```bash
# Check every 5 minutes and restart if needed
*/5 * * * * /path/to/socks-proxy.sh status >/dev/null || /path/to/socks-proxy.sh start
```

## 📈 Performance Tuning

### For High Traffic
```bash
# Increase SSH multiplexing
SSH_OPTIONS="$SSH_OPTIONS -o ControlMaster=auto -o ControlPath=/tmp/%r@%h:%p"

# Optimize TCP settings
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
```

### For Stability
```bash
# More aggressive keep-alive
SSH_OPTIONS="$SSH_OPTIONS -o ServerAliveInterval=15 -o ServerAliveCountMax=5"

# Shorter health check interval
HEALTH_CHECK_INTERVAL=15
```

## 🔄 Migration from v1.0

The enhanced version is fully backward compatible. Simply:
1. Replace the old script with the new one
2. Configuration remains the same
3. New features are enabled by default
4. No data loss or service interruption

## 🤝 Contributing

To contribute improvements:
1. Test thoroughly in different network conditions
2. Maintain backward compatibility
3. Add appropriate logging and error handling
4. Update documentation for new features

## 📞 Support

For issues or questions:
1. Check the logs: `./socks-proxy.sh logs`
2. Test connectivity: `./socks-proxy.sh test`
3. Review configuration settings
4. Check network connectivity and SSH access

The enhanced SSH SOCKS proxy is designed to be bulletproof - it should handle network interruptions, server restarts, and various failure modes automatically while providing detailed information about its operation.