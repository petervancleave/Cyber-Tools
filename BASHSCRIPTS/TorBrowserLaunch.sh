#!/bin/bash
tor &
sleep 5
firefox --proxy-server="socks5://127.0.0.1:9050"


# Launches firefox with Tor Proxy