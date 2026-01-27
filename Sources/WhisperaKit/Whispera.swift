import Foundation

/// WhisperaKit - Convert natural language to macOS bash commands
///
/// Usage:
/// ```swift
/// let whispera = Whispera()
/// try await whispera.loadModel { progress in
///     print("Loading: \(Int(progress * 100))%")
/// }
/// let command = try await whispera.process("open chrome")
/// print(command)  // open -a "Google Chrome"
/// ```
public class Whispera {
    private let modelLoader: ModelLoader
    private let commandParser: CommandParser

    /// Initialize Whispera with optional custom model ID
    /// - Parameter modelId: Hugging Face model ID (default: ismatulla/whispera-voice-commands)
    public init(modelId: String = ModelLoader.defaultModelId) {
        self.modelLoader = ModelLoader(modelId: modelId)
        self.commandParser = CommandParser()
    }

    /// Check if the model is loaded and ready
    public var isReady: Bool {
        modelLoader.isLoaded
    }

    /// Load the model from Hugging Face
    /// Downloads on first run, cached afterwards
    /// - Parameter progress: Optional progress callback (0.0 to 1.0)
    public func loadModel(progress: ((Double) -> Void)? = nil) async throws {
        try await modelLoader.load(progress: progress)
    }

    /// Convert natural language input to a bash command
    /// - Parameter input: Natural language command (e.g., "open chrome")
    /// - Returns: Executable bash command (e.g., `open -a "Google Chrome"`)
    public func process(_ input: String) async throws -> String {
        guard modelLoader.isLoaded else {
            throw WhisperaError.modelNotLoaded
        }

        let modelOutput = try await modelLoader.generate(prompt: input)

        guard let jsonString = modelLoader.extractJSON(from: modelOutput) else {
            throw WhisperaError.inferenceError("Could not extract JSON from model output: \(modelOutput)")
        }

        return try commandParser.parse(jsonString: jsonString)
    }

    /// Convert and execute a natural language command
    /// - Parameter input: Natural language command
    /// - Returns: The bash command that was executed
    @discardableResult
    public func execute(_ input: String) async throws -> String {
        let command = try await process(input)

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        return command
    }
}
