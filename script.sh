#!/bin/bash
# FiveM Installation Script
# Server Files Path: /mnt/server

set -e  # Exit on any error

# Ensure system is up-to-date and install necessary packages
echo "Updating system and installing required packages..."
apt update -y && apt install -y tar xz-utils file jq curl unzip

# Define directories
SERVER_DIR="/mnt/server"
RESOURCES_DIR="$SERVER_DIR/resources"

# Create required directories
echo "Creating directories..."
mkdir -p "$RESOURCES_DIR"

cd "$SERVER_DIR"

# Update citizenfx resource files
echo "Updating CitizenFX resource files..."
TEMP_DIR=$(mktemp -d)
git clone https://github.com/citizenfx/cfx-server-data.git "$TEMP_DIR"
cp -Rf "$TEMP_DIR/resources/"* "$RESOURCES_DIR/"
rm -rf "$TEMP_DIR"

# Fetch release information
echo "Fetching release information..."
RELEASE_PAGE=$(curl -sSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

# Determine download link based on the version
echo "Determining download link..."
if [[ "${FIVEM_VERSION}" == "recommended" ]] || [[ -z ${FIVEM_VERSION} ]]; then
  DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
elif [[ "${FIVEM_VERSION}" == "latest" ]]; then
  DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.latest_download')
else
  VERSION_LINK=$(echo "$RELEASE_PAGE" | grep -Eo '".*/*.tar.xz"' | grep -io "${FIVEM_VERSION}" | head -n 1)
  if [[ -z "${VERSION_LINK}" ]]; then
    echo "Invalid version requested. Defaulting to 'recommended'."
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
  else
    DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$VERSION_LINK"
  fi
fi

# Validate custom download URL if provided
if [[ ! -z "${DOWNLOAD_URL}" ]]; then
  echo "Validating custom download URL..."
  if curl --output /dev/null --silent --head --fail "$DOWNLOAD_URL"; then
    echo "Custom download URL is valid. Using $DOWNLOAD_URL."
    DOWNLOAD_LINK="$DOWNLOAD_URL"
  else
    echo "Custom download URL is invalid. Exiting."
    exit 2
  fi
fi

echo "Downloading FiveM server files from $DOWNLOAD_LINK..."
curl -sSL "$DOWNLOAD_LINK" -o "fx.tar.xz"

# Extract the downloaded file
echo "Extracting FiveM server files..."
FILETYPE=$(file -b "fx.tar.xz" | cut -d' ' -f1)
case "$FILETYPE" in
  gzip) tar xzvf fx.tar.xz ;;
  Zip) unzip fx.tar.xz ;;
  XZ) tar xvf fx.tar.xz ;;
  *)
    echo "Unknown filetype. Exiting."
    exit 2
    ;;
esac

# Clean up
rm -rf fx.tar.xz run.sh

# Ensure server.cfg exists
if [[ -e "$SERVER_DIR/server.cfg" ]]; then
  echo "server.cfg already exists. Skipping download."
else
  echo "Downloading default server.cfg..."
  curl -sSL https://raw.githubusercontent.com/zippy01/custom-fivem/main/server.cfg -o server.cfg
fi

# Add Imperial Logo
mkdir -p /home/container
curl -o /home/container/mylogo.png https://raw.githubusercontent.com/Zippy01/custom-fivem/main/mylogo.png

# Create logs directory if not exists
mkdir -p "$SERVER_DIR/logs/"

echo "Your Imperial Hosting server is almost ready!!"
