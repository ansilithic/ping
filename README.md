# ping — advanced ping for macOS

A Swift CLI that wraps the system `ping`, adding timestamps to every response, color-coding successes and failures, and printing a clean packet loss summary on exit.

This isn't your average everyday ping. This is... *advanced ping.*

![ping demo](assets/demo.gif)

## Install

```sh
brew install ansilithic/tap/ping
```

Or build from source:

```sh
swift build -c release
cp .build/release/ping /usr/local/bin/
```

## Usage

```sh
ping google.com
ping 1.1.1.1 -c 5
```

All standard `ping` flags are passed through to the system binary.

## License

MIT
