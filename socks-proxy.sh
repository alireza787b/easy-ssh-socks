#!/bin/bash

# ============================================================================
# EASY SSH SOCKS - Simple SOCKS5 Proxy Manager via SSH Tunnels
# ============================================================================
# 
# Description: A user-friendly SOCKS5 proxy manager that creates secure SSH 
#              tunnels for proxy connections. Perfect for bypassing restrictions,
#              securing connections, or accessing remote networks.
#
# Author: Alireza Ghaderi (https://www.linkedin.com/in/alireza787b/)
# Version: 1.0.0
# License: MIT
# Repository: https://github.com/alireza787b/easy-ssh-socks
#
# Prerequisites:
#   - SSH client (openssh-client)
#   - Network connectivity to remote server
#   - Valid SSH credentials or key-based authentication
#
# Quick Start:
#   1. Edit the configuration section below
#   2. Run: chmod +x socks-proxy.sh
#   3. Run: ./socks-proxy.sh
#   4. Use menu option 6 to setup SSH keys (recommended)
#   5. Use menu option 1 to start the proxy
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

# Advanced SSH options (usually don't need to change)
SSH_OPTIONS="-o ConnectTimeout=10 -o ServerAliveInterval=60 -o ServerAliveCountMax=3"

# ============================================================================
# SYSTEM VARIABLES - DO NOT EDIT
# ============================================================================

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0.0"
PIDFILE="/tmp/socks_proxy_${PROXY_PORT}.pid"
LOGFILE="/tmp/socks_proxy_${PROXY_PORT}.log"
LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")

# SSH command construction
SSH_CMD="ssh -g -D ${LOCAL_BIND_IP}:${PROXY_PORT} -p ${REMOTE_PORT} -N -C ${SSH_OPTIONS} ${REMOTE_USER}@${REMOTE_HOST}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo
    echo "============================================"
    echo "🚀 Easy SSH SOCKS - SOCKS5 Proxy Manager"
    echo "============================================"
}

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate configuration
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
    
    return $errors
}

# Check prerequisites
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
    
    print_success "All prerequisites satisfied"
    return 0
}

# Test SSH connection
test_ssh_connection() {
    print_info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}..."
    
    if ssh ${SSH_OPTIONS} -p ${REMOTE_PORT} -o BatchMode=yes -o PasswordAuthentication=no ${REMOTE_USER}@${REMOTE_HOST} exit 2>/dev/null; then
        print_success "SSH connection successful (key-based authentication)"
        return 0
    else
        print_warning "SSH key-based authentication failed"
        print_info "You may need to setup SSH keys or use password authentication"
        return 1
    fi
}

# ============================================================================
# CORE PROXY FUNCTIONS
# ============================================================================

# Display current proxy status and configuration
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
    echo " PID File           : $PIDFILE"
    echo " Log File           : $LOGFILE"
    echo "----------------------------------------"
    
    # Check proxy status
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            print_success "Proxy Status: Running (PID: $PID)"
            
            # Check if port is actually listening
            if command_exists netstat; then
                if netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
                    print_success "Port $PROXY_PORT is listening"
                else
                    print_warning "Port $PROXY_PORT is not listening"
                fi
            elif command_exists ss; then
                if ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
                    print_success "Port $PROXY_PORT is listening"
                else
                    print_warning "Port $PROXY_PORT is not listening"
                fi
            fi
        else
            print_warning "PID file exists but process is not running"
            print_info "Cleaning up stale PID file..."
            rm -f "$PIDFILE"
        fi
    else
        print_error "Proxy Status: Not running"
    fi
    
    echo
    echo "💡 Usage Instructions:"
    echo "   Configure your applications to use SOCKS5 proxy:"
    echo "   Server: $LOCAL_IP (or 127.0.0.1 for local use)"
    echo "   Port: $PROXY_PORT"
    echo
}

# Start the SOCKS5 proxy
start_proxy() {
    print_info "Starting SOCKS5 proxy..."
    
    # Validate configuration first
    if ! validate_config; then
        print_error "Configuration validation failed. Please check your settings."
        return 1
    fi
    
    # Check if already running
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            print_warning "Proxy already running (PID: $PID)"
            return 0
        else
            print_info "Removing stale PID file..."
            rm -f "$PIDFILE"
        fi
    fi
    
    # Check if port is already in use
    if command_exists netstat; then
        if netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
            print_error "Port $PROXY_PORT is already in use by another process"
            return 1
        fi
    elif command_exists ss; then
        if ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
            print_error "Port $PROXY_PORT is already in use by another process"
            return 1
        fi
    fi
    
    # Start the SSH tunnel
    log_message "Starting SSH tunnel: $SSH_CMD"
    nohup $SSH_CMD > "$LOGFILE" 2>&1 &
    SSH_PID=$!
    
    # Save PID
    echo $SSH_PID > "$PIDFILE"
    
    # Wait a moment and check if it's still running
    sleep 2
    if ps -p $SSH_PID > /dev/null 2>&1; then
        print_success "SOCKS5 proxy started successfully!"
        print_success "PID: $SSH_PID"
        print_success "Listening on: ${LOCAL_BIND_IP}:${PROXY_PORT}"
        log_message "Proxy started successfully (PID: $SSH_PID)"
        
        # Show connection info
        echo
        print_info "Configure your applications with these settings:"
        echo "  Proxy Type: SOCKS5"
        echo "  Server: $LOCAL_IP (or 127.0.0.1)"
        echo "  Port: $PROXY_PORT"
        echo "  Authentication: None"
    else
        print_error "Failed to start proxy. Check the log file: $LOGFILE"
        rm -f "$PIDFILE"
        return 1
    fi
}

# Stop the SOCKS5 proxy
stop_proxy() {
    print_info "Stopping SOCKS5 proxy..."
    
    if [ ! -f "$PIDFILE" ]; then
        print_warning "Proxy is not running (no PID file found)"
        return 0
    fi
    
    PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -z "$PID" ]; then
        print_error "Invalid PID file"
        rm -f "$PIDFILE"
        return 1
    fi
    
    if ps -p "$PID" > /dev/null 2>&1; then
        print_info "Terminating process (PID: $PID)..."
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
        fi
        
        print_success "Proxy stopped successfully"
        log_message "Proxy stopped (PID: $PID)"
    else
        print_warning "Process not found, cleaning up PID file"
    fi
    
    rm -f "$PIDFILE"
}

# Restart the proxy
restart_proxy() {
    print_info "Restarting SOCKS5 proxy..."
    stop_proxy
    sleep 2
    start_proxy
}

# Setup SSH key for passwordless authentication
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
}

# Show help information
print_help() {
    print_header
    echo
    echo "📘 Usage: $SCRIPT_NAME [COMMAND]"
    echo
    echo "COMMANDS:"
    echo "  start    - Start the SOCKS5 proxy tunnel"
    echo "  stop     - Stop the running proxy tunnel"
    echo "  restart  - Restart the proxy tunnel"
    echo "  status   - Show current proxy status and configuration"
    echo "  setup    - Setup SSH key for passwordless authentication"
    echo "  help     - Show this help message"
    echo
    echo "CONFIGURATION:"
    echo "  Edit the configuration section at the top of this script:"
    echo "  - REMOTE_USER: SSH username"
    echo "  - REMOTE_HOST: Remote server IP or hostname"
    echo "  - REMOTE_PORT: SSH port (default: 22)"
    echo "  - PROXY_PORT: Local SOCKS5 proxy port"
    echo "  - LOCAL_BIND_IP: Bind IP (0.0.0.0 for all interfaces)"
    echo
    echo "EXAMPLES:"
    echo "  $SCRIPT_NAME start     # Start the proxy"
    echo "  $SCRIPT_NAME status    # Check proxy status"
    echo "  $SCRIPT_NAME setup     # Setup SSH keys"
    echo
    echo "PROXY USAGE:"
    echo "  Configure your applications to use SOCKS5 proxy:"
    echo "  - Server: $LOCAL_IP (or 127.0.0.1)"
    echo "  - Port: $PROXY_PORT"
    echo "  - No authentication required"
    echo
    echo "COMMON APPLICATIONS:"
    echo "  - Firefox: Settings → Network → Manual proxy"
    echo "  - Chrome: Use with proxy extensions"
    echo "  - curl: curl --socks5 $LOCAL_IP:$PROXY_PORT http://example.com"
    echo
}

# Interactive menu for user-friendly operation
interactive_menu() {
    while true; do
        print_status
        echo "🔧 What would you like to do?"
        echo "----------------------------------------"
        echo "  1) Start proxy"
        echo "  2) Stop proxy"
        echo "  3) Restart proxy"
        echo "  4) Show status"
        echo "  5) Setup SSH key"
        echo "  6) Show help"
        echo "  7) View log file"
        echo "  0) Exit"
        echo "----------------------------------------"
        
        read -p "👉 Enter your choice (0-7): " choice
        echo
        
        case $choice in
            1) start_proxy ;;
            2) stop_proxy ;;
            3) restart_proxy ;;
            4) print_status ;;
            5) setup_ssh_key ;;
            6) print_help ;;
            7) 
                if [ -f "$LOGFILE" ]; then
                    print_info "Last 20 lines of log file:"
                    echo "----------------------------------------"
                    tail -20 "$LOGFILE"
                    echo "----------------------------------------"
                else
                    print_info "No log file found"
                fi
                ;;
            0) 
                print_success "Goodbye! 👋"
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

# Trap to cleanup on script exit
cleanup() {
    print_info "Script interrupted. Cleaning up..."
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
