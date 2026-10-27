TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Samples
TERMUX_PKG_DESCRIPTION="Khronos Vulkan Samples command-line runner"
TERMUX_PKG_LICENSE="custom"
TERMUX_PKG_LICENSE_FILE="LICENSE,assets/README.md"
TERMUX_PKG_MAINTAINER="@RandomCoderOrg"
TERMUX_PKG_VERSION="0.0.20261022"
_COMMIT=69622af06f7652c7fc9b9a9180e7142046315cbc
TERMUX_PKG_SRCURL=git+https://github.com/KhronosGroup/Vulkan-Samples.git
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libc++, libx11, libxcb, libxcursor, libxi, libxinerama, libxrandr, vulkan-loader-generic"
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers, xorgproto"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DCMAKE_POLICY_VERSION_MINIMUM=3.5
-DVKB_WSI_SELECTION=XCB
-DVKB_BUILD_TESTS=OFF
-DVKB_BUILD_SHADERS=OFF
-DVKB_VULKAN_DEBUG=OFF
-DVKB_WARNINGS_AS_ERRORS=OFF
-DBUILD_SHARED_LIBS=OFF
-DGLFW_BUILD_WAYLAND=OFF
"

termux_step_pre_configure() {
	# ASTC's NEON backend uses AArch64 intrinsics unavailable on 32-bit ARM.
	if [ "$TERMUX_ARCH" = "arm" ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DASTC_ARCH=NONE"
	fi
}

termux_step_get_source() {
	mkdir -p "$TERMUX_PKG_SRCDIR"
	git -C "$TERMUX_PKG_SRCDIR" init
	git -C "$TERMUX_PKG_SRCDIR" remote add origin "${TERMUX_PKG_SRCURL#git+}"
	git -C "$TERMUX_PKG_SRCDIR" fetch --depth=1 --filter=blob:none origin "$_COMMIT"
	git -C "$TERMUX_PKG_SRCDIR" checkout --detach FETCH_HEAD
	local submodule
	local -a submodules=()
	while read -r _ submodule; do
		[[ "$submodule" == third_party/* ]] && submodules+=("$submodule")
	done < <(git -C "$TERMUX_PKG_SRCDIR" config --file .gitmodules --get-regexp 'submodule\..*\.path')
	git -C "$TERMUX_PKG_SRCDIR" submodule update --init --depth=1 -- "${submodules[@]}"
	git -C "$TERMUX_PKG_SRCDIR" submodule update --init --depth=1 -- assets
}

termux_step_make_install() {
	local build_type=Release
	[[ "${TERMUX_DEBUG_BUILD}" == "true" ]] && build_type=Debug
	install -Dm755 "${TERMUX_PKG_BUILDDIR}/app/bin/${build_type}/${TERMUX_ARCH}/vulkan_samples" \
		"${TERMUX_PREFIX}/libexec/vulkan-samples"
	local library
	for library in liboctomap.so libdynamicEDT3d.so; do
		install -Dm755 "${TERMUX_PKG_BUILDDIR}/samples/complex/render_octomap/lib/${build_type}/${TERMUX_ARCH}/${library}" \
			"${TERMUX_PREFIX}/lib/vulkan-samples/${library}"
	done
	install -Dm755 "${TERMUX_PKG_BUILDER_DIR}/vulkan-samples.sh" \
		"${TERMUX_PREFIX}/bin/vulkan-samples"
	mkdir -p "${TERMUX_PREFIX}/share/vulkan-samples"
	cp -a "${TERMUX_PKG_SRCDIR}/shaders" "${TERMUX_PREFIX}/share/vulkan-samples/"
	cp -a "${TERMUX_PKG_SRCDIR}/assets" "${TERMUX_PREFIX}/share/vulkan-samples/"
	rm -f "${TERMUX_PREFIX}/share/vulkan-samples/assets/.git"
}
