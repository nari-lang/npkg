#!/bin/sh
# Bundle the npkg CLI into a release tarball.
#   ./bundle.sh [version]
set -euo pipefail

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$here"

VERSION="${1:-$(git describe --tags --always --dirty 2>/dev/null || echo dev)}"
case "$VERSION" in v*) ;; *) VERSION="v${VERSION}" ;; esac

NAME="npkg-${VERSION}"
STAGE="dist/${NAME}"

rm -rf "$STAGE"
mkdir -p "${STAGE}/bin" "${STAGE}/lib/npkg"

cp main.nari "${STAGE}/lib/npkg/main.nari"
cp -R lib "${STAGE}/lib/npkg/lib"
cp LICENSE "${STAGE}/LICENSE" 2>/dev/null || true
cp README.md "${STAGE}/README.md" 2>/dev/null || true

cat > "${STAGE}/bin/npkg" <<'WRAPPER'
#!/bin/sh
self="$0"
while [ -L "$self" ]; do
    link=$(readlink "$self")
    case "$link" in
        /*) self="$link" ;;
        *)  self="$(dirname "$self")/$link" ;;
    esac
done
bindir=$(cd "$(dirname "$self")" && pwd)
root=$(dirname "$bindir")
if [ -x "$bindir/nari" ]; then
    exec "$bindir/nari" "$root/lib/npkg/main.nari" "$@"
fi
exec nari "$root/lib/npkg/main.nari" "$@"
WRAPPER
chmod +x "${STAGE}/bin/npkg"

( cd dist && tar --format=ustar -czf "${NAME}.tar.gz" "${NAME}" )

if command -v sha256sum >/dev/null 2>&1; then
    ( cd dist && sha256sum "${NAME}.tar.gz" > "${NAME}.tar.gz.sha256" )
elif command -v shasum >/dev/null 2>&1; then
    ( cd dist && shasum -a 256 "${NAME}.tar.gz" > "${NAME}.tar.gz.sha256" )
else
    echo "bundle.sh: no sha256 tool found; skipping checksum" >&2
fi

rm -rf "$STAGE"
echo "dist/${NAME}.tar.gz"
