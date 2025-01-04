#!/bin/bash
NoColor='\033[0m'
Green='\033[0;32m'
Cyan='\033[0;36m'
Red='\033[0;31m'
Yellow='\033[0;33m'
Bold='\033[1m'

COMMON_PORTS=(
    "21:FTP"
    "22:SSH"
    "23:Telnet"
    "25:SMTP"
    "53:DNS"
    "80:HTTP"
    "110:POP3"
    "143:IMAP"
    "443:HTTPS"
    "445:SMB"
    "3306:MySQL"
    "3389:RDP"
    "5432:PostgreSQL"
    "8080:HTTP-Proxy"
)

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

validate_hostname() {
    local hostname=$1
    if [[ $hostname =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*[a-zA-Z0-9]$ ]]; then
        return 0
    fi
    return 1
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    fi
    return 1
}

validate_port_range() {
    local start=$1
    local end=$2
    if validate_port "$start" && validate_port "$end" && [ "$start" -le "$end" ]; then
        return 0
    fi
    return 1
}

check_dependencies() {
    local missing_deps=()
    if ! command -v nc >/dev/null 2>&1; then
        missing_deps+=("netcat")
    fi
    if ! command -v telnet >/dev/null 2>&1; then
        missing_deps+=("telnet")
    fi
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${Yellow}${Bold}Missing recommended dependencies: ${missing_deps[*]}${NoColor}"
        echo -e "${Yellow}${Bold}Install them for better scan results${NoColor}"
        sleep 2
    fi
}

scan_tcp_port() {
    local host=$1
    local port=$2
    local is_open=false
    local service_name=""
    
    echo -e "${Cyan}${Bold}Scanning port $port...${NoColor}"
    
    if command -v nc >/dev/null 2>&1; then
        if nc -zv -w2 "$host" "$port" 2>&1 | grep -q "open"; then
            is_open=true
        fi
    fi
    
    if ! $is_open; then
        if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            is_open=true
        fi
    fi
    
    for port_info in "${COMMON_PORTS[@]}"; do
        IFS=':' read -r port_num service <<< "$port_info"
        if [ "$port" -eq "$port_num" ]; then
            service_name=" ($service)"
            break
        fi
    done
    
    if $is_open; then
        echo -e "${Green}${Bold}Port $port$service_name is open${NoColor}"
        return 0
    else
        echo -e "${Red}${Bold}Port $port$service_name is closed${NoColor}"
        return 1
    fi
}

scan_udp_port() {
    local host=$1
    local port=$2
    
    if ! command -v nc >/dev/null 2>&1; then
        echo -e "${Red}${Bold}Netcat is required for UDP scanning${NoColor}"
        return 1
    fi
    
    echo -e "${Cyan}${Bold}Scanning UDP port $port...${NoColor}"
    if nc -zuv -w2 "$host" "$port" 2>&1 | grep -q "open"; then
        echo -e "${Green}${Bold}UDP Port $port appears open${NoColor}"
        return 0
    else
        echo -e "${Red}${Bold}UDP Port $port appears closed or filtered${NoColor}"
        return 1
    fi
}

print_header() {
    clear
    echo -e "${Green}${Bold}════════════════════════════════════════════${NoColor}"
    echo -e "${Green}${Bold}   ADVANCED NETWORK RECONNAISSANCE SUITE    ${NoColor}"
    echo -e "${Green}${Bold}        Created by: Pranit Marathe          ${NoColor}"
    echo -e "${Green}${Bold}════════════════════════════════════════════${NoColor}"
    echo -e "${Cyan}${Bold}              Version 1.0.0                  ${NoColor}"
    echo
}

read_input() {
    local prompt=$1
    echo -en "${Green}${Bold}${prompt}${NoColor}"
    read -r response
    printf '%s' "$response"
}

scan_tcp() {
    local target
    
    echo -en "${Green}${Bold}Enter target (IP or Hostname): ${NoColor}"
    read -r target

    if ! validate_ip "$target" && ! validate_hostname "$target"; then
        echo -e "${Red}${Bold}Invalid target format!${NoColor}"
        sleep 2
        return
    fi
    

    echo -e "${Green}${Bold}┌────────────────────────────────────┐${NoColor}"
    echo -e "${Green}${Bold}│             TCP SCAN               │${NoColor}"
    echo -e "${Green}${Bold}├────────────────────────────────────┤${NoColor}"
    echo -e "${Green}${Bold}│ 1. Single port                     │${NoColor}"
    echo -e "${Green}${Bold}│ 2. Port range                      │${NoColor}"
    echo -e "${Green}${Bold}│ 3. Common TCP ports                │${NoColor}"
    echo -e "${Green}${Bold}└────────────────────────────────────┘${NoColor}"
    
    
    local scan_type
    echo -en "${Green}${Bold}Choice: ${NoColor}"
    read -r scan_type
    
    case $scan_type in
        1)
            local port
            echo -en "${Green}${Bold}Enter port (1-65535): ${NoColor}"
            read -r port
            if ! validate_port "$port"; then
                echo -e "${Red}${Bold}Invalid port number!${NoColor}"
                sleep 2
                return
            fi
            scan_tcp_port "$target" "$port"
            ;;
        2)
            local start_port end_port
            echo -en "${Green}${Bold}Start port: ${NoColor}"
            read -r start_port
            
            echo -en "${Green}${Bold}End port: ${NoColor}"
            read -r end_port
            
            
            if ! validate_port_range "$start_port" "$end_port"; then
                echo -e "${Red}${Bold}Invalid port range!${NoColor}"
                sleep 2
                return
            fi
            
            echo -e "${Cyan}${Bold}Scanning ports $start_port-$end_port on $target...${NoColor}"
            open_ports=0
            for port in $(seq "$start_port" "$end_port"); do
                if scan_tcp_port "$target" "$port"; then
                    ((open_ports++))
                fi
            done
            echo -e "${Cyan}${Bold}Found $open_ports open port(s)${NoColor}"
            ;;
        3)
            echo -e "${Cyan}${Bold}Scanning common ports on $target...${NoColor}"
            open_ports=0
            for port_info in "${COMMON_PORTS[@]}"; do
                IFS=':' read -r port service <<< "$port_info"
                if scan_tcp_port "$target" "$port"; then
                    ((open_ports++))
                fi
            done
            echo -e "${Cyan}${Bold}Found $open_ports open port(s)${NoColor}"
            ;;
        *)
            echo -e "${Red}${Bold}Invalid choice!${NoColor}"
            sleep 2
            return
            ;;
    esac
    
    echo
    echo -e "${Cyan}${Bold}Press Enter to continue...${NoColor}"
    read -r
}

scan_udp() {
    local target
    echo -en "${Green}${Bold}Enter target (IP or hostname): ${NoColor}"
    read -r target

    if ! validate_ip "$target" && ! validate_hostname "$target"; then
        echo -e "${Red}${Bold}Invalid target format!${NoColor}"
        sleep 2
        return
    fi

    echo -e "${Green}${Bold}┌────────────────────────────────────┐${NoColor}"
    echo -e "${Green}${Bold}│             UDP SCAN               │${NoColor}"
    echo -e "${Green}${Bold}├────────────────────────────────────┤${NoColor}"
    echo -e "${Green}${Bold}│ 1. Single port                     │${NoColor}"
    echo -e "${Green}${Bold}│ 2. Common UDP ports                │${NoColor}"
    echo -e "${Green}${Bold}└────────────────────────────────────┘${NoColor}"
    echo -en "${Green}${Bold}Select option: ${NoColor}"
    read -r scan_type

    case $scan_type in
        1)
            echo -en "${Green}${Bold}Enter port (1-65535): ${NoColor}"
            read -r port
            if ! validate_port "$port"; then
                echo -e "${Red}${Bold}Invalid port number!${NoColor}"
                sleep 2
                return
            fi
            scan_udp_port "$target" "$port"
            ;;
        2)
            echo -e "${Cyan}${Bold}Scanning common UDP ports on $target...${NoColor}"
            udp_ports=(53 67 68 69 123 161 162 514 1900 5353)
            open_ports=0
            for port in "${udp_ports[@]}"; do
                if scan_udp_port "$target" "$port"; then
                    ((open_ports++))
                fi
            done
            echo -e "${Cyan}${Bold}Found $open_ports open UDP port(s)${NoColor}"
            ;;
        *)
            echo -e "${Red}${Bold}Invalid choice!${NoColor}"
            sleep 2
            return
            ;;
    esac
    
    echo
    echo -e "${Cyan}${Bold}Press Enter to continue...${NoColor}"
    read -r
}

main_menu() {
    echo -e "${Green}${Bold}┌────────────────────────────────────┐${NoColor}"
    echo -e "${Green}${Bold}│             MAIN MENU              │${NoColor}"
    echo -e "${Green}${Bold}├────────────────────────────────────┤${NoColor}"
    echo -e "${Green}${Bold}│ 1. TCP Scan                        │${NoColor}"
    echo -e "${Green}${Bold}│ 2. UDP Scan                        │${NoColor}"
    echo -e "${Green}${Bold}│ 3. Exit                            │${NoColor}"
    echo -e "${Green}${Bold}└────────────────────────────────────┘${NoColor}"
    echo -en "${Green}${Bold}Choice: ${NoColor}"
    read -r choice
    case $choice in 
        1) scan_tcp ;;
        2) scan_udp ;;
        3) echo -e "${Cyan}${Bold}Thank you for using Advanced Network Reconnaissance Suite!${NoColor}" && exit 0 ;;
        *) echo -e "${Red}${Bold}Invalid choice!${NoColor}" && sleep 1 ;;
    esac
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${Red}${Bold}Please run as root${NoColor}"
    exit 1
fi

check_dependencies

while true; do
    print_header
    main_menu
done
