#!/usr/bin/env bash

# proccessctl.sh - Wrapper for running a command under systemd-run
# Usage: ./proccessctl.sh [-c COMMAND] [-m MEMORY_HIGH] [-M MEMORY_MAX] [-C CPU_LIMIT] [-s SLICE]
# Example: ./proccessctl.sh -c firefox -m 1G -M 2G -C 20% -s user-100.slice

MEMORY_SOFT_LIMIT=""
MEMORY_LIMIT=""
CPU_LIMIT=""
COMMAND=""
SLICE=""

show_usage() {
    echo "Usage: $0 [-c COMMAND] [-m MEMORY_HIGH] [-M MEMORY_MAX] [-C CPU_LIMIT] [-s SLICE]"
    echo "  -c COMMAND       Command to run (required)"
    echo "  -m MEMORY_HIGH   Soft memory limit (e.g., 1G, optional)"
    echo "  -M MEMORY_MAX    Hard memory limit (e.g., 2G, optional)"
    echo "  -C CPU_LIMIT     CPU quota/limit (e.g., 20%, optional)"
    echo "  -s SLICE         systemd slice (optional; disables resource flag usage and puts into slice)"
}

while getopts "c:m:M:C:s:h" opt; do
    case "$opt" in
        c) COMMAND="$OPTARG" ;;
        m) MEMORY_SOFT_LIMIT="$OPTARG" ;;
        M) MEMORY_LIMIT="$OPTARG" ;;
        C) CPU_LIMIT="$OPTARG" ;;
        s) SLICE="$OPTARG" ;;
        h) show_usage; exit 0 ;;
        *)
           show_usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

if [ -z "$COMMAND" ]; then
    echo "Error: Command to run (-c) must be specified."
    show_usage
    exit 1
fi

if [ -n "$SLICE" ]; then
    # Use slice, don't set extra -p flags
    systemd-run --user --slice="$SLICE" $COMMAND
else
    ARGS=()
    [ -n "$MEMORY_SOFT_LIMIT" ] && ARGS+=("-p" "MemoryHigh=$MEMORY_SOFT_LIMIT")
    [ -n "$MEMORY_LIMIT" ] && ARGS+=("-p" "MemoryMax=$MEMORY_LIMIT")
    [ -n "$CPU_LIMIT" ] && ARGS+=("-p" "CPUQuota=$CPU_LIMIT")
    systemd-run --scope "${ARGS[@]}" --user $COMMAND
fi