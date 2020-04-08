# WireGuard Docker Tunnel to SOCKS5 Server

Convers WireGuard connection to SOCKS5 server in Docker. This allows you to have multiple WireGuard to SOCKS5 proxies in different containers and expose to different host ports.

Supports latest Docker for both Windows, Linux, and MacOS.

### Related Projects

-   [wireguard-socks5](https://hub.docker.com/r/curve25519xsalsa20poly1305/wireguard-socks5/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-wireguard-socks5)) - Expose a SOCKS5 proxy server on your host port to serve programs on your host machine that can connect to a WireGuard proxy.
-   [wireguard-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/wireguard-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-wireguard-aria2)) - Extends wireguard-socks5 with aria2 support.
-   [openvpn-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-tunnel)) - Wraps your program with OpenVPN network tunnel fully contained in Docker.
-   [openvpn-socks5](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-socks5/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5)) - Expose a SOCKS5 proxy server on your host port to serve programs on your host machine that can connect to a OpenVPN proxy.
-   [openvpn-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-aria2)) - Extends openvpn-socks5 with aria2 support.
-   [shadowsocks-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks-tunnel)) - Wraps your program with Shadowsocks network tunnel fully contained in Docker. Also exposes SOCKS5 server to host machine.
-   [shadowsocks-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks-aria2)) - Extends `shadowsocks-tunnel` with `aria2` support.
-   [shadowsocksr-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocksr-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocksr-tunnel)) - Wraps your program with ShadowsocksR network tunnel fully contained in Docker. Also exposes SOCKS5 server to host machine.
-   [shadowsocksr-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocksr-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocksr-aria2)) - Extends `shadowsocksr-tunnel` with `aria2` support.

## What it does?

1. It reads in a WireGuard configuration file (`.conf`) from a mounted file, specified through `WIREGUARD_CONFIG` environment variable.
2. If such configuration file is not provided, it will try to generate one in the following steps:
    - If all the following environment variables are set, it will use them to generate a configuration file:
        - `WIREGUARD_INTERFACE_PRIVATE_KEY`
        - `WIREGUARD_INTERFACE_DNS` defaults to `1.1.1.1`
        - `WIREGUARD_INTERFACE_ADDRESS`
        - `WIREGUARD_PEER_PUBLIC_KEY`
        - `WIREGUARD_PEER_ALLOWED_IPS` defaults to `0.0.0.0/0`
        - `WIREGUARD_PEER_ENDPOINT`
    - Otherwise, it will generate a free Cloudflare Warp account and use that as a configuration.
3. It starts the WireGuard client program to establish the VPN connection.
4. It optionally runs the executable defined by `WIREGUARD_UP`` when the VPN connection is stable.
5. It starts the SOCKS5 server and listen on container-scoped port 1080 on default. SOCKS5 authentication can be enabled with `SOCKS5_USER` and `SOCKS5_PASS` environment variables. `SOCKS5_PORT` can be used to change the default port.
6. It optionally runs the executable defined by `SOCKS5_UP` when the SOCKS5 server is ready.
7. It optionally runs the user specified CMD line from `docker run` positional arguments ([see Docker doc](https://docs.docker.com/engine/reference/run/#cmd-default-command-or-options)). The program will use the VPN connection inside the container.
8. If user has provided CMD line, and `DAEMON_MODE` environment variable is not set to `true`, then after running the CMD line, it will shutdown the OpenVPN client and terminate the container.

## Example with Warp

```bash

# Unix
SET NAME="mysocks5"
PORT="7777"
USER="myuser"
PASS="mypass"
docker run --name "${NAME}" -dit --rm \
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged \
    -p "${PORT}":1080 \
    -e SOCKS5_USER="${USER}" \
    -e SOCKS5_PASS="${PASS}" \
    curve25519xsalsa20poly1305/wireguard-socks5 \
    curl ifconfig.me

# Windows
SET NAME="mysocks5"
SET PORT="7777"
SET USER="myuser"
SET PASS="mypass"
docker run --name "%NAME%" -dit --rm ^
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged ^
    -p "%PORT%":1080 ^
    -e SOCKS5_USER="%USER%" ^
    -e SOCKS5_PASS="%PASS%" ^
    curve25519xsalsa20poly1305/wireguard-socks5 ^
    curl ifconfig.me
```

Then on your host machine test it with curl:

```bash
# Unix & Windows
curl ifconfig.me -x socks5h://myuser:mypass@127.0.0.1:7777
```

To stop the daemon, run this:

```bash
# Unix
NAME="mysocks5"
docker stop "${NAME}"

# Windows
SET NAME="mysocks5"
docker stop "%NAME%"
```

### Example with Config File

Prepare a WireGuard configuration at `./wg.conf`. NOTE: DO NOT use IPv6 related configs as they may not be supported in Docker.

```bash
# Unix
docker run -it --rm \
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged \
    -v "${PWD}":/vpn:ro -e WIREGUARD_CONFIG=/vpn/wg.conf \
    curve25519xsalsa20poly1305/wireguard-socks5 \
    curl ifconfig.me

# Windows
docker run -it --rm ^
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged ^
    -v "%CD%":/vpn:ro -e WIREGUARD_CONFIG=/vpn/wg.conf ^
    curve25519xsalsa20poly1305/wireguard-socks5 ^
    curl ifconfig.me
```

## Contributing

Please feel free to contribute to this project. But before you do so, just make
sure you understand the following:

1\. Make sure you have access to the official repository of this project where
the maintainer is actively pushing changes. So that all effective changes can go
into the official release pipeline.

2\. Make sure your editor has [EditorConfig](https://editorconfig.org/) plugin
installed and enabled. It's used to unify code formatting style.

3\. Use [Conventional Commits 1.0.0-beta.2](https://conventionalcommits.org/) to
format Git commit messages.

4\. Use [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
as Git workflow guideline.

5\. Use [Semantic Versioning 2.0.0](https://semver.org/) to tag release
versions.

## License

Copyright © 2019 curve25519xsalsa20poly1305 &lt;<curve25519xsalsa20poly1305@gmail.com>&gt;

This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.
