ARG S6_VERSION=v3.2.0.0
FROM socheatsok78/s6-overlay:${S6_VERSION} AS s6-overlay
FROM socheatsok78/s6-overlay:${S6_VERSION}-symlinks AS s6-overlay-symlinks
FROM socheatsok78/s6-overlay:${S6_VERSION}-syslogd AS s6-overlay-syslogd

# This is your final image
FROM alpine:latest

# Overlay the s6-overlay files to the root filesystem
# The order of this is up to you, but generally, you want to copy the main s6-overlay first,
# followed by symlinks and syslogd if needed.
COPY --link --from=s6-overlay / /
COPY --link --from=s6-overlay-symlinks / /
COPY --link --from=s6-overlay-syslogd / /
ENTRYPOINT [ "/init" ]
CMD [ "/bin/sh" ]

# Add any additional packages or configurations you need here
