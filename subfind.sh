#!/bin/bash

# -----------------------------------------------------------
# 🎬 Hollywood Terminal Style Live Subdomain Finder Tool
# Bash Version with Live Output, Progress Bars, Animations & Sounds
# Fully ANSI Color Safe
# -----------------------------------------------------------

# Required tools: assetfinder, subfinder, httprobe, figlet, lolcat, play (sox)

# ---------- COLORS ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ---------- FUNCTIONS ----------
animate_text() {
    local text="$1"
    local delay="${2:-0.02}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
    echo -e "${RESET}"
}

rainbow_banner() {
    local text="$1"
    if command -v lolcat &> /dev/null; then
        echo "$text" | figlet -f slant | lolcat
    else
        echo "$text" | figlet -f slant
    fi
}

spinner() {
    local pid=$1
    local msg="$2"
    local delay=0.1
    local spinstr='|/-\'
    echo -ne "${CYAN}$msg ${RESET}"
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\b${spinstr:$i:1}"
            sleep $delay
        done
    done
    echo -e "\b✔ Done!"
}

live_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local bar_length=40
    local filled=$((percent * bar_length / 100))
    local empty=$((bar_length - filled))
    local bar=$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')
    echo -ne "\r[${bar}] ${percent}%"
}

play_sound() {
    if command -v play &> /dev/null; then
        play -n synth 0.05 sin 880 vol 0.3 2>/dev/null
    fi
}

# ---------- START SCREEN ----------
clear
rainbow_banner "LIVE SUBDOMAIN FINDER"
echo -e "${CYAN}🎬 Initializing Hollywood Terminal Mode...${RESET}"
play_sound
sleep 1

# ---------- INPUT DOMAIN ----------
echo -e "${YELLOW}Enter Target Domain:${RESET}"
read DOMAIN

OUTPUT_DIR="./output"
SUBDOMAINS_FILE="$OUTPUT_DIR/${DOMAIN}_subdomains.txt"
ACTIVE_SUBDOMAINS_FILE="$OUTPUT_DIR/${DOMAIN}_active_subdomains.txt"
mkdir -p "$OUTPUT_DIR"
> "$SUBDOMAINS_FILE"
> "$ACTIVE_SUBDOMAINS_FILE"

# ---------- SCANNING ----------
clear
rainbow_banner "SCANNING..."
echo -e "${CYAN}🚀 Launching Subdomain Enumeration...${RESET}"
play_sound

ALL_SUBDOMAINS=()

# assetfinder
while read sub; do
    echo -e "${BLUE}[Found] $sub${RESET}"
    ALL_SUBDOMAINS+=("$sub")
    play_sound
done < <(assetfinder "$DOMAIN")

# subfinder
while read sub; do
    echo -e "${MAGENTA}[Found] $sub${RESET}"
    ALL_SUBDOMAINS+=("$sub")
    play_sound
done < <(subfinder -d "$DOMAIN" -silent)

# Remove duplicates
ALL_SUBDOMAINS=($(printf "%s\n" "${ALL_SUBDOMAINS[@]}" | sort -u))
TOTAL=${#ALL_SUBDOMAINS[@]}
echo -e "${YELLOW}Total Unique Subdomains: $TOTAL${RESET}"
play_sound

# ---------- ACTIVE SUBDOMAIN CHECK ----------
echo -e "${CYAN}🔍 Checking Active Subdomains...${RESET}"
count=0
for sub in "${ALL_SUBDOMAINS[@]}"; do
    active=$(echo "$sub" | httprobe -prefer-https)
    if [[ -n "$active" ]]; then
        echo -e "${GREEN}[ACTIVE] $active${RESET}"
        echo "$active" >> "$ACTIVE_SUBDOMAINS_FILE"
        play_sound
    fi
    ((count++))
    live_progress "$count" "$TOTAL"
done
echo -e "${RESET}"

# ---------- RESULTS ----------
clear
rainbow_banner "RESULTS"
echo -e "${GREEN}All Active Subdomains:${RESET}"
echo -e "${GREEN}==================================${RESET}"
cat "$ACTIVE_SUBDOMAINS_FILE" | (command -v lolcat &> /dev/null && lolcat || cat)
echo -e "${GREEN}==================================${RESET}"
play_sound

# ---------- END SCREEN ----------
rainbow_banner "SCAN COMPLETED"
echo -e "${MAGENTA}🎉 Hollywood Terminal Scan Complete!${RESET}"
echo -e "${CYAN}Results saved in: $ACTIVE_SUBDOMAINS_FILE${RESET}"
echo -e "${CYAN}Thank you for using Live Subdomain Finder!${RESET}"
play_sound
