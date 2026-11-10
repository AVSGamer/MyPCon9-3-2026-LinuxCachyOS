# WIP
# Created by: Khayeel(https://github.com/AVSGamer)
# Created with Google's Gemini Free Tier LLM
# Not yet finished.
# Supposed to be another implementation of
# the media playing tracker via linux's
# 'playerctl' command. It outputs into a JSON
# file instead of a plaintext(.txt) file.
# Will look into whether JSON is absolutely
# needed or the supposed HTML version of the
# tracker can do it with a plaintext(.txt)
# format instead.

#!/usr/bin/env bash
OUT_JSON="./obs_overlay/current_track.json"
IMAGE_OUT="./obs_overlay/current_cover.jpg"
INTERVAL=1

mkdir -p "$(dirname "$OUT_JSON")"
LAST_TRACK_ID=""

# Helper function to sanitize text strings for safe URL query parameters
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0; pos<strlen; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) printf -v o '%%%02X' "'$c"; encoded+="$o" ;;
        esac
    done
    echo "${encoded}"
}

# Helper function to clean text formatting so it doesn't break JSON files
escape_json() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/$/\\n/' | tr -d '\r\n'
}

while sleep "$INTERVAL"; do
    if playerctl status >/dev/null 2>&1; then
        STATUS=$(playerctl status 2>/dev/null)
        TITLE=$(playerctl metadata -p plasma-browser-integration xesam:title 2>/dev/null)
        ARTIST=$(playerctl metadata -p plasma-browser-integration xesam:artist 2>/dev/null)
        ALBUM=$(playerctl metadata -p plasma-browser-integration xesam:album 2>/dev/null)
        ART_URL=$(playerctl metadata -p plasma-browser-integration mpris:artUrl 2>/dev/null)

        TIME_STR=$(playerctl metadata --format '{{duration(position)}}' 2>/dev/null)
        SL_STR=$(playerctl metadata --format '{{duration(mpris:length)}}' 2>/dev/null)

        INT_TIMESTR=$(playerctl position)
        INT_SLSTR=$(playerctl metadata mpris:length)

        if [[ "${TITLE,,}" == *"facebook"* ]]; then
            echo '{"playing": false}' > "$OUT_JSON"
            rm -f "$IMAGE_OUT"
            LAST_TRACK_ID=""
            continue
        fi

        # Math logic for progress metrics
        CLEAN_MAX=${INT_SLSTR%.*}
        CLEAN_CURRENT=${INT_TIMESTR%.*}
        MAX=$(( CLEAN_MAX / 1000000 ))
        CURRENT=$(( CLEAN_CURRENT ))

        if [ "$MAX" -le 0 ]; then MAX=1; fi
        if [ "$CURRENT" -gt "$MAX" ]; then CURRENT=$MAX; fi
        PERCENTAGE=$(( (CURRENT * 100) / MAX ))

        if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
            TRACK_ID="$ARTIST - $TITLE"

            # --- TRACK CHANGE TRIGGER: Fetch fresh lyrics only once per song ---
            if [[ "$TRACK_ID" != "$LAST_TRACK_ID" && -n "$TITLE" ]]; then
                LAST_TRACK_ID="$TRACK_ID"

                # Encode text queries safely
                ENC_ARTIST=$(urlencode "$ARTIST")
                ENC_TITLE=$(urlencode "$TITLE")

                # Fetch lyrics data from the open-source LRCLIB repository
                API_RESPONSE=$(curl -s -G \
                    --data-urlencode "artist=$ARTIST" \
                    --data-urlencode "track_name=$TITLE" \
                    "https://lrclib.net")

                # Extract components using standard string selectors to keep things lightweight
                PLAIN_LYRICS=$(echo "$API_RESPONSE" | grep -o '"plainLyrics":"[^"]*"' | sed 's/"plainLyrics":"//;s/"$//')
                SYNCED_LYRICS=$(echo "$API_RESPONSE" | grep -o '"syncedLyrics":"[^"]*"' | sed 's/"syncedLyrics":"//;s/"$//')

                # Fallback text if the track is instrumental or missing from the library
                if [[ -z "$PLAIN_LYRICS" || "$PLAIN_LYRICS" == "null" ]]; then
                    PLAIN_LYRICS="[Lyrics instrumental or not found in LRCLIB]"
                    SYNCED_LYRICS=""
                fi

                # Format text content for safe deployment inside our local JSON state
                JSON_PLAIN=$(escape_json "$PLAIN_LYRICS")
                JSON_SYNCED=$(escape_json "$SYNCED_LYRICS")
            fi

            SAFE_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
            SAFE_ARTIST=$(echo "$ARTIST" | sed 's/"/\\"/g')
            SAFE_ALBUM=$(echo "$ALBUM" | sed 's/"/\\"/g')

            # Write data cleanly to our background tracking portal
            cat <<EOF > "$OUT_JSON"
{
  "playing": true,
  "title": "${SAFE_TITLE:-Unknown Title}",
  "artist": "${SAFE_ARTIST:-Unknown Artist}",
  "album": "${SAFE_ALBUM:-Unknown Album}",
  "time": "${TIME_STR:-0:00}",
  "duration": "${SL_STR:-0:00}",
  "progress": ${PERCENTAGE:-0},
  "plainLyrics": "$JSON_PLAIN",
  "syncedLyrics": "$JSON_SYNCED"
}
EOF

            # Export track artwork files locally
            if [[ -n "$ART_URL" && "$ART_URL" != "$LAST_ART" ]]; then
                LAST_ART="$ART_URL"
                [[ "$ART_URL" == file://* ]] && cp "${ART_URL#file://}" "$IMAGE_OUT" 2>/dev/null
                [[ "$ART_URL" == http* ]] && curl -s "$ART_URL" -o "$IMAGE_OUT"
            fi
        else
            echo '{"playing": false}' > "$OUT_JSON"
            rm -f "$IMAGE_OUT"
            LAST_TRACK_ID=""
        fi
    else
        echo '{"playing": false}' > "$OUT_JSON"
        rm -f "$IMAGE_OUT"
        LAST_TRACK_ID=""
    fi
done
