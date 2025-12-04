#!/usr/bin/env bash

# Nautilus: Convert to MP4

main() {
	local lang="en"
	local timeout='10000'
	local uri=$(echo "$NAUTILUS_SCRIPT_SELECTED_URIS" | head -n1)
	local input_file="${uri#file://}"
	
	while [[ "$input_file" =~ %([0-9A-Fa-f]{2}) ]]; do
		input_file="${input_file//${BASH_REMATCH[0]}/$(printf "\\x${BASH_REMATCH[1]}")}"
	done

	local types=("mp4" "avi" "mkv" "webm")
	local ext="${input_file##*.}"
	ext="${ext,,}"

	local fail_summ=""
	local fail_body=""

	if [[ " ${types[@]} " =~ " ${ext} " ]]; then
		: # input_file already set
	else
		fail_summ="Invalid file type"
		fail_body="File must be: ${types[*]}. Got \"${ext}\"."
	fi
	
	local new_file="${input_file%.*}_converted.mp4"
	local wip_summ="Converting to MP4"
	local wip_body="Processing: ${input_file##*/}"
	local success_summ="Conversion complete"
	local success_body="Saved: ${new_file##*/}"
	
	if [ "$input_file" ]; then
		echo "DEBUG: input_file='$input_file'" > /tmp/nautilus-debug.log
		notify-send "$wip_summ" "$wip_body" -t $timeout
		ffmpeg -i "$input_file" -vf "scale='if(mod(iw,2),iw+1,iw)':'if(mod(ih,2),ih+1,ih)'" -c:v libx264 -c:a aac -y "$new_file" 2>/tmp/ffmpeg-error.log
		[ ${PIPESTATUS[0]} -ne 0 ] && input_file="" && fail_summ="Conversion failed" && fail_body="FFmpeg error during call: \"$(which ffmpeg) -i "$input_file" -c:v libx264 -c:a aac -y "$new_file"\"."
	fi

	if [ "$input_file" ]; then
		act=$(
			notify-send \
				"$success_summ" \
				"$success_body" \
				-A "open=" \
				-A "del=" \
				--wait \
				-t $timeout
		)
		case "$act" in
			"open") xdg-open "$new_file" ;;
			"del") 
				if [ -f "$new_file" ]; then
					rm "$new_file"
				fi
				;;
		esac
	else
		notify-send \
			"$fail_summ" \
			"$fail_body"
		[ -f "$new_file" ] && rm "$new_file"
	fi

	return 0
}

main "$@"