# debian-debootstrap-ports

[![actions](https://github.com/urbanogilson/debian-debootstrap-ports/actions/workflows/actions.yml/badge.svg?branch=main)](https://github.com/urbanogilson/debian-debootstrap-ports/actions/workflows/actions.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/urbanogilson/debian-debootstrap-ports)](https://hub.docker.com/r/urbanogilson/debian-debootstrap-ports)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/urbanogilson/debian-debootstrap-ports/blob/main/LICENSE)

Minimal Debian Docker images for architectures available only through [Debian Ports](https://www.debian.org/ports/) — built with `debootstrap` and QEMU user-mode emulation.

## Usage

Enable multi-architecture support on your Docker host (required once):

```console
$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

Then run any supported architecture from an `x86_64` host:

```console
$ docker run -it --rm urbanogilson/debian-debootstrap-ports:powerpc-forky-sid
root@urbanogilson:/# uname -a
Linux urbanogilson 6.17.0-20-generic #20~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Mar 19 01:28:37 UTC 2 ppc GNU/Linux
```

## Image variants

Each architecture is published in two variants:

| Variant | Tag pattern | Description |
|---------|-------------|-------------|
| full | `ARCH-VERSION` | Includes `qemu-*-static` — runs on any x86_64 host without extra setup |
| slim | `ARCH-VERSION-slim` | No QEMU binary — smaller, for use when binfmt is already registered on the host |

Example tags: `m68k-trixie-sid`, `m68k-trixie-sid-slim`

## Supported ports

| Port | Architecture | Endianness | Description |
|------|-------------|------------|-------------|
| `alpha` | Alpha 64-bit RISC | little | Port to the 64-bit RISC Alpha architecture. |
| `hppa` | HP PA-RISC | big | Port to Hewlett-Packard's PA-RISC architecture. |
| `loong64` | LoongArch 64-bit | little | Port to the Loongson LoongArch 64-bit architecture. |
| `m68k` | Motorola 68k | big | Port to the Motorola 68k series — Sun3 workstations, Apple Macintosh, Atari and Amiga. |
| `powerpc` | PowerPC 32-bit | big | Port for Apple PowerMac, CHRP and PReP machines. |
| `ppc64` | PowerPC 64-bit | big | Port for 64-bit PowerPC systems. |
| `sh4` | SuperH | little | Port to Hitachi SuperH processors and the open-source J-Core processor. |
| `sparc64` | SPARC 64-bit | big | Port to Sun's 64-bit SPARC architecture. |

All images target Debian `sid` (unstable) via [deb.debian.org/debian-ports](https://deb.debian.org/debian-ports).

## Source

Images are built from [Debian other ports](https://www.debian.org/ports/#portlist-other) using [`debootstrap`](https://wiki.debian.org/Debootstrap) and scripts derived from [moby/moby](https://github.com/moby/moby/tree/master/contrib).

This project is based on [multiarch/debian-debootstrap](https://github.com/multiarch/debian-debootstrap).

## License

This project is licensed under the [MIT License](LICENSE).
