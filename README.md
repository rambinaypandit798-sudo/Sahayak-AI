<div align="center">

# 🏛️ SAHAYAK AI
### *Intelligent Civic & Student Assistant Platform*

[![Flutter Framework](https://img.shields.io/badge/Framework-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini 3.6 Flash](https://img.shields.io/badge/AI_Engine-Gemini_3.6_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android_%7C_iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/rambinaypandit798-sudo/Sahayak-AI/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

---

## 🌟 Overview
**Sahayak AI** is a next-generation mobile application built for the **Fund My Crazy 2026 Hackathon**. It leverages the power of **Google Gemini AI** to bridge the gap between citizens and local governance, offering instant multimodal analysis for civic issues, live ticket tracking, and multi-session AI assistance in local languages.

---

## 📱 Core Features

* **🤖 Multimodal AI Analysis:** Upload photos of civic grievances (potholes, garbage dumps, water leaks) via camera or gallery for instant AI evaluation using `gemini-3.6-flash`.
* **🎫 Live Ticket Lifecycle:** Automatically generates unique tracking IDs (`SAH-XXXX`) with real-time status monitoring in the dedicated **'My Complaints'** module.
* **⚡ Escalation & Remind System:** Empower users to push unresolved grievances directly to higher authorities or trigger instant department reminders.
* **🎙️ Voice & Multilingual Accessibility:** Built-in **Speech-to-Text (STT)** and **Text-to-Speech (TTS)** engine to support seamless voice interaction in Hindi.
* **💬 Multi-Session Local Storage:** Secure multi-chat history and persistent API key management powered locally via `SharedPreferences`.

---

## 🛠️ Tech Stack & Architecture

| Component | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Flutter (`Dart`) | Cross-platform UI development |
| **AI Intelligence** | Google Generative AI (`gemini-3.6-flash`) | Image & text-based reasoning |
| **Local Persistence**| `shared_preferences`, `path_provider` | Offline state & secure key storage |
| **Media & Audio** | `image_picker`, `flutter_tts`, `speech_to_text` | Camera input & voice handling |

---

## 🚀 Quick Download & Setup

* **📥 Get the APK:** Download the production-ready build directly from the [GitHub Releases Page](https://github.com/rambinaypandit798-sudo/Sahayak-AI/releases).
* **💻 Run Locally:**
  ```bash
  git clone [https://github.com/rambinaypandit798-sudo/Sahayak-AI.git](https://github.com/rambinaypandit798-sudo/Sahayak-AI.git)
  cd Sahayak-AI
  flutter pub get
  flutter run
