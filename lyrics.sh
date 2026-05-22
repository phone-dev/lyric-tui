#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ./lyrics.sh \"Artist - Song Name\""
    exit 1
fi

SONG_QUERY="$1"
CLEAN_NAME=$(echo "$SONG_QUERY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')
AUDIO_FILE="$HOME/${CLEAN_NAME}.mp3"
LYRIC_FILE="$HOME/${CLEAN_NAME}.lrc"

clear
echo "Searching and fetching assets for: $SONG_QUERY..."
if [ ! -f "$AUDIO_FILE" ]; then
    echo " -> Downloading audio stream from YouTube..."
    yt-dlp --extract-audio --audio-format mp3 --quiet --no-warnings -o "$AUDIO_FILE" "ytsearch1:${SONG_QUERY}"
fi

if [ ! -f "$LYRIC_FILE" ]; then
    echo " -> Checking synced database..."
    ENCODED_QUERY=$(echo "$SONG_QUERY" | jq -sRr @uri)
    curl -s "https://lrclib.net/api/search?q=${ENCODED_QUERY}" | jq -r '.[0].syncedLyrics // empty' > "$LYRIC_FILE"

    if [ ! -s "$LYRIC_FILE" ] || [ "$(cat "$LYRIC_FILE")" = "null" ]; then
        echo " -> Synced file empty. Generating local track layout matrix..."
        echo "[00:01.00] $SONG_QUERY" > "$LYRIC_FILE"
        echo "[00:10.00] ** Instrumental / Beat Drop **" >> "$LYRIC_FILE"
        if [ "$CLEAN_NAME" = "janina_terranova" ]; then
            echo "[00:30.00] Terranova ... So Far Away" >> "$LYRIC_FILE"
            echo "[00:45.00] Dam Dam Di Di Di Di" >> "$LYRIC_FILE"
            echo "[01:10.00] New Dimension ... No More Pain" >> "$LYRIC_FILE"
        else
            echo "[00:20.00] Enjoy the music!" >> "$LYRIC_FILE"
        fi
    fi
fi

pkill -f mpv 2>/dev/null
sleep 0.5
mpv --no-video --input-ipc-server=$HOME/mpvsocket "$AUDIO_FILE" >/dev/null 2>&1 &
clear

echo "Engine loaded. Initializing visualization..."
sleep 1
LAST_LYRIC=""

while true; do
    RAW_TIME=$(echo '{ "command": ["get_property", "time-pos"] }' | socat - $HOME/mpvsocket 2>/dev/null)
    CURRENT_SEC=$(echo "$RAW_TIME" | jq -r '.data // -1')
    if [ "$CURRENT_SEC" = "-1" ] || [ -z "$CURRENT_SEC" ]; then
        clear
        echo "Playback finished."
        break
    fi
    
    # Built-in check: if it's "She", subtract 21 seconds to hold back the lyrics during the intro
    LYRIC=$(awk -v now="$CURRENT_SEC" -v name="$CLEAN_NAME" '
        BEGIN { 
            best_lyric = ""
            offset = 0
            if (name ~ /she/) { offset = -21.0 }
        }
        {
            if (match($0, /^\[([0-9]+):([0-9.]+)\].*/, arr)) {
                sec = (arr[1] * 60) + arr[2] + offset
                if (sec <= now) {
                    best_lyric = substr($0, index($0, "]") + 1)
                }
            }
        }
        END { print best_lyric }
    ' "$LYRIC_FILE")
    
    LYRIC=$(echo "$LYRIC" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ ! -z "$LYRIC" ] && [ "$LYRIC" != "$LAST_LYRIC" ]; then
        clear
        echo -e "\n\n\n"
        figlet -c -f standard "$LYRIC"
        LAST_LYRIC="$LYRIC"
    fi
    sleep 0.1
done
pkill -f mpv 2>/dev/null
