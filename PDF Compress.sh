#!/usr/bin/env bash -l -c

# Nautilus: PDF Compress

set -euo pipefail

decode_uri() {
	local input="$1"
	while [[ "$input" =~ %([0-9A-Fa-f]{2}) ]]; do
		input="${input//${BASH_REMATCH[0]}/$(printf "\\x${BASH_REMATCH[1]}")}"
	done
	echo "$input"
}

process_file() {
	local input_file="$1"
	local timeout='10000'

	if [ ! -f "$input_file" ]; then
		notify-send "File not found" "Could not access: ${input_file##*/}"
		return 1
	fi

	local mime_type
	mime_type="$(file --brief --mime-type "$input_file")"
	if [ "$mime_type" != "application/pdf" ]; then
		notify-send "Invalid file type" "Not a PDF: ${input_file##*/}"
		return 1
	fi

	local base="$input_file"
	if [[ "${base,,}" == *.pdf ]]; then
		base="${base%.*}"
	fi
	local new_file="${base}.cmp.pdf"

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

main() {
	if ! declare -F "pdf.cmp" >/dev/null 2>&1; then
		# Phase 1: source typical profile/bashrc init files
		local _rc
		for _rc in /etc/profile /etc/bashrc /etc/bash.bashrc "${HOME}/.profile" "${HOME}/.bashrc"; do
			# shellcheck source=/dev/null
			[[ -f "$_rc" ]] && source "$_rc" 2>/dev/null || true
		done
	fi

	if ! declare -F "pdf.cmp" >/dev/null 2>&1; then
		# Phase 2: source pdf_utils.sh directly from each bash_utils scope path
		local _scope _candidate
		for _scope in /etc/profile.d /etc/bashrc.d "${HOME}/.profile.d" "${HOME}/.bashrc.d"; do
			_candidate="${_scope}/tsilvs/bash_utils/pdf_utils.sh"
			if [[ -f "$_candidate" ]]; then
				# shellcheck source=/dev/null
				source "$_candidate"
				break
			fi
		done
	fi

	if ! declare -F "pdf.cmp" >/dev/null 2>&1; then
		notify-send "Missing dependency" 'try installing `tsilvs/bash_utils`'
		return 1
	fi

	local uris=()
	if [ -n "${NAUTILUS_SCRIPT_SELECTED_URIS:-}" ]; then
		mapfile -t uris < <(printf '%s' "$NAUTILUS_SCRIPT_SELECTED_URIS" | grep -v '^$')
	elif [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
		uris=("$NAUTILUS_SCRIPT_CURRENT_URI")
	fi

	if [ "${#uris[@]}" -eq 0 ]; then
		notify-send "No file selected" "Select a PDF to compress."
		return 1
	fi

	for uri in "${uris[@]}"; do
		local input_file="${uri#file://}"
		input_file="$(decode_uri "$input_file")"
		process_file "$input_file" || true
	done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
