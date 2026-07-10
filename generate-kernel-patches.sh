#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

usage()
{
	echo "Usage: $0 LINUX_GIT_TREE OUTPUT_DIRECTORY" >&2
	exit 2
}

[ "$#" -eq 2 ] || usage

src_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
linux_tree=$1
output_dir=$2

git -C "$linux_tree" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
	echo "Not a Linux git tree: $linux_tree" >&2
	exit 1
}
linux_tree=$(git -C "$linux_tree" rev-parse --show-toplevel)

mkdir -p "$output_dir"
output_dir=$(CDPATH= cd -- "$output_dir" && pwd)

patch_driver="$output_dir/1001-Add-t2bce-driver-stack.patch"
patch_integration="$output_dir/1002-Integrate-t2bce-driver-stack.patch"
if [ -e "$patch_driver" ] || [ -e "$patch_integration" ]; then
	echo "Refusing to overwrite existing T2BCE patches in $output_dir" >&2
	exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
work_tree="$tmp_dir/linux"

git clone --quiet --no-checkout "$linux_tree" "$work_tree"
git -C "$work_tree" checkout --quiet --detach HEAD
git -C "$work_tree" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git -C "$work_tree" config user.name "github-actions[bot]"

"$src_dir/export-kernel-tree.sh" "$work_tree/drivers/staging/t2bce"
git -C "$work_tree" add drivers/staging/t2bce
git -C "$work_tree" commit --quiet -m "Add t2bce driver stack"
git -C "$work_tree" format-patch --quiet -1 --stdout HEAD >"$patch_driver"

staging_kconfig="$work_tree/drivers/staging/Kconfig"
staging_makefile="$work_tree/drivers/staging/Makefile"

grep -q '^endif # STAGING$' "$staging_kconfig" || {
	echo "Could not find the staging Kconfig insertion point" >&2
	exit 1
}

sed -i '/^endif # STAGING$/i source "drivers/staging/t2bce/Kconfig"\
' "$staging_kconfig"
printf 'obj-$(CONFIG_T2BCE_CORE)\t\t+= t2bce/\n' >>"$staging_makefile"

git -C "$work_tree" add drivers/staging/Kconfig drivers/staging/Makefile
git -C "$work_tree" commit --quiet -m "Integrate t2bce driver stack"
git -C "$work_tree" format-patch --quiet -1 --stdout HEAD >"$patch_integration"

printf 'Generated:\n  %s\n  %s\n' "$patch_driver" "$patch_integration"
