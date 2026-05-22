#!/bin/bash

echo "Starting installation for lyric-tui..."

# 1. Update and install core dependencies
echo "Updating packages and installing dependencies..."
pkg update && pkg install -y yt-dlp mpv jq bc figlet curl && pkg install socat
# 2. Ensure lyrics.sh exists and is executable
if [ -f "lyrics.sh" ]; then
    chmod +x lyrics.sh
    echo "lyrics.sh is now executable."
else
    echo "Error: lyrics.sh not found in current directory."
    exit 1
fi

# 3. Setup aliases (optional, makes it easy to run)
# This lets you type 'lyrics' from anywhere to run your script
SCRIPT_PATH=$(pwd)/lyrics.sh
echo "alias lyrics='$SCRIPT_PATH'" >> $HOME/.bashrc

echo "------------------------------------------------"
echo "Installation complete!"
echo "Please run: source $HOME/.bashrc"
echo "Then you can simply type 'lyrics \"Song Name\"' to start."
echo "------------------------------------------------"
