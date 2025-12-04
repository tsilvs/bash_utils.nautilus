#!/usr/bin/env bash

# Nautilus: Convert to MP4

main() {
	local lang="en"
	local timeout='10000'
	local uri="$NAUTILUS_SCRIPT_CURRENT_URI"
	
	local types=( "mp4" "avi" "mkv" "webm" )
	
	local dirpath="${uri#file://}"
	dirpath="${dirpath//%20/ }"
	local dirname="${dirpath##*/}"
	local ext="${dirname##*.}"
	
	local input_file=""
	local fail_summ=""
	local fail_body=""
	
	if [[ " ${types[@]} " =~ " ${ext,,} " ]]; then
		input_file="$dirpath"
	else
		fail_summ="Invalid file type"
		fail_body="File must be: ${types[*]}"
	fi
	
	local new_file="${dirpath%.*}_converted.mp4"
	local wip_summ="Converting to MP4"
	local wip_body="Processing: $dirname"
	local success_summ="Conversion complete"
	local success_body="Saved: ${new_file##*/}"
	
	if [ "$input_file" ]; then
		notify-send "$wip_summ" "$wip_body" -t $timeout
		ffmpeg -i "$input_file" -c:v libx264 -c:a aac -y "$new_file" 2>/dev/null
		[ $? -ne 0 ] && input_file="" && fail_summ="Conversion failed" && fail_body="FFmpeg error"
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