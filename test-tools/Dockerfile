FROM cgr.dev/chainguard/wolfi-base:latest
RUN apk update && apk add --no-cache curl jq && rm -rf /var/cache/apk/*
USER 65532
ENTRYPOINT ["/bin/sh"]
