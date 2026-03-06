#!/usr/bin/env bash

# Nautilus: PDF Compress

set -euo pipefail

decode_uri() {
	local input="$1"
	while [[ "$input" =~ %([0-9A-Fa-f]{2}) ]]; do
		input="${input//${BASH_REMATCH[0]}/$(printf "\\x${BASH_REMATCH[1]}")}" 
	done
	echo "$input"
}

main() {
	local timeout='10000'
	local uri=""
	local input_file=""

	if [ -n "${NAUTILUS_SCRIPT_SELECTED_URIS:-}" ]; then
		uri=$(echo "$NAUTILUS_SCRIPT_SELECTED_URIS" | head -n1)
	elif [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
		uri="$NAUTILUS_SCRIPT_CURRENT_URI"
	fi

	if [ -n "$uri" ]; then
		input_file="${uri#file://}"
		input_file="$(decode_uri "$input_file")"
	fi

	if ! declare -F "pdf.cmp" >/dev/null 2>&1; then
		notify-send "Missing dependency" 'try installing `tsilvs/bash_utils`'
		return 1
	fi

	if [ -z "$input_file" ]; then
		notify-send "No file selected" "Select a PDF to compress."
		return 1
	fi

	if [ ! -f "$input_file" ]; then
		notify-send "File not found" "Could not access: ${input_file##*/}"
		return 1
	fi

	local ext="${input_file##*.}"
	ext="${ext,,}"
	if [ "$ext" != "pdf" ]; then
		notify-send "Invalid file type" "File must be PDF."
		return 1
	fi

	local new_file="${input_file%.pdf}.cmp.pdf"
	local wip_summ="Compressing PDF"
	local wip_body="Processing: ${input_file##*/}"
	local success_summ="Compression complete"
	local success_body="Saved: ${new_file##*/}"
	local fail_summ="Compression failed"
	local fail_body="Failed to compress PDF."

	notify-send "$wip_summ" "$wip_body" -t "$timeout" >/dev/null 2>&1 || true

	local error_msg=""
	if ! error_msg="$(pdf.cmp "$input_file" 2>&1)"; then
		notify-send "$fail_summ" "${error_msg:-$fail_body}"
		return 1
	fi

	notify-send "$success_summ" "$success_body" -t "$timeout"
}

main "$@"
