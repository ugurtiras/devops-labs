#!/bin/bash

# ============================================
# Linux System Monitor Script
# ============================================
# A comprehensive system monitoring tool that tracks
# CPU, Memory, and Disk usage with threshold alerts
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration ---
# Define threshold values and settings
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90

LOG_FILE="$HOME/.system_monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- Helper Functions ---
log_message() {
    local level=$1
    local message=$2
    echo "[$TIMESTAMP] [$level] $message" >> "$LOG_FILE"
}

check_threshold() {
    local name=$1
    local value=$2
    local threshold=$3
    
    if [ "$value" -ge "$threshold" ]; then
        echo -e "${RED}WARNING: $name usage ($value%) exceeds threshold ($threshold%)${NC}"
        log_message "WARNING" "$name usage ($value%) exceeds threshold ($threshold%)"
        return 1
    else
        echo -e "${GREEN}OK: $name usage ($value%) is normal${NC}"
        log_message "INFO" "$name usage ($value%) is within normal range"
        return 0
    fi
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}       Linux System Monitor${NC}"
    echo -e "${BLUE}       $TIMESTAMP${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
}

print_section() {
    echo -e "${YELLOW}--- $1 ---${NC}"
}

# --- Main Script ---
print_header

# --- CPU Usage Check ---
# Get current CPU usage percentage and compare with threshold
print_section "CPU Usage"

read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
TOTAL1=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE1=$idle

sleep 1

read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
TOTAL2=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE2=$idle

TOTAL_DIFF=$((TOTAL2 - TOTAL1))
IDLE_DIFF=$((IDLE2 - IDLE1))

if [ "$TOTAL_DIFF" -gt 0 ]; then
    CPU_USAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
else
    CPU_USAGE=0
fi

echo "CPU Usage: $CPU_USAGE%"
check_threshold "CPU" "$CPU_USAGE" "$CPU_THRESHOLD"
echo

# --- Memory Usage Check ---
# Get current memory usage and compare with threshold
print_section "Memory Usage"

MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
MEM_USAGE=$((100 * MEM_USED / MEM_TOTAL))

# Convert to human readable format (MB)
MEM_TOTAL_MB=$((MEM_TOTAL / 1024))
MEM_USED_MB=$((MEM_USED / 1024))
MEM_AVAILABLE_MB=$((MEM_AVAILABLE / 1024))

echo "Memory Usage: $MEM_USAGE%"
echo "  Total:     ${MEM_TOTAL_MB} MB"
echo "  Used:      ${MEM_USED_MB} MB"
echo "  Available: ${MEM_AVAILABLE_MB} MB"
check_threshold "Memory" "$MEM_USAGE" "$MEMORY_THRESHOLD"
echo

# --- Disk Space Check ---
# Check disk usage for specified partitions
print_section "Disk Usage"

echo "Filesystem      Size  Used  Avail Use%  Mounted on"
df -h --output=source,size,used,avail,pcent,target | grep -E '^/dev/' | while read line; do
    echo "$line"
done
echo

DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%",""); print $5}')
echo "Root Partition Usage: $DISK_USAGE%"
check_threshold "Disk" "$DISK_USAGE" "$DISK_THRESHOLD"
echo

# --- Top Processes ---
# List top resource-consuming processes (CPU and Memory)
print_section "Top Processes"

echo -e "${YELLOW}Top 5 CPU-consuming processes:${NC}"
printf "%-8s %-20s %-8s %-8s\n" "PID" "COMMAND" "CPU%" "MEM%"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | while read pid comm cpu mem; do
    printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$cpu" "$mem"
done

echo
echo -e "${YELLOW}Top 5 Memory-consuming processes:${NC}"
printf "%-8s %-20s %-8s %-8s\n" "PID" "COMMAND" "MEM%" "CPU%"
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 6 | tail -n 5 | while read pid comm mem cpu; do
    printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$mem" "$cpu"
done
echo

# --- System Information ---
print_section "System Information"

HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

echo "Hostname:     $HOSTNAME"
echo "Kernel:       $KERNEL"
echo "Uptime:       $UPTIME"
echo "Load Average: $LOAD_AVG (1min, 5min, 15min)"
echo

# --- Log to File ---
# Write monitoring results to log file with timestamp
log_message "INFO" "System Monitor completed - CPU: ${CPU_USAGE}%, Memory: ${MEM_USAGE}%, Disk: ${DISK_USAGE}%"

echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}Monitoring complete. Log saved to: $LOG_FILE${NC}"
echo -e "${BLUE}============================================${NC}"
