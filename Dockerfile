ARG S6_VERSION=v3.2.0.0
ARG GH_DOWNLOAD='https://github.com/just-containers/s6-overlay/releases/download'

# Tools for building the s6-overlay images
FROM alpine:latest AS internal
RUN apk add --no-cache curl cmd:sha256sum
ARG TARGETARCH TARGETVARIANT
RUN <<EOT
    {
    # See:
    # https://github.com/just-containers/s6-overlay/blob/d6f37bb2052cfc5705154315419dcacb3975f11e/README.md?plain=1#L1023
        case "${TARGETARCH}${TARGETVARIANT:+/}${TARGETVARIANT}" in
            (amd64) echo 'x86_64' ;;
            (arm64) echo 'aarch64' ;;
            (riscv64) echo 'riscv64' ;;
            (s390x) echo 's390x' ;;
            (386) echo 'i686' ;;
            (arm/v6) echo 'armhf' ;;
            (arm/v7) echo 'arm' ;;
            (*) echo 1>&2 'Unsupported architecture!' ; exit 1 ;;
        esac
    } >| /S6_ARCH
EOT


# Overlay for s6-overlay-noarch.tar.xz & s6-overlay-${arch}.tar.xz
FROM internal AS s6-overlay-rootfs
ARG GH_DOWNLOAD
ARG S6_VERSION
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-noarch.tar.xz.sha256" /tmp/
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-noarch.tar.xz" /tmp/
RUN <<EOT
    set -e
    S6_ARCH=$(cat /S6_ARCH)
    mkdir /s6-overlay-rootfs /verified
    set -x
    curl -L "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" -o /tmp/s6-overlay-${S6_ARCH}.tar.xz
    curl -L "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.xz.sha256" -o /tmp/s6-overlay-${S6_ARCH}.tar.xz.sha256
    cd   /tmp &&
    for sumfile in *.sha256
    do
        if sha256sum --check --warn --strict "${sumfile}"
        then
            mv -v "${sumfile%.sha256}" "${sumfile}" /verified/
        fi
    done
    tar  -C /s6-overlay-rootfs -Jxpf /verified/s6-overlay-noarch.tar.xz
    tar  -C /s6-overlay-rootfs -Jxpf /verified/s6-overlay-${S6_ARCH}.tar.xz
EOT
FROM scratch AS s6-overlay
COPY --from=s6-overlay-rootfs /s6-overlay-rootfs /


# Overlay for s6-overlay-symlinks-noarch.tar.xz & s6-overlay-symlinks-arch.tar.xz
FROM --platform=${BUILDPLATFORM} internal AS s6-overlay-rootfs-symlinks
ARG GH_DOWNLOAD
ARG S6_VERSION
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz.sha256" /tmp/
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz" /tmp/
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz.sha256" /tmp/
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz" /tmp/
RUN <<EOF
    set -e
    mkdir /s6-overlay-rootfs /verified
    set -x
    cd   /tmp &&
    for sumfile in *.sha256
    do
        if sha256sum --check --warn --strict "${sumfile}"
        then
            mv -v "${sumfile%.sha256}" "${sumfile}" /verified/
        fi
    done
    tar  -C /s6-overlay-rootfs -Jxpf /verified/s6-overlay-symlinks-noarch.tar.xz
    tar  -C /s6-overlay-rootfs -Jxpf /verified/s6-overlay-symlinks-arch.tar.xz
EOF
FROM scratch AS s6-overlay-symlinks
COPY --from=s6-overlay-rootfs-symlinks /s6-overlay-rootfs /


# Overlay for syslogd-overlay-noarch.tar.xz
FROM --platform=${BUILDPLATFORM} internal AS s6-overlay-rootfs-syslogd
ARG GH_DOWNLOAD
ARG S6_VERSION
ADD "${GH_DOWNLOAD}/${S6_VERSION}/syslogd-overlay-noarch.tar.xz.sha256" /tmp/
ADD "${GH_DOWNLOAD}/${S6_VERSION}/syslogd-overlay-noarch.tar.xz" /tmp/

RUN <<EOF
    set -e
    mkdir /s6-overlay-rootfs /verified
    set -x
    cd   /tmp &&
    for sumfile in *.sha256
    do
        if sha256sum --check --warn --strict "${sumfile}"
        then
            mv -v "${sumfile%.sha256}" "${sumfile}" /verified/
        fi
    done
    tar  -C /s6-overlay-rootfs -Jxpf /verified/syslogd-overlay-noarch.tar.xz
EOF
FROM scratch AS s6-overlay-syslogd
COPY --from=s6-overlay-rootfs-syslogd /s6-overlay-rootfs /


# Default image
# This image is used as a base for other images that require s6-overlay.
FROM s6-overlay


# s6-overlay tarballs
FROM scratch AS tarballs
ARG GH_DOWNLOAD
ARG S6_VERSION
# tarballs
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-aarch64.tar.xz" /s6-overlay-aarch64.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-arm.tar.xz" /s6-overlay-arm.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-armhf.tar.xz" /s6-overlay-armhf.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-i486.tar.xz" /s6-overlay-i486.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-i686.tar.xz" /s6-overlay-i686.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-noarch.tar.xz" /s6-overlay-noarch.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-powerpc64.tar.xz" /s6-overlay-powerpc64.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-powerpc64le.tar.xz" /s6-overlay-powerpc64le.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-riscv64.tar.xz" /s6-overlay-riscv64.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-s390x.tar.xz" /s6-overlay-s390x.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz" /s6-overlay-symlinks-arch.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz" /s6-overlay-symlinks-noarch.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-x86_64.tar.xz" /s6-overlay-x86_64.tar.xz
ADD "${GH_DOWNLOAD}/${S6_VERSION}/syslogd-overlay-noarch.tar.xz" /syslogd-overlay-noarch.tar.xz
# checksums
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-aarch64.tar.xz.sha256" /s6-overlay-aarch64.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-arm.tar.xz.sha256" /s6-overlay-arm.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-armhf.tar.xz.sha256" /s6-overlay-armhf.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-i486.tar.xz.sha256" /s6-overlay-i486.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-i686.tar.xz.sha256" /s6-overlay-i686.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-noarch.tar.xz.sha256" /s6-overlay-noarch.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-powerpc64.tar.xz.sha256" /s6-overlay-powerpc64.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-powerpc64le.tar.xz.sha256" /s6-overlay-powerpc64le.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-riscv64.tar.xz.sha256" /s6-overlay-riscv64.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-s390x.tar.xz.sha256" /s6-overlay-s390x.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz.sha256" /s6-overlay-symlinks-arch.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz.sha256" /s6-overlay-symlinks-noarch.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/s6-overlay-x86_64.tar.xz.sha256" /s6-overlay-x86_64.tar.xz.sha256
ADD "${GH_DOWNLOAD}/${S6_VERSION}/syslogd-overlay-noarch.tar.xz.sha256" /syslogd-overlay-noarch.tar.xz.sha256

FROM internal AS checksums
RUN --mount=type=bind,source=./tarballs,target=/tmp/tarballs <<EOT
    set -e
    cd /tmp/tarballs
    sha256sum --check --warn --strict *.sha256
EOT
