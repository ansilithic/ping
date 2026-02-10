import ArgumentParser
import CLICore
import Foundation

// Track stats globally so the signal handler can access them
nonisolated(unsafe) var sent = 0
nonisolated(unsafe) var received = 0
nonisolated(unsafe) var cleanedUp = false

@main
struct Ping: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ping",
        abstract: "Ping with timestamps and color-coded output.",
        discussion: "Shadows /sbin/ping, adding timestamps, color, and summary stats.",
        version: "1.0.0"
    )

    @Argument(parsing: .captureForPassthrough)
    var args: [String]

    func run() throws {
        guard !args.isEmpty else {
            print("Usage: ping <target> [ping options]")
            print("Example: ping google.com -c 10")
            throw ExitCode.failure
        }

        // Find system ping
        let systemPing: String
        if FileManager.default.isExecutableFile(atPath: "/sbin/ping") {
            systemPing = "/sbin/ping"
        } else if FileManager.default.isExecutableFile(atPath: "/bin/ping") {
            systemPing = "/bin/ping"
        } else {
            fputs("Error: system ping not found\n", stderr)
            throw ExitCode.failure
        }

        // Install signal handler for summary on Ctrl-C
        signal(SIGINT) { _ in
            printSummary()
            _exit(0)
        }
        signal(SIGTERM) { _ in
            printSummary()
            _exit(0)
        }

        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: systemPing)
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil

        do {
            try task.run()
        } catch {
            fputs("Error: failed to launch ping\n", stderr)
            throw ExitCode.failure
        }

        let handle = pipe.fileHandleForReading
        var buffer = Data()

        while task.isRunning || handle.availableData.count > 0 {
            let data = handle.availableData
            guard !data.isEmpty else { break }
            buffer.append(data)

            // Process complete lines
            while let newlineRange = buffer.range(of: Data([0x0A])) {
                let lineData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
                buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)

                guard let line = String(data: lineData, encoding: .utf8) else { continue }
                processLine(line)
            }
        }

        // Process any remaining data
        if !buffer.isEmpty, let line = String(data: buffer, encoding: .utf8), !line.isEmpty {
            processLine(line)
        }

        task.waitUntilExit()
        printSummary()
    }

    private func processLine(_ line: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())

        if line.contains("bytes from") {
            sent += 1
            received += 1
            print("\(styled(timestamp, .dim)) \(styled(line, .green))")
        } else if line.contains("timeout") || line.contains("Timeout") || line.contains("Request timeout") {
            sent += 1
            print("\(styled(timestamp, .dim)) \(styled(line, .red))")
        } else if line.contains("Destination Host Unreachable") || line.contains("Network is unreachable") || line.contains("No route to host") {
            sent += 1
            print("\(styled(timestamp, .dim)) \(styled(line, .red))")
        } else if line.contains("unknown host") || line.contains("cannot resolve") {
            print("\(styled(timestamp, .dim)) \(styled(line, .red))")
        } else if line.hasPrefix("PING ") {
            print(styled(line, .dim))
        } else if line.contains("ping statistics") || line.contains("packets transmitted") || line.contains("round-trip") || line.contains("rtt") {
            // Skip system summary lines — we print our own
            return
        } else if line.isEmpty || line.hasPrefix("---") {
            return
        } else {
            print("\(styled(timestamp, .dim)) \(line)")
        }
    }
}

private func printSummary() {
    guard !cleanedUp else { return }
    cleanedUp = true

    guard sent > 0 else { return }

    let lost = sent - received
    let lossPct = lost * 100 / sent

    print()
    print(styled("---", .dim))
    print(styled("Sent: \(sent), Received: \(received), Lost: \(lost) (\(lossPct)% loss)", .dim))
}
