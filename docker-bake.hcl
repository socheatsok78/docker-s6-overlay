
variable "S6_VERSION" { default = "v3.2.0.0" }
variable "ALPINE_VERSION" { default = "3.22.0" }

target "docker-metadata-action" {}
target "github-metadata-action" {}

# Download s6-overlay tarballs for local testing.
target "download" {
    output = ["./output"]
    platforms = ["local"]
    target = "download"
}
target "verify" {
    target = "verify"
}

group "default" {
    targets = [
        "s6-overlay",
        "s6-overlay-symlinks",
        "s6-overlay-syslogd",
    ]
}

target "s6-overlay" {
    inherits = [
        "docker-metadata-action",
        "github-metadata-action",
    ]
    target = "s6-overlay"
    args = {
        S6_VERSION = "${S6_VERSION}"
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/riscv64",
        "linux/s390x",
        "linux/386",
        "linux/arm/v7",
        "linux/arm/v6"
    ]
}

target "s6-overlay-symlinks" {
    inherits = [
        "docker-metadata-action",
        "github-metadata-action",
        "s6-overlay"
    ]
    target = "s6-overlay-symlinks"
}

target "s6-overlay-syslogd" {
    inherits = [
        "docker-metadata-action",
        "github-metadata-action",
        "s6-overlay"
    ]
    target = "s6-overlay-syslogd"
}

# The "build" group is used to build locally in the event that CI/CD is not available.
# Or in most cases, it got rate-limited by Docker Hub.
# e.g: S6_VERSION=v3.2.0.0 docker buildx bake build --push
group "build" {
    targets = [
        "build-s6-overlay",
        "build-s6-overlay-symlinks",
        "build-s6-overlay-syslogd",
    ]
}
target "build-s6-overlay" {
    inherits = [ "s6-overlay" ]
    tags = [ 
        "docker.io/socheatsok78/s6-overlay:${S6_VERSION}",
        "ghcr.io/socheatsok78/s6-overlay:${S6_VERSION}",
    ]
}
target "build-s6-overlay-symlinks" {
    inherits = [ "s6-overlay-symlinks" ]
    tags = [ 
        "docker.io/socheatsok78/s6-overlay:${S6_VERSION}-symlinks",
        "ghcr.io/socheatsok78/s6-overlay:${S6_VERSION}-symlinks",
    ]
}
target "build-s6-overlay-syslogd" {
    inherits = [ "s6-overlay-syslogd" ]
    tags = [ 
        "docker.io/socheatsok78/s6-overlay:${S6_VERSION}-syslogd",
        "ghcr.io/socheatsok78/s6-overlay:${S6_VERSION}-syslogd",
    ]
}

# The "local" group is used to build for host platforms, usually for testing purposes.
# e.g: S6_VERSION=v3.2.0.0 docker buildx bake local --load
group "local" {
    targets = [
        "local-s6-overlay",
        "local-s6-overlay-symlinks",
        "local-s6-overlay-syslogd",
    ]
}
target "local-s6-overlay" {
    target = "s6-overlay"
    args = {
        S6_VERSION = "${S6_VERSION}"
    }
    tags = [ "localhost:5000/s6-overlay:${S6_VERSION}"]
}
target "local-s6-overlay-symlinks" {
    inherits = [ "local-s6-overlay" ]
    target = "s6-overlay-symlinks"
    tags = [ "localhost:5000/s6-overlay:${S6_VERSION}-symlinks"]
}
target "local-s6-overlay-syslogd" {
    inherits = [ "local-s6-overlay" ]
    target = "s6-overlay-syslogd"
    tags = [ "localhost:5000/s6-overlay:${S6_VERSION}-syslogd"]
}
