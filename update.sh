#!/bin/bash
set -xeo pipefail

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "a:c:v:q:d:o:" opt; do
    case "$opt" in
    a)  ARCH=$OPTARG
        ;;
    c)  CONTAINER_ARCH=$OPTARG
        ;;
    v)  VERSION=$OPTARG
        ;;
    q)  QEMU_ARCH=$OPTARG
        ;;
    d)  DOCKER_REPO=$OPTARG
        ;;
    o)  UNAME_ARCH=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "ARCH=$ARCH CONTAINER_ARCH=$CONTAINER_ARCH VERSION=$VERSION QEMU_ARCH=$QEMU_ARCH UNAME_ARCH=$UNAME_ARCH"

dir="$VERSION-$ARCH"
VARIANT="minbase"
EXTRA_PACKAGES="bash,ca-certificates,debian-ports-archive-keyring,lsb-release,wget"
args=( -d "$dir" debootstrap --no-check-gpg --variant="$VARIANT" --include="$EXTRA_PACKAGES" --arch="$ARCH" "$VERSION" https://deb.debian.org/debian-ports)

mkdir -p mkimage $dir
curl https://raw.githubusercontent.com/moby/moby/6f78b438b88511732ba4ac7c7c9097d148ae3568/contrib/mkimage.sh > mkimage.sh
curl https://raw.githubusercontent.com/moby/moby/6f78b438b88511732ba4ac7c7c9097d148ae3568/contrib/mkimage/debootstrap > mkimage/debootstrap
chmod +x mkimage.sh mkimage/debootstrap

mkimage="$(readlink -f "${MKIMAGE:-"mkimage.sh"}")"
{
    echo "$(basename "$mkimage") ${args[*]/"$dir"/.}"
    echo
    echo 'https://github.com/moby/moby/blob/6f78b438b88511732ba4ac7c7c9097d148ae3568/contrib/mkimage.sh'
} > "$dir/build-command.txt"

sudo DEBOOTSTRAP="debootstrap" nice ionice -c 2 "$mkimage" "${args[@]}" 2>&1 | tee "$dir/build.log"
cat "$dir/build.log"
sudo chown -R "$(id -u):$(id -g)" "$dir"

xz -d < $dir/rootfs.tar.xz | gzip -c > $dir/rootfs.tar.gz
sed -i /^ENV/d "${dir}/Dockerfile"
echo "ENV ARCH=${UNAME_ARCH} DEBIAN_SUITE=${VERSION} DOCKER_REPO=${DOCKER_REPO}" >> "${dir}/Dockerfile"

if [ "$DOCKER_REPO" ]; then
    docker buildx build --provenance false --platform "linux/${CONTAINER_ARCH}" \
        -t "${DOCKER_REPO}:${ARCH}-${VERSION}-slim" "${dir}"

    mkdir -p "${dir}/full"
    cp "/usr/bin/qemu-${QEMU_ARCH}-static" "${dir}/full/"
    cat > "${dir}/full/Dockerfile" <<EOF
FROM ${DOCKER_REPO}:${ARCH}-${VERSION}-slim
ADD qemu-*-static /usr/bin/
EOF
    docker buildx build --provenance false --platform "linux/${CONTAINER_ARCH}" \
        -t "${DOCKER_REPO}:${ARCH}-${VERSION}" "${dir}/full"
fi

CONTAINER=$(docker run --rm --platform "linux/${CONTAINER_ARCH}" "${DOCKER_REPO}:${ARCH}-${VERSION}" \
    /bin/bash -c "uname -a; cat /etc/debian_version")
echo "${CONTAINER}"
NEW_VERSION=$(echo "${CONTAINER}" | tail -1 | tr "/" "-")

docker image tag "${DOCKER_REPO}:${ARCH}-${VERSION}" "${DOCKER_REPO}:${ARCH}-${NEW_VERSION}"
docker rmi "${DOCKER_REPO}:${ARCH}-${VERSION}"
docker image tag "${DOCKER_REPO}:${ARCH}-${VERSION}-slim" "${DOCKER_REPO}:${ARCH}-${NEW_VERSION}-slim"
docker rmi "${DOCKER_REPO}:${ARCH}-${VERSION}-slim"
