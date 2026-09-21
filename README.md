<div align="center">

# 🏛️ SAHAYAK AI
### *Intelligent Civic & Student Assistant Platform*

[![Flutter Framework](https://img.shields.io/badge/Framework-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini 3.6 Flash](https://img.shields.io/badge/AI_Engine-Gemini_3.6_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)

### **👨‍💻 Developed by Ram Binay Kumar Pandit**
[![GitHub Profile](https://img.shields.io/badge/GitHub-rambinaypandit798--sudo-black?style=for-the-badge&logo=github)](https://github.com/rambinaypandit798-sudo)
[![LinkedIn Profile](https://img.shields.io/badge/LinkedIn-Connect-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/ram-binay-kumar-pandit-445aa6405)

</div>

---

## 🌟 Overview
**Sahayak AI** is a next-generation mobile application built for the **Fund My Crazy 2026 Hackathon**. It leverages the power of **Google Gemini AI** to bridge the gap between citizens and local governance, offering instant multimodal analysis for civic issues, live ticket tracking, and multi-session AI assistance in local languages.

---

## 📱 App Screenshots (UI Preview)

<div align="center">
  <table width="100%">
    <tr>
      <td align="center" width="50%"><b>AI Assistant & Chat Interface</b></td>
      <td align="center" width="50%"><b>Live Complaint Tracking</b></td>
    </tr>
    <tr>
      <td align="center"><img src="screenshots/chat_screen.png" width="280" alt="Chat Screen"/></td>
      <td align="center"><img src="screenshots/complaint_screen.png" width="280" alt="Complaints Screen"/></td>
    </tr>
  </table>
</div>

---

## ✨ Core Features

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
