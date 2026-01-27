import Foundation
import MLXLLM
import MLXLMCommon

public class ModelLoader {
    public static let defaultModelId = "sapoepsilon/whispera-voice-commands"

    private var modelContainer: ModelContainer?
    private let modelId: String

    public var isLoaded: Bool {
        modelContainer != nil
    }

    public init(modelId: String = defaultModelId) {
        self.modelId = modelId
    }

    public func load(progress: ((Double) -> Void)? = nil) async throws {
        let config = ModelConfiguration(id: modelId)

        modelContainer = try await LLMModelFactory.shared.loadContainer(
            configuration: config
        ) { prog in
            progress?(prog.fractionCompleted)
        }
    }

    public func generate(prompt: String, maxTokens: Int = 100) async throws -> String {
        guard let container = modelContainer else {
            throw WhisperaError.modelNotLoaded
        }

        let result = try await container.perform { context in
            let input = try await context.processor.prepare(input: .init(prompt: prompt))

            var generatedText = ""
            let _ = try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(maxTokens: maxTokens),
                context: context
            ) { tokens in
                generatedText = context.tokenizer.decode(tokens: tokens)
                return .more
            }

            return generatedText
        }

        return result
    }

    public func extractJSON(from output: String) -> String? {
        if let start = output.firstIndex(of: "{"),
           let end = output.lastIndex(of: "}") {
            return String(output[start...end])
        }
        return nil
    }
}
