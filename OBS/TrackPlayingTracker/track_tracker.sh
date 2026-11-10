# Created/Modified by Khayeel(https://github.com/AVSGamer)
# Concept/Modifications by: Khayeel
# 'playerctl' command: provided by linux system.
# AI LLM tool used: Google's Gemini Free Tier LLM
# This script autoruns with system startup as a
# bridger between the system's
# 'currently playing media(Audio/Video) tracker'
# and OBS' text type source for creating overlays
# on video streaming. It's currently in the format
# I prefer it to be until I decide to change it or
# have need to do so.
#!/usr/bin/env bash
OUT="$HOME/current_track.txt"
INTERVAL=1

# --- SCROLL CONFIGURATION ---
MAX_CHARS=12       # Maximum visible characters before scrolling starts
PADDING="  <end|start>  "  # Separator between loops when text scrolls
# ----------------------------

# Global integer tracking variables to bypass subshell scoping bugs
OFF_ARTIST=0
OFF_TITLE=0
OFF_ALBUM=0

while sleep "$INTERVAL"; do
    if playerctl status >/dev/null 2>&1; then
        STATUS=$(playerctl status 2>/dev/null)
        TITLE=$(playerctl metadata -p plasma-browser-integration xesam:title 2>/dev/null)
        ARTIST=$(playerctl metadata -p plasma-browser-integration xesam:artist 2>/dev/null)
        ALBUM=$(playerctl metadata -p plasma-browser-integration xesam:album 2>/dev/null)
        URL=$(playerctl metadata -p plasma-browser-integration xesam:url 2>/dev/null)

        # CLEAN SPACES NATIVELY (Removes leading/trailing whitespace without xargs)
        TITLE="${TITLE##[[:space:]]}" ; TITLE="${TITLE%%[[:space:]]}"
        ARTIST="${ARTIST##[[:space:]]}" ; ARTIST="${ARTIST%%[[:space:]]}"
        ALBUM="${ALBUM##[[:space:]]}" ; ALBUM="${ALBUM%%[[:space:]]}"


        if [[ "$URL" == *"www.youtube.com"* ]]; then
            ALBUM="YouTube Video"
        fi

        # position follows actively playing regardless of active tab
        # length strictly follows last active tab
        # using the plasma-browser-integration unifies and simplifies detection
        TIME_STR=$(playerctl metadata --format '{{duration(position)}}' 2>/dev/null)
        SL_STR=$(playerctl metadata --format '{{duration(mpris:length)}}' 2>/dev/null)

        INT_TIMESTR=$(playerctl position)
        INT_SLSTR=$(playerctl metadata mpris:length)

        if [[ "${TITLE,,}" == *"facebook"* ]]; then
            > "$OUT" ; LAST_TRACK_ID="" ;
            continue
        fi

        # TRACK ID CHECK: Reset scroll offsets if the song changes
        TRACK_ID="$ARTIST - $TITLE"
        if [[ "$TRACK_ID" != "$LAST_TRACK_ID" ]]; then
            OFF_ARTIST=0
            OFF_TITLE=0
            OFF_ALBUM=0

            if [[ -n "$TITLE" ]]; then
                printf "\n🎵 New Song Logged:\nTitle:  %s\nArtist: %s\nAlbum:  %s\n\n" "$TITLE" "$ARTIST" "$ALBUM"
                LAST_TRACK_ID="$TRACK_ID"
            fi
        fi

        # --- CORRECTED SCROLLING LOGIC ---
        # Fixed indirect reference scoping using safe local assignments instead of unsafe eval strings
        scroll_text() {
            local text="$1"
            local var_name="$2"
            local offset_name="$3"
            local len=${#text}

            if [ "$len" -le "$MAX_CHARS" ]; then
                local formatted
                printf -v formatted "%-${MAX_CHARS}s" "$text"
                printf -v "$var_name" "%s" "$formatted"
            else
                local extended_text="${text}${PADDING}${text}"
                local offset="${!offset_name}"

                local win="${extended_text:$offset:$MAX_CHARS}"
                printf -v "$var_name" "%s" "$win"

                local total_period=$(( len + ${#PADDING} ))
                local next_offset=$(( (offset + 1) % total_period ))
                printf -v "$offset_name" "%s" "$next_offset"
            fi
        }

        # Process metadata safely through the reference scroller
        scroll_text "$ARTIST" "DISP_ARTIST" "OFF_ARTIST"
        scroll_text "$TITLE" "DISP_TITLE" "OFF_TITLE"
        scroll_text "$ALBUM" "DISP_ALBUM" "OFF_ALBUM"

        # Progress bar math
        SAFE_SLSTR=${INT_SLSTR:-1}
        SAFE_TIMESTR=${INT_TIMESTR:-1}
        CLEAN_MAX=${SAFE_SLSTR%.*}
        CLEAN_CURRENT=${SAFE_TIMESTR%.*}

        MAX=$(( CLEAN_MAX / 1000000 ))
        CURRENT=$(( CLEAN_CURRENT ))

        if [ "$MAX" -le 0 ]; then MAX=1; fi
        if [ "$CURRENT" -gt "$MAX" ]; then CURRENT=$MAX; fi

        BAR_LENGTH=7
        SOLID_BLOCK="█"
        LIGHT_SHADE="░"

        FILL_COUNT=$(( (CURRENT * BAR_LENGTH) / MAX ))
        EMPTY_COUNT=$(( BAR_LENGTH - FILL_COUNT ))

        PROGRESS_BLOCKS=""
        i=0
        while [ "$i" -lt "$FILL_COUNT" ]; do
            PROGRESS_BLOCKS="${PROGRESS_BLOCKS}${SOLID_BLOCK}"
            i=$((i + 1))
        done

        BACKGROUND_BLOCKS=""
        i=0
        while [ "$i" -lt "$EMPTY_COUNT" ]; do
            BACKGROUND_BLOCKS="${BACKGROUND_BLOCKS}${LIGHT_SHADE}"
            i=$((i + 1))
        done

        FINAL_BAR="${PROGRESS_BLOCKS}${BACKGROUND_BLOCKS}"

        # Adjusted spacing strings to align with the new fixed window size
        NEW_TEXT=$(printf "%s\n%s\n%s\n%s%s%s\n%s%s%s" "          $DISP_ARTIST" "        $DISP_TITLE" "          $DISP_ALBUM" "$TIME_STR" "   /   " "$SL_STR" "[" "$FINAL_BAR" "]")

        if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
            echo "$NEW_TEXT" > "$OUT"
        else
            > "$OUT" ; LAST_TRACK_ID="" ;
        fi
    else
        > "$OUT" ; LAST_TRACK_ID="" ;
    fi
done
