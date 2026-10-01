#!/bin/sh
# Build the Silicon Cellar renderer packages from pinned inputs. The files inside are not changed.
#
# Usage: ./build-packages.sh <D3DMetal 4.0 beta 2 DMG> <D3DMetal 3.0 DMG> <output folder>
#
# Apple's DMGs ("Evaluation environment for Windows games") need an Apple ID, so this script does not
# download them. It checks their SHA-256.
set -eu

TEMPLATE_URL="https://github.com/Sikarugir-App/Wrapper/releases/download/v1.0/Template-1.0.15.tar.xz"
TEMPLATE_SHA256="34273bcce885ce5a7fd6937af9ea344bb9961de7d55d6193f7413142e835c8c3"
DXMT_072_URL="https://github.com/3Shain/dxmt/releases/download/v0.72/dxmt-v0.72-builtin.tar.gz"
DXMT_072_SHA256="661eae8cc12c5ad900ecf3c76e7bacfda519b3eeb5ed5c44b48875b2373e89fe"
DXMT_072_LICENSE_URL="https://raw.githubusercontent.com/3Shain/dxmt/v0.72/LICENSE"
DXMT_072_LICENSE_SHA256="6b928413c6308c106f3e0080bd94b6427b56d587d400fd40e6cbfbab7d9c4ae1"
D3DMETAL_40B2_DMG_SHA256="6248a0edc61553790753e5e9c060b8e53c940ed197f11409dcc34a35e05becc1"
D3DMETAL_30_DMG_SHA256="d49395fb07e536804d1da0858590e53f6aa6fab12512e18fd80a74c87f9f063c"

[ $# -eq 3 ] || { echo "usage: $0 <D3DMetal 4.0 beta 2 DMG> <D3DMetal 3.0 DMG> <output folder>" >&2; exit 2; }
D3DMETAL_40B2_DMG=$1
D3DMETAL_30_DMG=$2
OUTPUT_DIR=$3
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CACHE_DIR="$SCRIPT_DIR/.cache"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/sc-renderers.XXXXXX")
# macOS tar adds AppleDouble files without this.
export COPYFILE_DISABLE=1

die() {
    echo "error: $*" >&2
    exit 1
}

cleanup() {
    for mount_point in "$WORK_DIR"/mount-*; do
        [ -d "$mount_point" ] && hdiutil detach -quiet "$mount_point" 2>/dev/null || true
    done
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

check_sha256() {
    actual_sha256=$(shasum -a 256 "$1" | cut -d' ' -f1)
    [ "$actual_sha256" = "$2" ] || die "$1 has SHA-256 $actual_sha256, expected $2"
}

# fetch <url> <sha256>: download into the cache once, check it, and print its path.
fetch() {
    cached_file="$CACHE_DIR/$(basename "$1")"
    if [ ! -f "$cached_file" ]; then
        curl --fail --location --silent --show-error --proto =https --proto-redir =https \
            --output "$cached_file.partial" "$1"
        mv "$cached_file.partial" "$cached_file"
    fi
    check_sha256 "$cached_file" "$2"
    echo "$cached_file"
}

# new_package <id>: make an empty staging folder for a package and print its path.
new_package() {
    package_staging="$WORK_DIR/package-$1"
    rm -rf "$package_staging"
    mkdir -p "$package_staging"
    echo "$package_staging"
}

# write_package <id> <staging folder> <SOURCE.txt text>
write_package() {
    printf '%s\n' "$3" > "$2/SOURCE.txt"
    tar -C "$2" -cJf "$OUTPUT_DIR/$1.tar.xz" .
    echo "wrote $OUTPUT_DIR/$1.tar.xz"
}

# package_template_renderer <id> <Template renderer folder>
package_template_renderer() {
    staging=$(new_package "$1")
    ditto "$TEMPLATE_RENDERERS/$2" "$staging"
    write_package "$1" "$staging" "Input: $TEMPLATE_URL
SHA-256: $TEMPLATE_SHA256
Folder: Template-1.0.15.app/Contents/Frameworks/renderer/$2
Version: $(cat "$staging/version")"
}

# package_d3dmetal <id> <DMG> <DMG SHA-256> <version>
package_d3dmetal() {
    check_sha256 "$2" "$3"
    mount_point="$WORK_DIR/mount-$1"
    mkdir -p "$mount_point"
    hdiutil attach -readonly -nobrowse -noautoopen -mountpoint "$mount_point" "$2" >/dev/null
    staging=$(new_package "$1")
    ditto "$mount_point/redist/lib/external" "$staging/external"
    ditto "$mount_point/redist/lib/wine" "$staging/wine"
    cp "$mount_point/License.rtf" "$mount_point/Acknowledgements.rtf" "$staging/"
    hdiutil detach -quiet "$mount_point"
    write_package "$1" "$staging" "Input: Apple \"Evaluation environment for Windows games $4\" DMG (developer.apple.com, Apple ID)
SHA-256: $3
Folders: redist/lib/external, redist/lib/wine
Version: $4
Licence: Apple Game Porting Toolkit licence EA18380 (License.rtf). Non-commercial distribution only."
}

mkdir -p "$CACHE_DIR" "$OUTPUT_DIR"

template_archive=$(fetch "$TEMPLATE_URL" "$TEMPLATE_SHA256")
tar -xJf "$template_archive" -C "$WORK_DIR" "Template-1.0.15.app/Contents/Frameworks/renderer"
TEMPLATE_RENDERERS="$WORK_DIR/Template-1.0.15.app/Contents/Frameworks/renderer"
package_template_renderer dxvk dxvk
package_template_renderer dxmt dxmt

dxmt_072_archive=$(fetch "$DXMT_072_URL" "$DXMT_072_SHA256")
dxmt_072_license=$(fetch "$DXMT_072_LICENSE_URL" "$DXMT_072_LICENSE_SHA256")
staging=$(new_package dxmt-v0.72)
mkdir -p "$staging/wine"
tar -xzf "$dxmt_072_archive" -C "$staging/wine" --strip-components 1
cp "$dxmt_072_license" "$staging/LICENSE"
write_package dxmt-v0.72 "$staging" "Input: $DXMT_072_URL
SHA-256: $DXMT_072_SHA256
Licence: $DXMT_072_LICENSE_URL (SHA-256 $DXMT_072_LICENSE_SHA256)
Version: v0.72"

package_d3dmetal d3dmetal "$D3DMETAL_40B2_DMG" "$D3DMETAL_40B2_DMG_SHA256" "4.0 beta 2"
package_d3dmetal d3dmetal-3.0 "$D3DMETAL_30_DMG" "$D3DMETAL_30_DMG_SHA256" "3.0"

(cd "$OUTPUT_DIR" && shasum -a 256 dxvk.tar.xz dxmt.tar.xz dxmt-v0.72.tar.xz d3dmetal.tar.xz d3dmetal-3.0.tar.xz > SHA256SUMS)
cat "$OUTPUT_DIR/SHA256SUMS"
