#!/bin/bash

set -eo pipefail

INSTALL_VERSION="1.11.2"

usage() {
    echo "Usage: bash install-go.sh [ --version <go_version> | --help ]"
}

# Parse
#   bash install-go.sh --help
# or
#   bash install-go.sh --version <go_version>

if [ -n "${1-}" ]; then
    if [ "${1-}" == "--help" ]; then
        usage
        exit 0
    elif [ "${1-}" == "--version" ]; then
        if [ -z "$2" ]; then
            usage
            exit 1
        fi
        INSTALL_VERSION="${2-}"
    fi
fi

# Make sure we haven't already installed Go
if [ -d "$HOME/go" ] || [ -d "$HOME/gocode" ]; then
    echo "~/go or ~/gocode already exists; exiting"
    exit 1
fi


filename=""

arch="$(uname -m)"
kernel="$(uname -s)"
sourced_env_vars_file=".bashrc"

if [ "${kernel}" == "Linux" ]; then
    case "${arch}" in
        "x86")
            filename="go${INSTALL_VERSION}.linux-386.tar.gz"
            ;;
        "x86_64")
            filename="go${INSTALL_VERSION}.linux-amd64.tar.gz"
            ;;
        "armv6l" | "armv7l")  # No armv7l version exists; use armv6l
            filename="go${INSTALL_VERSION}.linux-armv6l.tar.gz"
            ;;
        "armv8l")
            filename="go${INSTALL_VERSION}.linux-arm64.tar.gz"
            ;;
        "*")
            echo "Architecture ${arch} not recognized; exiting"
            exit 1
    esac
else  # Assume macOS
    sourced_env_vars_file=".profile"
    case "${arch}" in
        "x86")
            filename="go${INSTALL_VERSION}.darwin-386.tar.gz"
            ;;
        "x86_64")
            filename="go${INSTALL_VERSION}.darwin-amd64.tar.gz"
            ;;
        "*")
            echo "Architecture ${arch} not recognized; exiting"
            exit 1
    esac
fi

dest="/tmp/$filename"

echo "Downloading $filename ..."
wget https://dl.google.com/go/$filename -O $dest

if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

echo "Extracting $filename ..."
tar -C "$HOME" -xzf $dest

echo '
export GOROOT=$HOME/go
export PATH=$PATH:$GOROOT/bin
export GOPATH=$HOME/gocode
export PATH=$PATH:$GOPATH/bin' >> "$HOME/${sourced_env_vars_file}"

# Only print this if this script is being run interactively
if [ -n "$PS1" ]; then
    echo 'Success! Now open a new terminal or type

    source ~/'${sourced_env_vars_file}'

then run this to make sure it worked:

    go version
'
fi

# Clean up
rm "$dest"
