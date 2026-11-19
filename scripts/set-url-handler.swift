// Usage: swift set-url-handler.swift <path to .app> <scheme>
import AppKit
let args = CommandLine.arguments
guard args.count == 3 else { print("usage: set-url-handler.swift <app> <scheme>"); exit(2) }
let done = DispatchSemaphore(value: 0)
NSWorkspace.shared.setDefaultApplication(at: URL(fileURLWithPath: args[1]), toOpenURLsWithScheme: args[2]) { err in
    print(err.map { "failed: \($0)" } ?? "\(args[2]):// -> \(args[1])"); done.signal()
}
_ = done.wait(timeout: .now() + 30)
