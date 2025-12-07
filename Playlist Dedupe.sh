#!/usr/bin/env bash

# SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Nautilus script: deduplicate playlist by filename (keep last occurrence)

exec 2>> /tmp/nautilus_dedupe_debug.log
set -x

# Config
TIMEOUT=10000
MSG_SUCC_SUMM="Playlist Deduplicated"
MSG_SUCC_BODY="Duplicate entries removed."
MSG_FAIL_SUMM="Error"
MSG_FAIL_BODY="No playlist file selected or invalid format."
MSG_OPEN="Open File"
MSG_DEL="Delete File"

# URL decode function
urldecode() {
	printf '%b' "${1//%/\\x}"
}

# Get selected file from Nautilus
FILEPATH="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS%%$'\n'*}"
if [ -z "$FILEPATH" ]; then
	notify-send "$MSG_FAIL_SUMM" "No file selected."
	exit 1
fi

FILEPATH=$(urldecode "$FILEPATH")

# Check if .m3u file
if [[ ! "$FILEPATH" =~ \.m3u$ ]]; then
	notify-send "$MSG_FAIL_SUMM" "Selected file is not .m3u playlist."
	exit 1
fi

# Generate output filename
DIRPATH=$(dirname "$FILEPATH")
FILENAME=$(basename "$FILEPATH" .m3u)
OUTPUT="${DIRPATH}/${FILENAME}-uniq.m3u"

# Deduplicate: keep last occurrence of each filename
declare -A seen
lines=()

# Read entire file
while IFS= read -r line; do
	lines+=("$line")
done < "$FILEPATH"

# Process in reverse, track seen filenames
result=()
for ((i=${#lines[@]}-1; i>=0; i--)); do
	line="${lines[i]}"
	
	# Skip empty lines and #EXTM3U header (will re-add later)
	[[ -z "$line" || "$line" == "#EXTM3U" ]] && continue
	
	# Keep metadata lines (#EXTINF, etc)
	if [[ "$line" == \#* ]]; then
		result=("$line" "${result[@]}")
		continue
	fi
	
	# Extract filename from path, remove track numbers for deduplication
	filename=$(basename "$line")
	# Remove leading patterns: "01 - ", "01. ", "01 ", "1 - ", etc.
	normalized=$(echo "$filename" | sed -E 's/^[0-9]+[. -]+//')
	
	# Keep only first occurrence (from end)
	if [[ -z "${seen[$normalized]}" ]]; then
		seen[$normalized]=1
		result=("$line" "${result[@]}")
	fi
done

# Write output
echo "#EXTM3U" > "$OUTPUT"
printf '%s\n' "${result[@]}" >> "$OUTPUT"

COUNT=${#seen[@]}

# Notify result
if [ $COUNT -gt 0 ]; then
	ACTION=$(notify-send "$MSG_SUCC_SUMM" "$MSG_SUCC_BODY" \
		-A "open=$MSG_OPEN" \
		-A "del=$MSG_DEL" \
		--wait -t $TIMEOUT)
	
	case "$ACTION" in
		open) xdg-open "$OUTPUT" ;;
		del) rm -f "$OUTPUT" ;;
	esac
else
	notify-send "$MSG_FAIL_SUMM" "No entries found."
	rm -f "$OUTPUT"
fi