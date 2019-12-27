FROM alpine:3

# Install packages
RUN apk update && \
    apk add --no-cache \
      curl=7.67.0-r0 \
      hugo=0.61.0-r0

USER default
VOLUME /site
WORKDIR /site

# Expose port for live server
EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD ["--help"]
