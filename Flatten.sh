#!/bin/bash

scriptroot="${0%/*}"

#!/bin/bash

set -e
set -u
set -o pipefail

prop_get() {
	local json="$1"
	local prop="$2"
	echo "$json" | jq -r "$prop"
}

pad_number() {
	printf "%03d" "$1"
}

flat() {
	local dir="$1"
	local counter=1

	cd "$dir"

	for subdir in */; do
		subdir=${subdir%/}
		
		if [ -d "$subdir" ]; then
			for file in "$subdir"/*; do
				if [ -f "$file" ]; then
					local ext="${file##*.}"
					local new_name="${subdir}.$(pad_number $counter).${ext}"
					mv "$file" "$new_name"
					((counter++))
				fi
			done
			rmdir "$subdir"
		fi
	done
}

main() {
	local lang="en"
	local timeout='10000'
	local uri="$NAUTILUS_SCRIPT_CURRENT_URI"
	local i18n='
	{
		"en": {
			"succ": {
				"summ": "Directory Flattened",
				"body": "File structure has been flattened."
			},
			"fail": {
				"summ": "Error",
				"body": "Could not flatten the directory."
			},
			"open": "Open Directory"
		}
	}
	'

	local dirpath="${uri#file://}"
	dirpath="${dirpath//%20/ }"
	local dirname="${dirpath##*/}"

	flat "$dirpath"

	local act=$(
		notify-send \
			"$(prop_get "$i18n" ".$lang.succ.summ")" \
			"$(prop_get "$i18n" ".$lang.succ.body")" \
			-A "open=$(prop_get "$i18n" ".$lang.open")" \
			--wait \
			-t $timeout
	)
	case "$act" in
		"open") xdg-open "$dirpath" ;;
	esac
}

main "$@"
