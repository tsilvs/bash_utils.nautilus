#!/usr/bin/env bash

# Nautilus: Convert to GIF

# SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

main() {
	local timeout='10000'
	local uri=$(echo "$NAUTILUS_SCRIPT_SELECTED_URIS" | head -n1)
	local input_file="${uri#file://}"
	
	while [[ "$input_file" =~ %([0-9A-Fa-f]{2}) ]]; do
		input_file="${input_file//${BASH_REMATCH[0]}/$(printf "\\x${BASH_REMATCH[1]}")}"
	done

	local types=("mp4" "avi" "mkv" "webm" "mov")
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
	
	local new_file="${input_file%.*}_converted.gif"
	local wip_summ="Converting to GIF"
	local wip_body="Processing: ${input_file##*/}"
	local success_summ="Conversion complete"
	local success_body="Saved: ${new_file##*/}"
	
	if [ "$input_file" ]; then
		notify-send "$wip_summ" "$wip_body" -t $timeout &
		local error_msg=$(ffmpeg -i "$input_file" \
			-vf "fps=15,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
			-loop 0 \
			-y "$new_file" 2>&1)
		if [ $? -ne 0 ]; then
			input_file=""
			fail_summ="Conversion failed"
			fail_body="FFmpeg error"
		fi
	fi

	if [ "$input_file" ]; then
		act=$(
			notify-send \
				"$success_summ" \
				"$success_body" \
				-A "open=Open" \
				-A "del=Delete" \
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
		act=$(
			notify-send \
				"$fail_summ" \
				"$fail_body" \
				-A "copy=Copy error" \
				--wait
		)
		if [ "$act" = "copy" ]; then
			echo -n "${error_msg:-$fail_body}" | xclip -selection clipboard
		fi
		[ -f "$new_file" ] && rm "$new_file"
	fi

	return 0
}

main "$@"