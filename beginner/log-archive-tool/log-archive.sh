#!/bin/bash
set -e # Exit immediately if any command fails

if [ -z "$1" ]; then 
    echo " Usage: ./log-archive.sh <log-directory> "
    exit 1
fi

LOG_DIR="$1"

#Check if the directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Directory '$LOG_DIR' does not exist"
    exit 1
fi

# Get current date and time 
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create archive directory if it doesn't exist
ARCHIVE_DIR="archives"
mkdir -p "$ARCHIVE_DIR"

#Define archive file name and path 
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"

# Create archive
tar -czf "$ARCHIVE_PATH" "$LOG_DIR"

#Log archive activity 
LOG_FILE="archive.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Archived '$LOG_DIR' to '$ARCHIVE_PATH'" >> "$LOG_FILE"

#Notify

echo "Log archive created successfully: $ARCHIVE_PATH"

