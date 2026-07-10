#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

usage()
{
	echo "Usage: $0 DESTINATION" >&2
	exit 2
}

[ "$#" -eq 1 ] || usage

src_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
dest_dir=$1

if [ -e "$dest_dir" ] && [ ! -d "$dest_dir" ]; then
	echo "Destination is not a directory: $dest_dir" >&2
	exit 1
fi

if [ -d "$dest_dir" ] && [ "$(find "$dest_dir" -mindepth 1 -print -quit)" ]; then
	echo "Destination is not empty: $dest_dir" >&2
	exit 1
fi

mkdir -p "$dest_dir"
cp "$src_dir/kernel/Kconfig" "$src_dir/kernel/Makefile" "$dest_dir/"

for module in t2bce_dma t2bce_core t2bce_vhci t2bce_audio; do
	mkdir -p "$dest_dir/$module"
	find "$src_dir/$module" -maxdepth 1 -type f \( -name '*.c' -o -name '*.h' \) \
		-exec cp '{}' "$dest_dir/$module/" ';'
	if [ -d "$src_dir/$module/include" ]; then
		cp -a "$src_dir/$module/include" "$dest_dir/$module/"
	fi
	cp "$src_dir/kernel/$module/Makefile" "$dest_dir/$module/Makefile"
done
