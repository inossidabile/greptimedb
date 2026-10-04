FROM ubuntu:22.04@sha256:5ec03bb3441e8b0bf3b4f9cd4629a1ae763010dc3035bb8da3ae6cf026486401

# The root path under which contains all the dependencies to build this Dockerfile.
ARG DOCKER_BUILD_ROOT=.
# The binary name of GreptimeDB executable.
# Defaults to "greptime", but sometimes in other projects it might be different.
ARG TARGET_BIN=greptime

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl

ARG TARGETARCH

ADD $TARGETARCH/$TARGET_BIN /greptime/bin/

ENV PATH=/greptime/bin/:$PATH

ENV TARGET_BIN=$TARGET_BIN

ENV MALLOC_CONF="prof:true,prof_active:false"

ENTRYPOINT ["sh", "-c", "exec $TARGET_BIN \"$@\"", "--"]
