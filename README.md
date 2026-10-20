# 📡 linux-dual-wifi

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-orange.svg)](https://kernel.org)
[![Shell: Bash](https://img.shields.io/badge/shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

> **Lightweight, zero-dependency Multi-WAN & Dual Wi-Fi ECMP Load Balancer for Linux.**  
> Aggregates two concurrent Wi-Fi adapters (e.g. internal PCIe + external USB Wi-Fi dongle) for combined bandwidth, redundant fallback, and flow-balanced multi-path throughput.

---

## 🧐 The Problem: Why Connecting 2 Wi-Fi Adapters Normally Fails

When connecting two Wi-Fi adapters to a standard Linux desktop:
1. **Default Route Overwrite:** The network manager assigns a lower metric to one adapter and ignores the other, sending 100% of traffic over a single interface.
2. **ARP Flux:** Both interfaces may receive ARP requests on the same subnet, causing the kernel to answer ARP on the wrong interface, resulting in dropped packets and broken TCP connections.
3. **Reverse Path Filtering (rp_filter):** Packets received on adapter B with an IP route matching adapter A are silently discarded by kernel anti-spoofing filters.
4. **USB Adapter Power Sleep:** Many USB Wi-Fi adapters (e.g., Realtek, MediaTek) enter aggressive power savings and disconnect when idle.

---

## ⚡ The Solution: `linux-dual-wifi` Architecture

`linux-dual-wifi` solves this cleanly at the Linux kernel networking layer:
- **ARP Flux Mitigation:** Enforces `arp_ignore=1` and `arp_announce=2` across all network devices.
- **Loose RP Filtering:** Sets `rp_filter=2` so multi-homed packets are properly routed rather than dropped.
- **Layer 4 Flow Hashing:** Configures `fib_multipath_hash_policy=1` to distribute TCP and UDP connections evenly across both Wi-Fi interfaces based on IP and port tuples.
- **Policy Routing:** Configures separate kernel routing tables (`table 100` and `table 200`) with source-based `ip rule` entries to guarantee outgoing response packets exit via the same interface that received them.
- **Equal-Cost Multi-Path (ECMP):** Generates an equal-weight nexthop default route:
  ```bash
  ip route replace default scope global \
      nexthop via $GW1 dev $IF1 weight 1 \
      nexthop via $GW2 dev $IF2 weight 1
  ```
- **Keepalive Daemon:** Pings the secondary gateway periodically to keep USB dongles awake without draining bandwidth.

---

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/apravint/linux-dual-wifi.git
cd linux-dual-wifi
./install.sh
```

### Usage

```bash
# Check status of both adapters, SSIDs, and active default route
dual-wifi status

# Activate ECMP load balancing across both Wi-Fi adapters
dual-wifi balance

# Manually specify interfaces if you have 3+ adapters
dual-wifi --if1 wlp4s0 --if2 wlx503eaaec4cdb balance

# Revert to standard single-interface routing
dual-wifi clean
```

---

## 🛠️ Systemd Daemon Setup

To keep secondary Wi-Fi adapters awake permanently in the background:

```bash
# User service:
systemctl --user enable --now dual-wifi-keepalive.service

# Or system-wide service:
sudo systemctl enable --now dual-wifi-keepalive.service
```

---

## 📊 Verification & Benchmarking

Verify that traffic flows across both adapters simultaneously:

```bash
# Watch live traffic on both interfaces simultaneously
watch -n 1 "ip -s link show wlp4s0; echo ''; ip -s link show wlx503eaaec4cdb"
```

Or run multi-threaded downloads (e.g., `aria2c -x 16 <url>`) to observe concurrent throughput across both adapters.

---

## 📄 License

MIT License. Designed and maintained by [apravint](https://github.com/apravint).
