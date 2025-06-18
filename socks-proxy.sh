#!/bin/bash

# ============================================================================
# EASY SSH SOCKS - Robust SOCKS5 Proxy Manager via SSH Tunnels
# ============================================================================
# 
# Description: A robust, self-healing SOCKS5 proxy manager that creates secure 
#              SSH tunnels with automatic reconnection, health monitoring, and
#              persistent connection management.
#
# Author: Enhanced by AI Assistant based on Alireza Ghaderi's original work
# Version: 2.0.0
# License: MIT
# Repository: https://github.com/alireza787b/easy-ssh-socks
#
# New Features in v2.0:
#   - Automatic reconnection with exponential backoff
#   - Health monitoring and connection validation
#   - Persistent daemon mode for background operation
#   - Better error handling and recovery
#   - Connection statistics and monitoring
#   - Graceful handling of network interruptions
#
# Prerequisites:
#   - SSH client (openssh-client)
#   - Network connectivity to remote server
#   - Valid SSH credentials or key-based authentication
#
# Quick Start:
#   1. Edit the configuration section below
#   2. Run: chmod +x socks-proxy.sh
#   3. Run: ./socks-proxy.sh setup (recommended for SSH keys)
#   4. Run: ./socks-proxy.sh start
#   5. Proxy will maintain connection automatically
#
# ============================================================================

# ============================================================================
# CONFIGURATION SECTION - EDIT THESE VALUES
# ============================================================================

# Remote SSH server details
REMOTE_USER="root"                    # SSH username on remote server
REMOTE_HOST="your-server.com"         # Remote server IP or hostname
REMOTE_PORT="22"                      # SSH port (usually 22)

# Local proxy settings
PROXY_PORT="1337"                     # Local port for SOCKS5 proxy
LOCAL_BIND_IP="0.0.0.0"              # Bind IP (0.0.0.0 = all interfaces, 127.0.0.1 = localhost only)

# Robustness settings (NEW)
HEALTH_CHECK_INTERVAL=30              # Seconds between health checks
MAX_RETRY_ATTEMPTS=5                  # Maximum consecutive retry attempts
INITIAL_RETRY_DELAY=5                 # Initial retry delay in seconds
MAX_RETRY_DELAY=300                   # Maximum retry delay in seconds (5 minutes)
CONNECTION_TIMEOUT=15                 # SSH connection timeout in seconds
ENABLE_AUTO_RECONNECT=true            # Enable automatic reconnection
DAEMON_MODE=false                     # Run as daemon (background process)

# Advanced SSH options
SSH_OPTIONS="-o ConnectTimeout=${CONNECTION_TIMEOUT} -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o TCPKeepAlive=yes"

# ============================================================================
# SYSTEM VARIABLES - DO NOT EDIT
# ============================================================================

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0.0"
PIDFILE="/tmp/socks_proxy_${PROXY_PORT}.pid"
DAEMON_PIDFILE="/tmp/socks_daemon_${PROXY_PORT}.pid"
LOGFILE="/tmp/socks_proxy_${PROXY_PORT}.log"
STATS_FILE="/tmp/socks_stats_${PROXY_PORT}.json"
LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")

# SSH command construction
SSH_CMD="ssh -g -D ${LOCAL_BIND_IP}:${PROXY_PORT} -p ${REMOTE_PORT} -N -C ${SSH_OPTIONS} ${REMOTE_USER}@${REMOTE_HOST}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Statistics variables
START_TIME=""
RECONNECT_COUNT=0
LAST_RECONNECT=""
TOTAL_UPTIME=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_debug() {
    echo -e "${PURPLE}🔍 DEBUG: $1${NC}"
}

print_header() {
    echo
    echo "============================================"
    echo "🚀 Easy SSH SOCKS - Robust Proxy Manager v${SCRIPT_VERSION}"
    echo "============================================"
}

# Enhanced logging with levels
log_message() {
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $1" >> "$LOGFILE"
}

log_error() {
    log_message "$1" "ERROR"
}

log_warning() {
    log_message "$1" "WARNING"
}

log_debug() {
    log_message "$1" "DEBUG"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Enhanced configuration validation
validate_config() {
    local errors=0
    
    if [[ -z "$REMOTE_USER" ]]; then
        print_error "REMOTE_USER is not set"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$REMOTE_HOST" ]]; then
        print_error "REMOTE_HOST is not set"
        errors=$((errors + 1))
    fi
    
    if [[ "$REMOTE_HOST" == "your-server.com" ]]; then
        print_error "Please configure REMOTE_HOST (currently set to default value)"
        errors=$((errors + 1))
    fi
    
    if ! [[ "$PROXY_PORT" =~ ^[0-9]+$ ]] || [ "$PROXY_PORT" -lt 1024 ] || [ "$PROXY_PORT" -gt 65535 ]; then
        print_error "PROXY_PORT must be a number between 1024-65535"
        errors=$((errors + 1))
    fi
    
    if ! [[ "$HEALTH_CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$HEALTH_CHECK_INTERVAL" -lt 10 ]; then
        print_error "HEALTH_CHECK_INTERVAL must be at least 10 seconds"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Check prerequisites with enhanced detection
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command_exists ssh; then
        print_error "SSH client not found. Please install openssh-client"
        print_info "Ubuntu/Debian: sudo apt-get install openssh-client"
        print_info "CentOS/RHEL: sudo yum install openssh-clients"
        print_info "Arch Linux: sudo pacman -S openssh"
        return 1
    fi
    
    if ! command_exists ssh-keygen; then
        print_error "ssh-keygen not found. Please install openssh-client"
        return 1
    fi
    
    if ! command_exists ssh-copy-id; then
        print_error "ssh-copy-id not found. Please install openssh-client"
        return 1
    fi
    
    # Check for optional but recommended tools
    if ! command_exists netstat && ! command_exists ss; then
        print_warning "Neither netstat nor ss found. Port checking will be limited."
    fi
    
    if ! command_exists curl && ! command_exists wget; then
        print_warning "Neither curl nor wget found. Connection testing will be limited."
    fi
    
    print_success "Prerequisites check completed"
    return 0
}

# Enhanced SSH connection test with timeout
test_ssh_connection() {
    print_info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}..."
    
    # Test with timeout
    if timeout ${CONNECTION_TIMEOUT} ssh ${SSH_OPTIONS} -p ${REMOTE_PORT} -o BatchMode=yes -o PasswordAuthentication=no ${REMOTE_USER}@${REMOTE_HOST} exit 2>/dev/null; then
        print_success "SSH connection successful (key-based authentication)"
        return 0
    else
        print_warning "SSH key-based authentication failed or timed out"
        print_info "You may need to setup SSH keys or check network connectivity"
        return 1
    fi
}

# ============================================================================
# STATISTICS AND MONITORING FUNCTIONS
# ============================================================================

# Initialize statistics
init_stats() {
    local current_time=$(date +%s)
    cat > "$STATS_FILE" <<EOF
{
    "start_time": $current_time,
    "start_time_human": "$(date)",
    "reconnect_count": 0,
    "last_reconnect": null,
    "total_downtime": 0,
    "version": "$SCRIPT_VERSION"
}
EOF
}

# Update statistics
update_stats() {
    local field="$1"
    local value="$2"
    
    if [ -f "$STATS_FILE" ]; then
        # Simple JSON update (works without jq)
        if [ "$field" = "reconnect_count" ]; then
            local current_count=$(grep '"reconnect_count"' "$STATS_FILE" | grep -o '[0-9]*')
            local new_count=$((current_count + 1))
            sed -i "s/\"reconnect_count\": [0-9]*/\"reconnect_count\": $new_count/" "$STATS_FILE"
        elif [ "$field" = "last_reconnect" ]; then
            sed -i "s/\"last_reconnect\": [^,]*/\"last_reconnect\": \"$(date)\"/" "$STATS_FILE"
        fi
    fi
}

# Get statistics
get_stats() {
    if [ -f "$STATS_FILE" ]; then
        local start_time=$(grep '"start_time"' "$STATS_FILE" | grep -o '[0-9]*' | head -1)
        local current_time=$(date +%s)
        local uptime=$((current_time - start_time))
        local reconnect_count=$(grep '"reconnect_count"' "$STATS_FILE" | grep -o '[0-9]*')
        
        echo "📈 Connection Statistics:"
        echo "   Total Uptime: $(format_duration $uptime)"
        echo "   Reconnections: $reconnect_count"
        
        if [ "$reconnect_count" -gt 0 ]; then
            local last_reconnect=$(grep '"last_reconnect"' "$STATS_FILE" | sed 's/.*"last_reconnect": "\([^"]*\)".*/\1/')
            echo "   Last Reconnect: $last_reconnect"
        fi
    fi
}

# Format duration in human readable format
format_duration() {
    local duration=$1
    local days=$((duration / 86400))
    local hours=$(((duration % 86400) / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    if [ $days -gt 0 ]; then
        echo "${days}d ${hours}h ${minutes}m ${seconds}s"
    elif [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# ============================================================================
# HEALTH MONITORING AND RECONNECTION FUNCTIONS
# ============================================================================

# Check if proxy is healthy
is_proxy_healthy() {
    local pid=$1
    
    # Check if process is running
    if ! ps -p "$pid" > /dev/null 2>&1; then
        log_debug "Process $pid is not running"
        return 1
    fi
    
    # Check if port is listening
    if command_exists netstat; then
        if ! netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
            log_debug "Port $PROXY_PORT is not listening (netstat)"
            return 1
        fi
    elif command_exists ss; then
        if ! ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
            log_debug "Port $PROXY_PORT is not listening (ss)"
            return 1
        fi
    fi
    
    # Advanced health check: try to connect through the proxy
    if command_exists curl; then
        if ! timeout 10 curl --socks5 "127.0.0.1:${PROXY_PORT}" -s "http://httpbin.org/ip" >/dev/null 2>&1; then
            log_debug "Proxy functionality test failed"
            return 1
        fi
    fi
    
    return 0
}

# Calculate retry delay with exponential backoff
calculate_retry_delay() {
    local attempt=$1
    local delay=$((INITIAL_RETRY_DELAY * (2 ** (attempt - 1))))
    
    if [ $delay -gt $MAX_RETRY_DELAY ]; then
        delay=$MAX_RETRY_DELAY
    fi
    
    echo $delay
}

# Start SSH tunnel with retry logic
start_ssh_tunnel() {
    local attempt=1
    local delay=$INITIAL_RETRY_DELAY
    
    while [ $attempt -le $MAX_RETRY_ATTEMPTS ]; do
        log_message "Starting SSH tunnel (attempt $attempt/$MAX_RETRY_ATTEMPTS)"
        
        # Start the SSH tunnel
        nohup $SSH_CMD > "$LOGFILE" 2>&1 &
        local ssh_pid=$!
        
        # Save PID
        echo $ssh_pid > "$PIDFILE"
        
        # Wait and check if it started successfully
        sleep 3
        
        if is_proxy_healthy $ssh_pid; then
            log_message "SSH tunnel started successfully (PID: $ssh_pid)"
            return 0
        else
            log_error "SSH tunnel failed to start properly (attempt $attempt)"
            
            # Kill the failed process if it's still running
            if ps -p $ssh_pid > /dev/null 2>&1; then
                kill $ssh_pid 2>/dev/null
            fi
            rm -f "$PIDFILE"
            
            if [ $attempt -lt $MAX_RETRY_ATTEMPTS ]; then
                delay=$(calculate_retry_delay $attempt)
                log_message "Retrying in $delay seconds..."
                sleep $delay
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to start SSH tunnel after $MAX_RETRY_ATTEMPTS attempts"
    return 1
}

# Health monitoring daemon
health_monitor_daemon() {
    log_message "Starting health monitor daemon"
    
    while true; do
        if [ -f "$PIDFILE" ]; then
            local pid=$(cat "$PIDFILE" 2>/dev/null)
            
            if [ -n "$pid" ]; then
                if is_proxy_healthy "$pid"; then
                    log_debug "Health check passed for PID $pid"
                else
                    log_warning "Health check failed for PID $pid, attempting reconnection"
                    
                    # Kill the unhealthy process
                    if ps -p "$pid" > /dev/null 2>&1; then
                        kill "$pid" 2>/dev/null
                    fi
                    rm -f "$PIDFILE"
                    
                    # Update statistics
                    update_stats "reconnect_count" ""
                    update_stats "last_reconnect" ""
                    
                    # Attempt to restart
                    if start_ssh_tunnel; then
                        log_message "Successfully reconnected proxy"
                    else
                        log_error "Failed to reconnect proxy, will retry on next health check"
                    fi
                fi
            fi
        else
            log_debug "No PID file found, proxy appears to be stopped"
            break
        fi
        
        sleep "$HEALTH_CHECK_INTERVAL"
    done
    
    log_message "Health monitor daemon stopped"
}

# ============================================================================
# ENHANCED CORE PROXY FUNCTIONS
# ============================================================================

# Enhanced status display
print_status() {
    print_header
    echo
    echo "📊 Current Configuration:"
    echo "----------------------------------------"
    echo " Script Version     : $SCRIPT_VERSION"
    echo " Local IP Address   : $LOCAL_IP"
    echo " Proxy Bind IP      : $LOCAL_BIND_IP"
    echo " Proxy Port         : $PROXY_PORT"
    echo " Remote SSH Target  : $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
    echo " Auto-Reconnect     : $ENABLE_AUTO_RECONNECT"
    echo " Health Check       : ${HEALTH_CHECK_INTERVAL}s intervals"
    echo " PID File           : $PIDFILE"
    echo " Log File           : $LOGFILE"
    echo "----------------------------------------"
    
    # Check proxy status
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            if is_proxy_healthy "$PID"; then
                print_success "Proxy Status: Running and Healthy (PID: $PID)"
            else
                print_warning "Proxy Status: Running but Unhealthy (PID: $PID)"
            fi
            
            # Show daemon status
            if [ -f "$DAEMON_PIDFILE" ]; then
                local daemon_pid=$(cat "$DAEMON_PIDFILE" 2>/dev/null)
                if [ -n "$daemon_pid" ] && ps -p "$daemon_pid" > /dev/null 2>&1; then
                    print_success "Health Monitor: Active (PID: $daemon_pid)"
                else
                    print_warning "Health Monitor: Not running"
                    rm -f "$DAEMON_PIDFILE"
                fi
            else
                print_info "Health Monitor: Not running"
            fi
        else
            print_warning "PID file exists but process is not running"
            print_info "Cleaning up stale PID file..."
            rm -f "$PIDFILE"
        fi
    else
        print_error "Proxy Status: Not running"
    fi
    
    # Show statistics
    if [ -f "$STATS_FILE" ]; then
        echo
        get_stats
    fi
    
    echo
    echo "💡 Usage Instructions:"
    echo "   Configure your applications to use SOCKS5 proxy:"
    echo "   Server: $LOCAL_IP (or 127.0.0.1 for local use)"
    echo "   Port: $PROXY_PORT"
    echo "   No authentication required"
    echo
}

# Enhanced start function with daemon support
start_proxy() {
    print_info "Starting robust SOCKS5 proxy..."
    
    # Validate configuration first
    if ! validate_config; then
        print_error "Configuration validation failed. Please check your settings."
        return 1
    fi
    
    # Check if already running
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            if is_proxy_healthy "$PID"; then
                print_warning "Proxy already running and healthy (PID: $PID)"
                return 0
            else
                print_info "Existing proxy is unhealthy, stopping it first..."
                stop_proxy
            fi
        else
            print_info "Removing stale PID file..."
            rm -f "$PIDFILE"
        fi
    fi
    
    # Initialize statistics
    init_stats
    
    # Start the SSH tunnel
    if start_ssh_tunnel; then
        local ssh_pid=$(cat "$PIDFILE")
        print_success "SOCKS5 proxy started successfully!"
        print_success "PID: $ssh_pid"
        print_success "Listening on: ${LOCAL_BIND_IP}:${PROXY_PORT}"
        
        # Start health monitoring daemon if auto-reconnect is enabled
        if [ "$ENABLE_AUTO_RECONNECT" = "true" ]; then
            print_info "Starting health monitoring daemon..."
            
            # Start daemon in background
            (health_monitor_daemon) &
            local daemon_pid=$!
            echo $daemon_pid > "$DAEMON_PIDFILE"
            
            print_success "Health monitor started (PID: $daemon_pid)"
            print_info "Proxy will automatically reconnect if connection is lost"
        fi
        
        # Show connection info
        echo
        print_info "Configure your applications with these settings:"
        echo "  Proxy Type: SOCKS5"
        echo "  Server: $LOCAL_IP (or 127.0.0.1)"
        echo "  Port: $PROXY_PORT"
        echo "  Authentication: None"
        
        log_message "Proxy started successfully with health monitoring"
        return 0
    else
        print_error "Failed to start proxy after multiple attempts"
        return 1
    fi
}

# Enhanced stop function
stop_proxy() {
    print_info "Stopping SOCKS5 proxy and health monitor..."
    
    local stopped_something=false
    
    # Stop health monitoring daemon first
    if [ -f "$DAEMON_PIDFILE" ]; then
        local daemon_pid=$(cat "$DAEMON_PIDFILE" 2>/dev/null)
        if [ -n "$daemon_pid" ] && ps -p "$daemon_pid" > /dev/null 2>&1; then
            print_info "Stopping health monitor daemon (PID: $daemon_pid)..."
            kill "$daemon_pid" 2>/dev/null
            
            # Wait for daemon to stop
            local count=0
            while ps -p "$daemon_pid" > /dev/null 2>&1 && [ $count -lt 5 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            if ps -p "$daemon_pid" > /dev/null 2>&1; then
                kill -9 "$daemon_pid" 2>/dev/null
            fi
            
            print_success "Health monitor stopped"
            stopped_something=true
        fi
        rm -f "$DAEMON_PIDFILE"
    fi
    
    # Stop main proxy process
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            print_info "Terminating proxy process (PID: $PID)..."
            kill "$PID" 2>/dev/null
            
            # Wait for process to terminate
            local count=0
            while ps -p "$PID" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            if ps -p "$PID" > /dev/null 2>&1; then
                print_warning "Process didn't terminate gracefully, using force..."
                kill -9 "$PID" 2>/dev/null
                sleep 1
            fi
            
            print_success "Proxy stopped successfully"
            log_message "Proxy stopped (PID: $PID)"
            stopped_something=true
        fi
        rm -f "$PIDFILE"
    fi
    
    if ! $stopped_something; then
        print_warning "Proxy was not running"
    fi
    
    # Clean up statistics file
    rm -f "$STATS_FILE"
}

# Enhanced restart function
restart_proxy() {
    print_info "Restarting robust SOCKS5 proxy..."
    stop_proxy
    sleep 3
    start_proxy
}

# Setup SSH key for passwordless authentication (unchanged but with better logging)
setup_ssh_key() {
    print_header
    echo
    print_info "Setting up SSH key for passwordless authentication..."
    
    # Validate configuration
    if ! validate_config; then
        print_error "Please configure REMOTE_USER and REMOTE_HOST first"
        return 1
    fi
    
    # Check if SSH directory exists
    if [ ! -d ~/.ssh ]; then
        print_info "Creating ~/.ssh directory..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
    fi
    
    # Check if SSH key already exists
    if [ -f ~/.ssh/id_rsa ]; then
        print_info "SSH key already exists at ~/.ssh/id_rsa"
        read -p "Do you want to use the existing key? (y/n): " use_existing
        if [[ $use_existing =~ ^[Nn] ]]; then
            read -p "Enter new key filename (default: id_rsa_socks): " key_name
            key_name=${key_name:-id_rsa_socks}
            key_path="~/.ssh/$key_name"
        else
            key_path="~/.ssh/id_rsa"
        fi
    else
        print_info "Generating new SSH key pair..."
        key_path="~/.ssh/id_rsa"
        
        # Generate SSH key
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "socks-proxy-$(date +%Y%m%d)"
        
        if [ $? -eq 0 ]; then
            print_success "SSH key generated successfully"
        else
            print_error "Failed to generate SSH key"
            return 1
        fi
    fi
    
    # Copy key to remote server
    print_info "Copying SSH key to ${REMOTE_USER}@${REMOTE_HOST}..."
    print_info "You will be prompted for the password..."
    
    if ssh-copy-id -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}; then
        print_success "SSH key copied successfully!"
        print_success "You can now use passwordless authentication"
        
        # Test the connection
        echo
        test_ssh_connection
    else
        print_error "Failed to copy SSH key"
        print_info "Please check your credentials and network connectivity"
        return 1
    fi
    
    log_message "SSH key setup completed"
}

# Enhanced help with new features
print_help() {
    print_header
    echo
    echo "📘 Usage: $SCRIPT_NAME [COMMAND]"
    echo
    echo "COMMANDS:"
    echo "  start    - Start the robust SOCKS5 proxy with health monitoring"
    echo "  stop     - Stop the proxy and health monitor"
    echo "  restart  - Restart the proxy system"
    echo "  status   - Show detailed proxy status and statistics"
    echo "  setup    - Setup SSH key for passwordless authentication"
    echo "  test     - Test SSH connection to remote server"
    echo "  logs     - Show recent log entries"
    echo "  help     - Show this help message"
    echo
    echo "ROBUST FEATURES (NEW in v2.0):"
    echo "  • Automatic reconnection with exponential backoff"
    echo "  • Health monitoring every ${HEALTH_CHECK_INTERVAL} seconds"
    echo "  • Connection statistics tracking"
    echo "  • Graceful handling of network interruptions"
    echo "  • Persistent background operation"
    echo
    echo "CONFIGURATION:"
    echo "  Edit the configuration section at the top of this script:"
    echo "  - REMOTE_USER: SSH username"
    echo "  - REMOTE_HOST: Remote server IP or hostname"
    echo "  - REMOTE_PORT: SSH port (default: 22)"
    echo "  - PROXY_PORT: Local SOCKS5 proxy port"
    echo "  - ENABLE_AUTO_RECONNECT: Enable automatic reconnection"
    echo "  - HEALTH_CHECK_INTERVAL: Seconds between health checks"
    echo
    echo "EXAMPLES:"
    echo "  $SCRIPT_NAME setup     # Setup SSH keys (recommended first step)"
    echo "  $SCRIPT_NAME start     # Start robust proxy with monitoring"
    echo "  $SCRIPT_NAME status    # Check detailed status and stats"
    echo "  $SCRIPT_NAME logs      # View recent activity"
    echo
    echo "PROXY USAGE:"
    echo "  Configure your applications to use SOCKS5 proxy:"
    echo "  - Server: $LOCAL_IP (or 127.0.0.1)"
    echo "  - Port: $PROXY_PORT"
    echo "  - No authentication required"
    echo
    echo "The proxy will automatically reconnect if the connection is lost!"
    echo
}

# New function to show logs
show_logs() {
    if [ -f "$LOGFILE" ]; then
        print_info "Recent log entries (last 30 lines):"
        echo "----------------------------------------"
        tail -30 "$LOGFILE"
        echo "----------------------------------------"
        echo "Full log file: $LOGFILE"
    else
        print_info "No log file found"
    fi
}

# Enhanced interactive menu
interactive_menu() {
    while true; do
        print_status
        echo "🔧 What would you like to do?"
        echo "----------------------------------------"
        echo "  1) Start robust proxy"
        echo "  2) Stop proxy"
        echo "  3) Restart proxy"
        echo "  4) Show detailed status"
        echo "  5) Setup SSH key"
        echo "  6) Test SSH connection"
        echo "  7) View recent logs"
        echo "  8) Show help"
        echo "  0) Exit"
        echo "----------------------------------------"
        
        read -p "👉 Enter your choice (0-8): " choice
        echo
        
        case $choice in
            1) start_proxy ;;
            2) stop_proxy ;;
            3) restart_proxy ;;
            4) print_status ;;
            5) setup_ssh_key ;;
            6) test_ssh_connection ;;
            7) show_logs ;;
            8) print_help ;;
            0) 
                print_success "Goodbye! 👋"
                print_info "Note: Proxy will continue running in background if started"
                exit 0 
                ;;
            *) 
                print_error "Invalid option '$choice'. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

# Enhanced cleanup function
cleanup() {
    print_info "Script interrupted. Proxy will continue running in background."
    print_info "Use '$SCRIPT_NAME stop' to stop the proxy."
    exit 0
}

trap cleanup INT TERM

# Check prerequisites on startup
if ! check_prerequisites; then
    exit 1
fi

# Main execution logic
if [ $# -eq 0 ]; then
    # No arguments provided - run interactive menu
    interactive_menu
else
    # Command-line arguments provided
    case "$1" in
        start)
            start_proxy
            ;;
        stop)
            stop_proxy
            ;;
        restart)
            restart_proxy
            ;;
        status)
            print_status
            ;;
        setup)
            setup_ssh_key
            ;;
        test)
            test_ssh_connection
            ;;
        logs)
            show_logs
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            print_error "Unknown command: '$1'"
            print_info "Use '$SCRIPT_NAME help' for usage information"
            exit 1
            ;;
    esac
fi