#!/usr/bin/env bash

# Paths to save outputs
TEXT_OUT="$HOME/current_track.txt"
TEXT_TMP="$HOME/tmp_track.txt"
IMAGE_OUT="$HOME/current_cover.jpg"

# Interval in seconds to poll MPRIS data
INTERVAL=2

echo "Starting track tracker... Outputs will save to:"
echo "Txt: $TEXT_OUT"
echo "Img: $IMAGE_OUT"
echo "TxtTmp: $TEXT_TMP"

while true; do
    # Check if any playerctl-compatible player is active/playing
    if playerctl status >/dev/null 2>&1; then
        # Get metadata status and immediately strip any trailing newlines/spaces
        STATUS=$(playerctl status)
        TITLE=$(playerctl metadata xesam:title | sed 's/ | YouTube Music$//')
        ARTIST=$(playerctl metadata xesam:artist | sed 's/ | YouTube Music$//')
        ALBUM=$(playerctl metadata xesam:album | sed 's/ | YouTube Music$//')
        ART_URL=$(playerctl metadata mpris:artUrl)

        # 1. Build output string using literal newline concatenation
        if [ "$STATUS" = "Playing" ]; then
	    rm -f "$TEXT_TMP"
            printf "$TITLE\n$ARTIST\n$ALBUM" >> $TEXT_TMP
        else
            rm -f "$TEXT_TMP"
            printf "None Playing" >> $TEXT_TMP
        fi

        if [ ! -f "$TEXT_OUT" ] || ! cmp -s "$TEXT_OUT" "$TEXT_TMP"; then
            cp $TEXT_TMP $TEXT_OUT
            printf "Updated Track:\n$TITLE\n$ARTIST\n$ALBUM"
        fi

        # 2. Update image cover file if the art URL changed
        if [ -n "$ART_URL" ] && [ "$ART_URL" != "$LAST_ART_URL" ]; then
            LAST_ART_URL="$ART_URL"
            
            # MPRIS cover URLs can be local files (file://) or online links (http:// or https://)
            if [[ "$ART_URL" == file://* ]]; then
                # Strip 'file://' prefix to get the raw local path
                LOCAL_PATH="${ART_URL#file://}"
                cp "$LOCAL_PATH" "$IMAGE_OUT" 2>/dev/null && echo "Updated local cover art."
            elif [[ "$ART_URL" == http* ]]; then
                # Download online URLs (like Spotify web art)
                curl -s "$ART_URL" -o "$IMAGE_OUT" && echo "Downloaded online cover art."
            fi
        fi
    else
        # No player running
        # Write "No Media Playing" to a temp file to compare safely
        rm -f "$TEXT_TMP"
        printf "No Media Playing" >> $TEXT_TMP
        if [ ! -f "$TEXT_OUT" ] || ! cmp -s "$TEXT_OUT" "$TEXT_TMP"; then
            cp $TEXT_TMP $TEXT_OUT
            rm -f "$IMAGE_OUT" 
            LAST_ART_URL=""
        fi
    fi
    sleep "$INTERVAL"
done
