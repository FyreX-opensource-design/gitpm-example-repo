#!/usr/bin/env bash

show_usage() {
    echo "Usage: $0 <URL> [OPTIONS]"
    echo
    echo "Required:"
    echo "  <URL>                      The target URL for the app."
    echo
    echo "Options:"
    echo "  -n, --name NAME            The name of the application."
    echo "  -i, --icon ICON            Path to icon file."
    echo "  -d, --description DESC     App description."
    echo "  --internal-urls REGEX      Internal URLs to allow (use regex string)."
    echo "  --css CSS                  Path to custom CSS to inject."
    echo "  --block-external-links     Block external links."
    echo "  --single-instance          Single instance mode."
    echo "  --tray                     Enable tray icon."
    echo "  --user                     Install for user (otherwise system install)."
    echo "  -h, --help                 Show this help message."
    echo
    echo "Example:"
    echo "  $0 https://web.site -n AppName -i /path/to/icon.png -d 'My App Description' --internal-urls '^https://web.site' --css /path/to/style.css --block-external-links --single-instance --tray"
    echo
    echo "Minimal:"
    echo "  $0 https://web.site -n AppName -i /path/to/icon.png -d 'My App Description'"
}

# Default values
NAME=""
ICON=""
DESCRIPTION=""
URL_INTERNAL=""
CSS_INJECT=""
BLOCK_EXTERNAL_LINKS=""
SINGLE_INSTANCE=""
TRAY=""
SYSTEM="system"  # Default to system, but --user flag sets to user

# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
        show_usage
        exit 0
        ;;
        -n|--name)
        NAME="$2"
        shift; shift
        ;;
        -i|--icon)
        ICON="$2"
        shift; shift
        ;;
        -d|--description)
        DESCRIPTION="$2"
        shift; shift
        ;;
        --internal-urls)
        URL_INTERNAL="$2"
        shift; shift
        ;;
        --css)
        CSS_INJECT="$2"
        shift; shift
        ;;
        --block-external-links)
        BLOCK_EXTERNAL_LINKS="1"
        shift
        ;;
        --single-instance)
        SINGLE_INSTANCE="1"
        shift
        ;;
        --tray)
        TRAY="1"
        shift
        ;;
        --user)
        SYSTEM="user"
        shift
        ;;
        *)    # positional args
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

set -- "${POSITIONAL[@]}"

URL="$1"

if [ -z "$URL" ]; then
    echo "Error: URL must be provided."
    show_usage
    exit 1
fi

if [ -z "$NAME" ] || [ -z "$ICON" ] || [ -z "$DESCRIPTION" ]; then
    echo "Error: --name, --icon, and --description must all be provided."
    show_usage
    exit 1
fi

# Build flag arrays
NATIVEFIER_ARGS=()

if [ -n "$URL_INTERNAL" ]; then
    NATIVEFIER_ARGS+=("--internal-urls" "$URL_INTERNAL")
fi

if [ -n "$BLOCK_EXTERNAL_LINKS" ]; then
    NATIVEFIER_ARGS+=("--block-external-links")
fi

if [ -n "$ICON" ]; then
    NATIVEFIER_ARGS+=("--icon" "$ICON")
fi

if [ -n "$CSS_INJECT" ]; then
    NATIVEFIER_ARGS+=("--inject" "$CSS_INJECT")
fi

if [ -n "$SINGLE_INSTANCE" ]; then
    NATIVEFIER_ARGS+=("--single-instance")
fi

if [ -n "$TRAY" ]; then
    NATIVEFIER_ARGS+=("--tray")
fi

if [ "$SYSTEM" = "system" ]; then
    SYSTEM_FLAG="--system"
    PWA_DIR="/opt/PWA"
    DLI_E="/opt/PWA/$NAME-linux-x64/$NAME"
else
    SYSTEM_FLAG=""
    PWA_DIR="$HOME/.local/share/PWA"
    DLI_E="$HOME/.local/share/PWA/$NAME-linux-x64/$NAME"
fi

CURRENT_DIR=$(pwd)

# Run nativefier
cd /opt/apps/nativefier
npx nativefier --disable-context-menu --disable-dev-tools --ignore-certificate -n "$NAME" -u firefox "${NATIVEFIER_ARGS[@]}" "$URL"
mkdir -p "$PWA_DIR"
mv /opt/apps/nativefier/$NAME-linux-x64 "$PWA_DIR/$NAME-linux-x64"

# Run depender
DEPENDER_ARGS=(-n "$NAME" -e "$DLI_E" -c "$DESCRIPTION" -i "$ICON")
if [ -n "$SYSTEM_FLAG" ]; then
    DEPENDER_ARGS+=("$SYSTEM_FLAG")
fi
depender create app "${DEPENDER_ARGS[@]}"

cd "$CURRENT_DIR"
