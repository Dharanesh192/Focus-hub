### About Saily

**Saily** is a voice-controlled desktop based assistant, its built as a project for college activity to include neural-network classification.

Started as a demmo project with whisperflow for (speech to text) and pyttsx3 for (text to speech). Turns into a voice assistance to run (system command, file operation, web activity) and AI features by using Gemini API  

This project demonstrates how a voice assistant can:
- Execute known commands instantly through a local, deterministic pipeline
- Fall back to an LLM (Gemini) to interpret unfamiliar or loosely-worded requests
- For the Voice and speech recognition the browser's voice engine is used  
- Stay as modular (classification, intent discovery, and execution are separate components)

Instead of routing every request through an AI model, Saily classifies known commands locally and only calls out to Gemini when a request doesn't match anything in its known vocabulary — making it **fast for known commands** and **flexible for unfamiliar ones**.

---


### Current status

**Saily is under development** as this project doesn't obtain its full potential. Right now its 90% rule based execution and remaining comes under the decision making by NN and handling uncertainty by Gemini's API call. In this project I want to create my own NLM for handling uncertainty, decision making, executing commands and finally having a memory with personality

---

### Tech Stack

- **Command Understanding:** Local Neural Network (NN) classifier for known commands
- **AI Fallback:** Gemini (intent/function discovery for unknown requests)
- **Speech Input/Output:** Speech-to-text (Browser's default engine)
- **Execution Layer:** Local command handlers mapped to OS-level actions
- **Python libraraies:** faster-whisper, sounddevice, scipy, tavily-python, google-generativeai, google-genai, Subprocess
- **Core Concept:** Hybrid local-classification + AI-fallback architecture

---

### Project Overview

This project focuses on building a **hybrid voice assistant** — one that doesn't depend on an AI model for every single request.

The system connects:
- **Local command dictionaries** (`system_commands`, `create_command`, `Application`) — the canonical, controlled vocabulary the NN is trained to recognize
- **Neural Network classifier** — matches spoken/transcribed input to a known command
- **Gemini** — steps in only when the input doesn't match any known command, to determine user intent

The flow acts as a bridge between:

```
Voice Input ⇄ Speech-to-Text ⇄ Command Classifier (NN) ⇄ Local Handler / Gemini Fallback ⇄ OS Action
```

Main objectives of this project:
- Understand intent classification vs. open-ended LLM understanding
- Learn how to keep AI "in the loop" without giving it direct execution power
- Build a controlled, extensible command vocabulary
- Explore where local models are enough vs. where an LLM fallback adds real value

---

### Features

- 🖥️ **System controls** — restart, lock, sleep, get IP address, hostname, system info
- 📂 **Application control** — open VS Code, Terminal, calculator, Notepad, Task Manager (dictionary-driven, not freely generated)
- 📁 **File operations** — create, read/open, copy, move/rename (delete intentionally excluded)
- 🌍 **Web** — open websites and do web search by (Tavily API)
- 💻 **Programming execution** — run code in Python, C, C++, Java, JavaScript and other's by Gemini
- 🤖 **Gemini fallback** — handles anything outside the known command vocabulary
- 🔒 **No arbitrary AI-generated shell commands** — AI identifies intent only; execution is handled by validated local code

---

### Requirements

- Python for executing command and full backend process
- Gemini API (API key) for fallback intent discovery
- Tavily API for web search results
- A Dataset to train your ANN for making decisions

---

### Project Structure
 
```
Saily/
├── backend/
│   ├── Actions/            # Local command handlers (executes validated logical actions)
│   ├── Decision/           # Command classification / routing logic (NN vs Gemini)
│   ├── Memory/             # State / context handling
│   ├── Speech/             # Speech-to-text and voice input handling
│   ├── __init__.py
│   ├── main.py              # Backend entry point
│   └── requirements.txt
├── frontend/                # Frontend/UI layer
├── .gitignore
├── README.md
└── saily_nn_dataset_v7.csv  # Training data for the NN command classifier
```

---

### What is the Hybrid Command Architecture?

- Think of the **local NN classifier** as your **fast path**, and **Gemini** as the **fallback path** for anything unfamiliar
- Every voice command is first checked against known dictionaries (`system_commands`, `create_command`, `Application`)
- If it matches, the NN classifies it and a **local handler** executes it directly — no AI model call needed
- If it doesn't match, the request is routed to **Gemini** to determine the user's intended function
- The AI never directly issues OS commands — it identifies intent, and Saily's local code maps that intent to an approved implementation

---

### Safety and Command Control

A core design decision in Saily is that the AI model should **not be trusted to generate arbitrary shell commands and execute them directly**.

**What this means in practice:**
- The NN/Gemini layer only ever outputs a **logical action** (e.g. `RESTART`), never a raw shell command
- Saily's local handler is the only thing that decides *how* that logical action maps to a real OS operation
- Destructive operations (like file deletion) are intentionally excluded from the current command scope
- Programming-code execution is flagged as needing proper sandboxing before being treated as unrestricted execution

**Example:**
```
User: "Restart my computer"
NN: RESTART
Local handler: RESTART → OS-specific restart operation
```

This separation — AI identifies intent, local code controls execution — is what keeps the system testable and safe to extend.

---

### System Architecture

```
        Voice Input
              ⇅
        Speech-to-Text
              ⇅
     Command Classifier (NN)
        ⇅            ⇅
  Local Handler     Gemini (fallback)
        ⇅            ⇅
         Operating System
```

---

### How It Works

1️⃣ User speaks a command → converted to text by the speech-to-text layer

2️⃣ The text is checked against known command dictionaries (`system_commands`, `create_command`, `Application`)

3️⃣ If it's a known pattern, the **NN classifier** matches it to a logical action (e.g. `OPEN_VSCODE`) → the **local handler** executes it directly

4️⃣ If it's not recognized, the request is routed to **Gemini** to discover the user's intended function

5️⃣ Gemini's output is treated as an intent, not a command — it's mapped to a **validated local function**, never executed as raw code

6️⃣ The local handler performs the OS-level action and Saily responds to the user
