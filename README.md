# ping — enhanced ping for macOS

A Swift CLI that wraps the system `ping`, adding timestamps to every response, color-coding successes and failures, and printing a clean packet loss summary on exit.

## Install

```sh
swift build -c release
cp .build/release/ping ~/.local/bin/
```

Or with Make:

```sh
make build install
```

## Usage

```sh
ping google.com
ping 1.1.1.1 -c 5
```

Output:

```
PING google.com (142.250.80.46): 56 data bytes
2026-02-21 14:32:01 64 bytes from 142.250.80.46: icmp_seq=0 ttl=117 time=12.3 ms
2026-02-21 14:32:02 64 bytes from 142.250.80.46: icmp_seq=1 ttl=117 time=11.8 ms
^C
---
Sent: 2, Received: 2, Lost: 0 (0% loss)
```

All standard `ping` flags are passed through to the system binary.

## Requirements

- macOS 14+ (Sonoma)
- Swift 6.0

## License

MIT
