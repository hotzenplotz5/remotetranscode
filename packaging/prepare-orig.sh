#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_VERSION="${1:-0.1+git20261117.49240d0}"
OUTDIR="${2:-${ROOT}/dist}"
SOURCE_DIR="${OUTDIR}/remotetranscode-${UPSTREAM_VERSION}"
ORIG_TARBALL="${OUTDIR}/remotetranscode_${UPSTREAM_VERSION}.orig.tar.xz"

command -v git >/dev/null
command -v meson >/dev/null
command -v tar >/dev/null

rm -rf "${SOURCE_DIR}"
mkdir -p "${SOURCE_DIR}" "${OUTDIR}"

git -C "${ROOT}" archive --format=tar HEAD | tar -xf - -C "${SOURCE_DIR}"

cd "${SOURCE_DIR}"
rm -rf subprojects/packagecache

# Every wrap file carries an immutable source_hash.  Resolve them before the
# source package is uploaded so the Launchpad builder itself stays offline.
meson subprojects download

TMPDIR_ORIG="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_ORIG}"' EXIT
mkdir -p "${TMPDIR_ORIG}/remotetranscode-${UPSTREAM_VERSION}"
cp -a . "${TMPDIR_ORIG}/remotetranscode-${UPSTREAM_VERSION}/"
rm -rf "${TMPDIR_ORIG}/remotetranscode-${UPSTREAM_VERSION}/debian"
rm -rf "${TMPDIR_ORIG}/remotetranscode-${UPSTREAM_VERSION}/dist"

SOURCE_DATE_EPOCH="$(git -C "${ROOT}" show -s --format=%ct HEAD)"
tar --sort=name   --mtime="@${SOURCE_DATE_EPOCH}"   --owner=0 --group=0 --numeric-owner   -C "${TMPDIR_ORIG}"   -cJf "${ORIG_TARBALL}"   "remotetranscode-${UPSTREAM_VERSION}"

printf 'PREPARED_SOURCE=%s\n' "${SOURCE_DIR}"
printf 'ORIG_TARBALL=%s\n' "${ORIG_TARBALL}"
printf 'UPSTREAM_FIX_HEAD=%s\n' "49240d07a7a4f2c299960192cd1fc6f6865de7bb"
