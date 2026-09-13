#!/usr/bin/env bash
OUT="$HOME/current_track.txt"  IMAGE_OUT="$HOME/current_cover.jpg"  INTERVAL=1

while sleep "$INTERVAL"; do
    if playerctl status >/dev/null 2>&1; then
        # 1. Let playerctl's built-in duration() engine handle the math perfectly
	IFS=$'\t' read -r STATUS TITLE ARTIST TIME_STR SL_STR ART_URL ALBUM <<< "$(playerctl --all-players --ignore-player=plasma-browser-integration metadata --format '{{status}}	{{xesam:title}}	{{xesam:artist}}	{{duration(position)}}	{{duration(mpris:length)}}	{{mpris:artUrl}}	{{xesam:album}}')"

        if [[ "${TITLE,,}" == *"facebook"* ]]; then
            # If true, wipe out the current tracking stats and immediately jump to the next loop cycle
            > "$OUT" ; rm -f "$IMAGE_OUT" ; LAST_TRACK_ID="" ; LAST_ART=""
            continue
        fi

        NEW_TEXT=$(printf "%s\n%s%s%s\n%s%s\n%s%s\n%s%s" "[--------------------------------------------------]" "$TIME_STR" "   /   " "$SL_STR" "Title:    " "$TITLE" "by:       " "$ARTIST" "S.Album:  " "$ALBUM")

        if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
            echo "$NEW_TEXT" > "$OUT"

            # TRACK ID CHECK: Logs to terminal ONLY when actual song metadata changes
            TRACK_ID="$ARTIST - $TITLE"
            if [[ "$TRACK_ID" != "$LAST_TRACK_ID" && -n "$TITLE" ]]; then
                printf "\n🎵 New Song Logged:\nTitle:  %s\nArtist: %s\nAlbum:  %s\n\n" "$TITLE" "$ARTIST" "$ALBUM"
                LAST_TRACK_ID="$TRACK_ID"
            fi

            # 2. Shrunk Artwork routine
            if [[ -n "$ART_URL" && "$ART_URL" != "$LAST_ART" ]]; then
                LAST_ART="$ART_URL"
                [[ "$ART_URL" == file://* ]] && cp "${ART_URL#file://}" "$IMAGE_OUT" 2>/dev/null
                [[ "$ART_URL" == http* ]] && curl -s "$ART_URL" -o "$IMAGE_OUT"
            fi
        else
            > "$OUT" ; rm -f "$IMAGE_OUT" ; LAST_TRACK_ID="" ; LAST_ART=""
        fi
    else
        > "$OUT" ; rm -f "$IMAGE_OUT" ; LAST_TRACK_ID="" ; LAST_ART=""
    fi
done
