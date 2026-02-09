# WhisperaKit

A Swift package for converting natural language to macOS bash commands using a fine-tuned LLM.

## Features

- **Library**: Import `WhisperaKit` in your Swift apps to add voice command functionality
- **CLI**: Use the `whispera` command-line tool directly in your terminal
- **Hugging Face Integration**: Model automatically downloads from Hugging Face on first run

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)
- Xcode 15.0+ (for building)

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sapoepsilon/WhisperaKit", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["WhisperaKit"]
)
```

### Build from Source

```bash
git clone https://github.com/sapoepsilon/WhisperaKit
cd WhisperaKit
xcodebuild -scheme whispera -destination 'platform=macOS' -configuration Release build
cp ~/Library/Developer/Xcode/DerivedData/WhisperaKit-*/Build/Products/Release/whispera /usr/local/bin/
```

## Usage

### As a Library

```swift
import WhisperaKit

let whispera = Whispera()

// Load model (downloads from Hugging Face on first run)
try await whispera.loadModel { progress in
    print("Loading: \(Int(progress * 100))%")
}

// Convert natural language to bash
let command = try await whispera.process("open chrome")
print(command)  // open -a "Google Chrome"

// Or execute directly
try await whispera.execute("set volume to 50")
```

### CLI Tool

```bash
# Convert command
whispera "open safari"              # → open -a "Safari"

# Execute immediately
whispera -x "open chrome"           # Opens Chrome

# Interactive mode
whispera -i                         # REPL mode

# Verbose output
whispera -v "git status"            # Shows progress
```

## Supported Commands

| Category | Examples |
|----------|----------|
| **Apps** | "open chrome", "quit safari", "hide slack" |
| **Volume** | "set volume to 50", "mute", "volume up" |
| **Git** | "git status", "commit fix bug", "push to main" |
| **Docker** | "docker ps", "stop container", "docker images" |
| **Files** | "list files", "make directory test", "remove file.txt" |
| **System** | "screenshot", "lock screen", "empty trash" |

See [full command list](https://github.com/sapoepsilon/whisperaModel#supported-commands-250).

## Model Download (Default)

WhisperaKit downloads the default model from Hugging Face automatically:

- `sapoepsilon/whispera-voice-commands`

You do not need to upload anything to use WhisperaKit.

## Publishing a Custom Model (Optional)

Only follow this section if you fine-tuned your own model and want to publish it under your own Hugging Face account (e.g. `your-username/your-model`).

### 1. Merge LoRA Adapters

```bash
cd /path/to/whisperaModel
source venv/bin/activate
mlx_lm.fuse --model ./qwen-base --adapter-path ./adapters --save-path ./whispera-merged
```

### 2. Login to Hugging Face

```bash
pip install -U huggingface_hub
hf auth login
```

### 3. Create + Upload Model Repo

```bash
hf repo create your-username/your-model --repo-type model --exist-ok
hf upload your-username/your-model ./whispera-merged . --repo-type model --commit-message "publish merged model"
```

### 4. Update Model ID

Edit `Sources/WhisperaKit/ModelLoader.swift`:

```swift
public static let defaultModelId = "your-username/your-model"
```

## Custom Model

Use a different model by specifying the model ID:

```swift
let whispera = Whispera(modelId: "your-username/your-model")
```

Or via CLI:

```bash
whispera --model-id your-username/your-model "open chrome"
```

## Architecture

```
User Input          Model Output                 Bash Command
─────────────────────────────────────────────────────────────
"open chrome"  →  {"category":"apps",       →  open -a "Google Chrome"
                   "operation":"open",
                   "app":"chrome"}
```

1. **Input**: Natural language command
2. **Model**: Fine-tuned Qwen 0.5B outputs structured JSON
3. **Parser**: Looks up template in `macos_operations.json`
4. **Output**: Executable bash command

## Project Structure

```
WhisperaKit/
├── Package.swift
├── Sources/
│   ├── WhisperaKit/           # Library
│   │   ├── Whispera.swift     # Public API
│   │   ├── ModelLoader.swift  # HF download
│   │   ├── CommandParser.swift
│   │   └── Resources/
│   │       └── macos_operations.json
│   └── whispera/              # CLI
│       └── main.swift
└── Tests/
```

## License

MIT
