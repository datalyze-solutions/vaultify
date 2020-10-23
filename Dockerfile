FROM golang:latest as build

RUN apt-get update && \
    apt-get install -y upx-ucl && \
    rm -rf /var/lib/apt/lists/*
ADD ./ /src
WORKDIR /src
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