#!/bin/bash

echo "Starting installation for lyric-tui..."
echo "we will use sudo please enter your password"
sudo pacman -S yt-dlp mpv jq bc figlet curl &&  sudo pacman  -S  socat 

#and if your using pacman in termux

pacman -S yt-dlp mpv jq bc figlet curl &&  pacman -S  socat
