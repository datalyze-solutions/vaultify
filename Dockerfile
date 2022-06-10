# FROM golang:latest as base
FROM golang:latest as build

# FROM base AS base-arm64
# RUN ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
#     ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
#     ln -s /bin/rm /usr/sbin/rm  && \
#     ln -s /bin/tar /usr/sbin/tar

# FROM base AS base-amd64

# ARG TARGETARCH
# FROM base-${TARGETARCH} AS build

ENV SRC_DIR="/src"
# symlinks needed for arm64 builds
RUN apt-get update && \
    apt-get install -y apt-utils upx-ucl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${SRC_DIR}"
WORKDIR "${SRC_DIR}"

# just build deps
COPY go.mod .
COPY go.sum .
# RUN go get ./...
RUN go mod download

# add source code
ADD ./ "${SRC_DIR}"
# passed via --platform arg

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS
ARG TARGETVARIANT

ENV BIN_DIR="/src/bin/"
RUN make build compress

FROM scratch
ENV BIN_DIR="/opt/vaultify" \
    VAULTIFY_SOURCE_BIN="/vaultify" \
    VAULTIFY_TARGET_BIN="${BIN_DIR}/vaultify"
COPY --from=build /src/bin/vaultify "${VAULTIFY_SOURCE_BIN}"
ENTRYPOINT [ "/vaultify" ]
CMD ["copy", "/opt/vaultify/"]