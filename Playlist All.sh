#!/usr/bin/env bash

# Nautilus script: generates M3U playlist from media files in current directory

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

exec 2>> /tmp/nautilus_playlist_debug.log
set -x

# Config
TIMEOUT=10000
TYPES=("wav" "wv" "flac" "ogg" "mp3" "mp4" "avi" "mkv" "m4a" "opus")

# i18n messages
MSG_SUCC_SUMM="File Generated"
MSG_SUCC_BODY="Playlist created successfully."
MSG_FAIL_SUMM="Error"
MSG_FAIL_BODY="No media files found."
MSG_OPEN="Open File"
MSG_DEL="Delete File"

# URL decode function
urldecode() {
	printf '%b' "${1//%/\\x}"
}

# Get directory from Nautilus
DIRPATH="${NAUTILUS_SCRIPT_CURRENT_URI:-}"
if [ -z "$DIRPATH" ]; then
	DIRPATH=$(dirname "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS%%$'\n'*}")
fi

# Decode URI
DIRPATH="${DIRPATH#file://}"
DIRPATH=$(urldecode "$DIRPATH")

DIRNAME="${DIRPATH##*/}"
PLAYLIST="${DIRPATH}/${DIRNAME}-Full.m3u"

# Generate playlist
echo "#EXTM3U" > "$PLAYLIST"
COUNT=0

# Build find command with properly quoted patterns (recursive, no symlink loops)
FIND_CMD="find -L \"$DIRPATH\" -type f \\("
for i in "${!TYPES[@]}"; do
	[ $i -gt 0 ] && FIND_CMD+=" -o"
	FIND_CMD+=" -iname \"*.${TYPES[i]}\""
done
FIND_CMD+=" \\) | sort"

while IFS= read -r file; do
	echo "${file#$DIRPATH/}" >> "$PLAYLIST"
	((COUNT++))
done < <(eval "$FIND_CMD")

# Notify result
if [ $COUNT -gt 0 ]; then
	ACTION=$(notify-send "$MSG_SUCC_SUMM" "$MSG_SUCC_BODY" \
		-A "open=$MSG_OPEN" \
		-A "del=$MSG_DEL" \
		--wait -t $TIMEOUT)
	
	case "$ACTION" in
		open) xdg-open "$PLAYLIST" ;;
		del) rm -f "$PLAYLIST" ;;
	esac
else
	notify-send "$MSG_FAIL_SUMM" "$MSG_FAIL_BODY"
	rm -f "$PLAYLIST"
fi