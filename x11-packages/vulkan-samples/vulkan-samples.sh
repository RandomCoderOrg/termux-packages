#!/data/data/com.termux/files/usr/bin/sh
prefix="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$prefix/share/vulkan-samples" || exit 1
export LD_LIBRARY_PATH="$prefix/lib/vulkan-samples${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$prefix/libexec/vulkan-samples" "$@"
