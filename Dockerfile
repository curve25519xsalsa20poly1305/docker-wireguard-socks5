FROM golang:alpine as builder
WORKDIR /go/src
COPY warp.go ./warp/
COPY socks5.go ./socks5/
RUN CGO_ENABLED=0 GOOS=linux \
    apk add --no-cache git build-base && \
    cd warp && \
    go get && \
    go build -a -installsuffix cgo -ldflags '-s' -o warp && \
    cd ../socks5 && \
    go get && \
    go build -a -installsuffix cgo -ldflags '-s' -o socks5

FROM alpine:latest

COPY --from=builder /go/src/warp/warp /usr/local/bin/
COPY --from=builder /go/src/socks5/socks5 /usr/local/bin/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY entrypoint.sh   /usr/local/bin/

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --no-cache bash curl wget wireguard-tools openresolv ip6tables \
    && chmod +x /usr/local/bin/entrypoint.sh

ENV         DAEMON_MODE                     false
ENV         SOCKS5_UP                       ""
ENV         SOCKS5_PORT                     "1080"
ENV         SOCKS5_USER                     ""
ENV         SOCKS5_PASS                     ""
ENV         WIREGUARD_UP                    ""
ENV         WIREGUARD_CONFIG                ""
ENV         WIREGUARD_INTERFACE_PRIVATE_KEY ""
ENV         WIREGUARD_INTERFACE_DNS         "1.1.1.1"
ENV         WIREGUARD_INTERFACE_ADDRESS     ""
ENV         WIREGUARD_PEER_PUBLIC_KEY       ""
ENV         WIREGUARD_PEER_ALLOWED_IPS      "0.0.0.0/0"
ENV         WIREGUARD_PEER_ENDPOINT         ""

ENTRYPOINT  [ "entrypoint.sh" ]
