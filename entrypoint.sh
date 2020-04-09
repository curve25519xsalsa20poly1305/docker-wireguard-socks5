#!/usr/bin/env bash

function spawn {
    if [[ -z ${PIDS+x} ]]; then PIDS=(); fi
    "$@" &
    PIDS+=($!)
}

function join {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            wait "${pid}"
        done
    fi
}

function on_kill {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            kill "${pid}" 2> /dev/null
        done
    fi
    kill "${ENTRYPOINT_PID}" 2> /dev/null
}

export ENTRYPOINT_PID="${BASHPID}"

trap "on_kill" EXIT
trap "on_kill" SIGINT

function gen_conf {
    if [[ \
        -n "${WIREGUARD_INTERFACE_PRIVATE_KEY}" && \
        -n "${WIREGUARD_INTERFACE_DNS}" && \
        -n "${WIREGUARD_INTERFACE_ADDRESS}" && \
        -n "${WIREGUARD_PEER_PUBLIC_KEY}" && \
        -n "${WIREGUARD_PEER_ALLOWED_IPS}" && \
        -n "${WIREGUARD_PEER_ENDPOINT}" \
    ]]; then
        cat <<EOF
[Interface]
PrivateKey = ${WIREGUARD_INTERFACE_PRIVATE_KEY}
DNS = ${WIREGUARD_INTERFACE_DNS}
Address = ${WIREGUARD_INTERFACE_ADDRESS}

[Peer]
PublicKey = ${WIREGUARD_PEER_PUBLIC_KEY}
AllowedIPs = ${WIREGUARD_PEER_ALLOWED_IPS}
Endpoint = ${WIREGUARD_PEER_ENDPOINT}
EOF
    else
        echo "# Generating Warp config" 1>&2
        warp
    fi
}

if [ -n "${WIREGUARD_CONFIG}" ]; then
    cp -f "${WIREGUARD_CONFIG}" /etc/wireguard/wg.conf
else
    gen_conf > /etc/wireguard/wg.conf
fi

wg-quick up wg

spawn socks5

SUBNET=$(ip -o -f inet addr show dev eth0 | awk '{print $4}')
IPADDR=$(echo "${SUBNET}" | cut -f1 -d'/')
GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
eval "$(ipcalc -np "${SUBNET}")"

ip -4 rule del not fwmark 51820 table 51820
ip -4 rule del table main suppress_prefixlength 0

ip -4 rule add prio 10 from "${IPADDR}" table 128
ip -4 route add table 128 to "${NETWORK}/${PREFIX}" dev eth0
ip -4 route add table 128 default via "${GATEWAY}"

ip -4 rule add prio 20 not fwmark 51820 table 51820
ip -4 rule add prio 20 table main suppress_prefixlength 0

if [[ -n "${WIREGUARD_UP}" ]]; then
    spawn "${WIREGUARD_UP}" "$@"
elif [[ -n "${SOCKS5_UP}" ]]; then
    spawn "${SOCKS5_UP}" "$@"
elif [[ $# -gt 0 ]]; then
    "$@"
fi

if [[ $# -eq 0 || "${DAEMON_MODE}" == true ]]; then
    join
fi
