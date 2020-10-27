FROM golang:latest as build

ENV SRC_DIR="/src"
RUN apt-get update && \
    apt-get install -y upx-ucl && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p "${SRC_DIR}"
WORKDIR "${SRC_DIR}"

# add source code
ADD ./ "${SRC_DIR}"
RUN make deps
RUN make build compress

FROM busybox
ENV BIN_DIR="/opt/vaultify" \
    VAULTIFY_SOURCE_BIN="/vaultify" \
    VAULTIFY_TARGET_BIN="${BIN_DIR}/vaultify"
RUN mkdir -p "${BIN_DIR}"
COPY --from=build /src/bin/vaultify "${VAULTIFY_SOURCE_BIN}"
# ADD ./bin/vaultify "${VAULTIFY_SOURCE_BIN}"
VOLUME [ "/opt/vaultify" ]
# take care to update vaultify in the volume
CMD cp "${VAULTIFY_SOURCE_BIN}" /opt/vaultify/vaultify