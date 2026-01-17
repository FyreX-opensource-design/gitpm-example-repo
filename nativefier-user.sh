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

# Build flag variables
URL_INTERNAL_FLAG=""
if [ -n "$URL_INTERNAL" ]; then
    URL_INTERNAL_FLAG="--internal-urls \"$URL_INTERNAL\""
fi

BLOCK_EXTERNAL_LINKS_FLAG=""
if [ -n "$BLOCK_EXTERNAL_LINKS" ]; then
    BLOCK_EXTERNAL_LINKS_FLAG="--block-external-links"
fi

ICON_FLAG=""
if [ -n "$ICON" ]; then
    ICON_FLAG="--icon \"$ICON\""
fi

CSS_INJECT_FLAG=""
if [ -n "$CSS_INJECT" ]; then
    CSS_INJECT_FLAG="--inject \"$CSS_INJECT\""
fi

SINGLE_INSTANCE_FLAG=""
if [ -n "$SINGLE_INSTANCE" ]; then
    SINGLE_INSTANCE_FLAG="--single-instance"
fi

TRAY_FLAG=""
if [ -n "$TRAY" ]; then
    TRAY_FLAG="--tray"
fi

if [ "$SYSTEM" = "system" ]; then
    SYSTEM_FLAG="--system"
    PWA_DIR="/opt/PWA"
    DLI_E="/opt/PWA/$NAME-linux-x64/APP"
else
    SYSTEM_FLAG=""
    PWA_DIR="$HOME/.local/share/PWA"
    DLI_E="$HOME/.local/share/PWA/$NAME-linux-x64/APP"
fi

CURRENT_DIR=$(pwd)

# Run nativefier
cd ~/.local/share/apps/nativefier
npx nativefier --disable-context-menu --disable-dev-tools --ignore-certificate -n "$NAME" -u firefox $CSS_INJECT_FLAG $BLOCK_EXTERNAL_LINKS_FLAG $URL_INTERNAL_FLAG $ICON_FLAG $SINGLE_INSTANCE_FLAG $TRAY_FLAG "$URL"
mkdir -p $PWA_DIR
mv ~/.local/share/apps/nativefier/$NAME-linux-x64 ~/.local/share/PWA/$NAME-linux-x64

# Run depender
depender -n "$NAME" -e "$DLI_E" -c "$DESCRIPTION" -i "$ICON" $SYSTEM_FLAG

cd "$CURRENT_DIR"
