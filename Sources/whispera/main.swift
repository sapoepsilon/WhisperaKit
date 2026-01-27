import ArgumentParser
import WhisperaKit
import Foundation

struct WhisperaCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "whispera",
        abstract: "Convert natural language to macOS bash commands",
        usage: """
            whispera "open chrome"
            whispera -x "open chrome"
            whispera -i
            """,
        version: "1.0.0"
    )

    @Argument(help: "Natural language command to convert")
    var command: String?

    @Flag(name: .shortAndLong, help: "Execute the command after conversion")
    var execute = false

    @Flag(name: .shortAndLong, help: "Interactive mode")
    var interactive = false

    @Flag(name: .shortAndLong, help: "Show verbose output")
    var verbose = false

    @Option(name: .long, help: "Custom Hugging Face model ID")
    var modelId: String = ModelLoader.defaultModelId

    mutating func run() async throws {
        let whispera = Whispera(modelId: modelId)
        let showProgress = verbose

        print("Loading model...")
        try await whispera.loadModel { progress in
            if showProgress {
                print("\rProgress: \(Int(progress * 100))%", terminator: "")
                fflush(stdout)
            }
        }
        if showProgress { print() }
        print("Model loaded.\n")

        if interactive {
            try await runInteractiveMode(whispera: whispera)
        } else if let cmd = command {
            try await processCommand(whispera: whispera, input: cmd)
        } else {
            try await runInteractiveMode(whispera: whispera)
        }
    }

    private func processCommand(whispera: Whispera, input: String) async throws {
        if verbose {
            print("Input: \(input)")
        }

        let bashCommand = try await whispera.process(input)
        print(bashCommand)

        if execute {
            if verbose {
                print("Executing...")
            }
            try await whispera.execute(input)
        }
    }

    private func runInteractiveMode(whispera: Whispera) async throws {
        print("Whispera CLI - Type commands or 'quit' to exit")
        print("Prefix with '!' to execute immediately\n")

        while true {
            print(">>> ", terminator: "")
            fflush(stdout)

            guard let line = readLine()?.trimmingCharacters(in: .whitespaces) else {
                print("\nBye!")
                break
            }

            if line.isEmpty { continue }

            if ["quit", "exit", "q"].contains(line.lowercased()) {
                print("Bye!")
                break
            }

            var input = line
            var shouldExecute = false

            if input.hasPrefix("!") {
                shouldExecute = true
                input = String(input.dropFirst()).trimmingCharacters(in: .whitespaces)
            }

            do {
                let bashCommand = try await whispera.process(input)

                if shouldExecute {
                    try await whispera.execute(input)
                    print("Executed: \(bashCommand)")
                } else {
                    print(bashCommand)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }

            print()
        }
    }
}

WhisperaCLI.main()
