FROM ubuntu:22.04@sha256:5ec03bb3441e8b0bf3b4f9cd4629a1ae763010dc3035bb8da3ae6cf026486401 AS libs

ARG TARGETARCH

# Copy required library dependencies based on architecture
# TARGETARCH values: amd64, arm64
# Ubuntu library paths: x86_64-linux-gnu, aarch64-linux-gnu
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        mkdir -p /output/x86_64-linux-gnu && \
        cp /lib/x86_64-linux-gnu/libz.so.1.2.11 /output/x86_64-linux-gnu/libz.so.1; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        mkdir -p /output/aarch64-linux-gnu && \
        cp /lib/aarch64-linux-gnu/libz.so.1.2.11 /output/aarch64-linux-gnu/libz.so.1; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi

FROM gcr.io/distroless/cc-debian12:latest@sha256:e5d81ddde149641e2a9ba55be4545bc125c67de07508b03ba4c22e6eb0ded5aa

# The root path under which contains all the dependencies to build this Dockerfile.
ARG DOCKER_BUILD_ROOT=.
# The binary name of GreptimeDB executable.
# Defaults to "greptime", but sometimes in other projects it might be different.
ARG TARGET_BIN=greptime

ARG TARGETARCH

# Copy required library dependencies
COPY --from=libs /output /lib
COPY --from=busybox:stable@sha256:73aaf090f3d85aa34ee199857f03fa3a95c8ede2ffd4cc2cdb5b94e566b11662 /bin/busybox /bin/busybox

ADD $TARGETARCH/$TARGET_BIN /greptime/bin/

ENV PATH=/greptime/bin/:$PATH

ENV TARGET_BIN=$TARGET_BIN

ENV MALLOC_CONF="prof:true,prof_active:false"

ENTRYPOINT ["greptime"]
