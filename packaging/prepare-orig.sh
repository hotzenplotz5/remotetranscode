#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_VERSION="${1:-0.1+git20261128.ca94751}"
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

download_rc=0
meson subprojects download || download_rc=$?

required_subprojects=(
  dash2ts-4ef8bf173f7ea355bcab7f7d42f436541d4f795a
  mINI-0.9.14
  spdlog-1.15.0
  thrift-0.24.0
  tiny-process-library-4bf0e59e64f18d3080a1ce4e853775de2181e993
)
for subproject in "${required_subprojects[@]}"; do
  test -d "subprojects/${subproject}"
done
if (( download_rc != 0 )); then
  printf 'MESON_SUBPROJECT_DOWNLOAD_EXIT=%s (required sources verified)\n' "${download_rc}"
fi

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
printf 'FORK_SOURCE_HEAD=%s\n' "$(git -C "${ROOT}" rev-parse HEAD)"
printf 'UPSTREAM_FIX_HEAD=%s\n' "ca9475181fe0e38f75f7a87866e93432bd447407"
