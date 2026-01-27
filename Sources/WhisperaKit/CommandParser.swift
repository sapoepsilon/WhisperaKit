import Foundation

public struct OperationsConfig: Codable {
    let categories: [String: [String: String]]
    let nlpPatterns: [String: [String: [String]]]?
    let sampleValues: [String: [String]]?

    enum CodingKeys: String, CodingKey {
        case categories
        case nlpPatterns = "nlp_patterns"
        case sampleValues = "sample_values"
    }
}

public struct ModelOutput: Codable {
    let category: String
    let operation: String

    private let additionalParams: [String: String]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var params: [String: String] = [:]
        var cat = ""
        var op = ""

        for key in container.allKeys {
            if key.stringValue == "category" {
                cat = try container.decode(String.self, forKey: key)
            } else if key.stringValue == "operation" {
                op = try container.decode(String.self, forKey: key)
            } else {
                if let value = try? container.decode(String.self, forKey: key) {
                    params[key.stringValue] = value
                } else if let intValue = try? container.decode(Int.self, forKey: key) {
                    params[key.stringValue] = String(intValue)
                }
            }
        }

        self.category = cat
        self.operation = op
        self.additionalParams = params
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(category, forKey: DynamicCodingKeys(stringValue: "category")!)
        try container.encode(operation, forKey: DynamicCodingKeys(stringValue: "operation")!)
        for (key, value) in additionalParams {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }

    public func param(_ name: String) -> String? {
        additionalParams[name]
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

public class CommandParser {
    private var operationsConfig: OperationsConfig?
    private var appMappings: [String: String] = [:]

    public init() {
        loadConfig()
        loadDefaultAppMappings()
    }

    private func loadConfig() {
        guard let url = Bundle.module.url(forResource: "macos_operations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Warning: Could not load macos_operations.json from bundle")
            return
        }

        do {
            operationsConfig = try JSONDecoder().decode(OperationsConfig.self, from: data)
        } catch {
            print("Warning: Could not parse macos_operations.json: \(error)")
        }
    }

    private func loadDefaultAppMappings() {
        appMappings = [
            "chrome": "Google Chrome",
            "safari": "Safari",
            "firefox": "Firefox",
            "slack": "Slack",
            "discord": "Discord",
            "spotify": "Spotify",
            "terminal": "Terminal",
            "iterm": "iTerm",
            "vscode": "Visual Studio Code",
            "code": "Visual Studio Code",
            "xcode": "Xcode",
            "finder": "Finder",
            "notes": "Notes",
            "messages": "Messages",
            "mail": "Mail",
            "calendar": "Calendar",
            "photos": "Photos",
            "music": "Music",
            "podcasts": "Podcasts",
            "tv": "TV",
            "news": "News",
            "books": "Books",
            "maps": "Maps",
            "facetime": "FaceTime",
            "preview": "Preview",
            "textedit": "TextEdit",
            "calculator": "Calculator",
            "activity monitor": "Activity Monitor",
            "system preferences": "System Preferences",
            "system settings": "System Settings",
            "app store": "App Store",
            "notion": "Notion",
            "figma": "Figma",
            "postman": "Postman",
            "docker": "Docker",
            "zoom": "zoom.us",
            "teams": "Microsoft Teams",
            "outlook": "Microsoft Outlook",
            "word": "Microsoft Word",
            "excel": "Microsoft Excel",
            "powerpoint": "Microsoft PowerPoint"
        ]
    }

    public func parse(jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw WhisperaError.invalidJSON("Could not convert string to data")
        }

        let output = try JSONDecoder().decode(ModelOutput.self, from: data)
        return try convertToCommand(output)
    }

    private func convertToCommand(_ output: ModelOutput) throws -> String {
        guard let config = operationsConfig else {
            throw WhisperaError.configNotLoaded
        }

        guard let categoryOps = config.categories[output.category] else {
            throw WhisperaError.unknownCategory(output.category)
        }

        guard let template = categoryOps[output.operation] else {
            throw WhisperaError.unknownOperation(output.operation, category: output.category)
        }

        var result = template
        let paramPattern = try NSRegularExpression(pattern: "\\{(\\w+)\\}")
        let matches = paramPattern.matches(in: template, range: NSRange(template.startIndex..., in: template))

        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: template) else { continue }
            let paramName = String(template[range])

            let value: String
            if let paramValue = output.param(paramName) {
                value = transformParam(name: paramName, value: paramValue)
            } else {
                value = "<missing:\(paramName)>"
            }

            if let fullRange = Range(match.range, in: result) {
                result.replaceSubrange(fullRange, with: value)
            }
        }

        return result
    }

    private func transformParam(name: String, value: String) -> String {
        switch name {
        case "app":
            return appMappings[value.lowercased()] ?? value.capitalized
        case "level":
            let cleaned = value.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces).lowercased()
            switch cleaned {
            case "half": return "50"
            case "max", "maximum", "full": return "100"
            case "min", "minimum": return "0"
            default:
                if let intValue = Int(cleaned) {
                    return String(max(0, min(100, intValue)))
                }
                return "50"
            }
        case "folder":
            let knownFolders = ["downloads": "~/Downloads", "documents": "~/Documents", "desktop": "~/Desktop"]
            return knownFolders[value.lowercased()] ?? "~/\(value)"
        default:
            return value
        }
    }
}

public enum WhisperaError: Error, LocalizedError {
    case configNotLoaded
    case invalidJSON(String)
    case unknownCategory(String)
    case unknownOperation(String, category: String)
    case modelNotLoaded
    case inferenceError(String)

    public var errorDescription: String? {
        switch self {
        case .configNotLoaded:
            return "Operations config not loaded"
        case .invalidJSON(let msg):
            return "Invalid JSON: \(msg)"
        case .unknownCategory(let cat):
            return "Unknown category: \(cat)"
        case .unknownOperation(let op, let cat):
            return "Unknown operation '\(op)' in category '\(cat)'"
        case .modelNotLoaded:
            return "Model not loaded. Call loadModel() first."
        case .inferenceError(let msg):
            return "Inference error: \(msg)"
        }
    }
}
