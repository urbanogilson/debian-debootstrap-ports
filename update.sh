#!/bin/bash
set -eo pipefail

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "a:v:q:u:d:s:i:o:" opt; do
    case "$opt" in
    a)  ARCH=$OPTARG
        ;;
    v)  VERSION=$OPTARG
        ;;
    q)  QEMU_ARCH=$OPTARG
        ;;
    u)  QEMU_VER=$OPTARG
        ;;
    d)  DOCKER_REPO=$OPTARG
        ;;
    o)  UNAME_ARCH=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

dir="$VERSION-$ARCH"
VARIANT="minbase"
args=( -d "$dir" debootstrap --no-check-gpg --variant="$VARIANT" --include="wget" --arch="$ARCH" "$VERSION" https://deb.debian.org/debian-ports)

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
echo "ENV ARCH=${UNAME_ARCH} UBUNTU_SUITE=${VERSION} DOCKER_REPO=${DOCKER_REPO}" >> "${dir}/Dockerfile"

if [ "$DOCKER_REPO" ]; then
    docker build -t "${DOCKER_REPO}:${ARCH}-${VERSION}-slim" "${dir}"
    mkdir -p "${dir}/full"
    (
    cd "${dir}/full"
    if [ ! -f x86_64_qemu-${QEMU_ARCH}-static.tar.gz ]; then
        wget -N https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VER}/x86_64_qemu-${QEMU_ARCH}-static.tar.gz
    fi
    tar xf x86_64_qemu-*.gz
    )
    cat > "${dir}/full/Dockerfile" <<EOF
FROM ${DOCKER_REPO}:${ARCH}-${VERSION}-slim
ADD qemu-*-static /usr/bin/
EOF
    docker build -t "${DOCKER_REPO}:${ARCH}-${VERSION}" "${dir}/full"
fi

CONTAINER=`docker run --rm ${DOCKER_REPO}:${ARCH}-${VERSION} /bin/bash -c "uname -a; cat /etc/debian_version"`
echo "${CONTAINER}"
NEW_VERSION=`echo "${CONTAINER}" | tail -1 | tr "/" "-"`

docker image tag "${DOCKER_REPO}:${ARCH}-${VERSION}" "${DOCKER_REPO}:${ARCH}-${NEW_VERSION}"
docker rmi "${DOCKER_REPO}:${ARCH}-${VERSION}"
docker image tag "${DOCKER_REPO}:${ARCH}-${VERSION}-slim" "${DOCKER_REPO}:${ARCH}-${NEW_VERSION}-slim"
docker rmi "${DOCKER_REPO}:${ARCH}-${VERSION}-slim"
