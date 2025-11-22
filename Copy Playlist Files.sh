#!/bin/bash

scriptroot="${0%/*}"

main() {
	local dv1=""
	local v1=${1:-$dv1}
	echo "$v1"
}

main "$@"

# Bash Parameter Expansion:
# ${var#pattern} : Removes short match from begin of `var`
# ${var##pattern}: Removes long  match from begin of `var`
# ${var%pattern} : Removes short match from end   of `var`
# ${var%%pattern}: Removes long  match from end   of `var`
# For path="/home/user/documents/file.txt"
# fil="${path##*/}": Extracts "file.txt"
# dir="${path%/*}":  Extracts "/home/user/documents"

# $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS
# $NAUTILUS_SCRIPT_SELECTED_URIS
# $NAUTILUS_SCRIPT_CURRENT_URI
# $NAUTILUS_SCRIPT_WINDOW_GEOMETRY
