// ============================================================================
//  Sahayak AI — Secure Production App with Fixed API Key Reset & Gemini Brain
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AppColors {
  AppColors._();
  static const Color bg = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color primary = Color(0xFF2563EB);
  static const Color highlight = Color(0xFF38BDF8);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);
}

class ChatMessage {
  ChatMessage({required this.id, required this.text, required this.isUser, required this.timestamp, this.imagePath});
  final String id;
  final String text;
  final bool isUser;
  final int timestamp;
  final String? imagePath;

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isUser': isUser, 'timestamp': timestamp, 'imagePath': imagePath};
  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    isUser: json['isUser'] == true,
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    imagePath: json['imagePath'],
  );
}

class Complaint {
  Complaint({required this.id, required this.ticketId, required this.title, required this.department, required this.details, required this.ward, required this.timestamp, required this.status, this.imagePath});
  final String id;
  final String ticketId;
  final String title;
  final String department;
  final String details;
  final String ward;
  final int timestamp;
  final String status;
  final String? imagePath;

  Map<String, dynamic> toJson() => {'id': id, 'ticketId': ticketId, 'title': title, 'department': department, 'details': details, 'ward': ward, 'timestamp': timestamp, 'status': status, 'imagePath': imagePath};
  static Complaint fromJson(Map<String, dynamic> json) => Complaint(
    id: json['id'] ?? '',
    ticketId: json['ticketId'] ?? '',
    title: json['title'] ?? '',
    department: json['department'] ?? '',
    details: json['details'] ?? '',
    ward: json['ward'] ?? '',
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    status: json['status'] ?? 'Submitted',
    imagePath: json['imagePath'],
  );
}

class LocalStore {
  static const String _chatKey = 'sahayak_chat_v9';
  static const String _complaintsKey = 'sahayak_complaints_v9';
  static const String _apiKeyStore = 'gemini_user_api_key';

  static Future<String?> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyStore);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyStore, key.trim());
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyStore);
  }

  static Future<List<ChatMessage>> loadChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chatKey);
      if (raw == null) return [];
      List decoded = jsonDecode(raw);
      return decoded.map((e) => ChatMessage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChat(List<ChatMessage> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<List<Complaint>> loadComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_complaintsKey);
      if (raw == null) return [];
      List decoded = jsonDecode(raw);
      return decoded.map((e) => Complaint.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveComplaints(List<Complaint> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_complaintsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}

class GeminiService {
  static Future<String> getGeminiResponse(String userPrompt, {String? imagePath}) async {
    final apiKey = await LocalStore.getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "⚠️ कृपया ऊपरी कोने में दिए गए चाबी (Key) आइकॉन पर क्लिक करके अपनी सही Gemini API Key दर्ज करें।";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.text(
          "आप 'Sahayak AI' हैं—एक बुद्धिमान नागरिक और छात्र सहायक (Civic & Student Assistant)। "
          "लोगों की नागरिक समस्याओं (सड़क, पानी, कचरा) और पढ़ाई/शैक्षणिक सवालों में मदद करें। हमेशा हिंदी में उत्तर दें।"
        ),
      );

      if (imagePath != null && File(imagePath).existsSync()) {
        final imageBytes = await File(imagePath).readAsBytes();
        final prompt = TextPart(userPrompt.isEmpty ? "इस फोटो को analyse करके बताएं कि यह किस प्रकार की समस्या है।" : userPrompt);
        final imagePart = DataPart('image/jpeg', imageBytes);

        final response = await model.generateContent([
          Content.multi([prompt, imagePart])
        ]);
        return response.text ?? "छवि का विश्लेषण करने में असमर्थ।";
      } else {
        final response = await model.generateContent([
          Content.text(userPrompt)
        ]);
        return response.text ?? "उत्तर प्राप्त नहीं हुआ।";
      }
    } catch (e) {
      return "एआई कनेक्शन में त्रुटि: आपकी API Key अमान्य हो सकती है। कृपया दूसरी Key दर्ज करें।";
    }
  }
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const SahayakApp());
  }, (_, __) {});
}

class SahayakApp extends StatelessWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(primary: AppColors.primary, secondary: AppColors.highlight, surface: AppColors.card),
      ),
      home: const ApiKeyWrapper(),
    );
  }
}

class ApiKeyWrapper extends StatefulWidget {
  const ApiKeyWrapper({super.key});

  @override
  State<ApiKeyWrapper> createState() => _ApiKeyWrapperState();
}

class _ApiKeyWrapperState extends State<ApiKeyWrapper> {
  bool _isLoading = true;
  bool _hasKey = false;
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final key = await LocalStore.getSavedApiKey();
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _saveAndProceed() async {
    final text = _keyController.text.trim();
    if (text.isEmpty) return;
    await LocalStore.saveApiKey(text);
    setState(() {
      _hasKey = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasKey) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enter Gemini API Key')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'सुरक्षा के लिए कोड में API Key नहीं है। Google AI Studio से अपनी फ्री Gemini API Key यहाँ दर्ज करें:',
                style: TextStyle(fontSize: 15, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.card,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(14)),
                onPressed: _saveAndProceed,
                child: const Text('Save & Start App', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final List<ChatMessage> _messages = [];
  final List<Complaint> _complaints = [];
  bool _booting = true;
  bool _aiTyping = false;
  bool _isListening = false;
  String? _currentlySpeakingId;
  int _idSeed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
    _bootstrap();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _currentlySpeakingId = null);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _currentlySpeakingId = null);
      });
    } catch (_) {}
  }

  Future<void> _speakText(String id, String text) async {
    try {
      if (_currentlySpeakingId == id) {
        await _flutterTts.stop();
        setState(() => _currentlySpeakingId = null);
      } else {
        await _flutterTts.stop();
        setState(() => _currentlySpeakingId = id);
        await _flutterTts.speak(text);
      }
    } catch (_) {
      setState(() => _currentlySpeakingId = null);
    }
  }

  Future<void> _listenVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'hi_IN',
          onResult: (val) => setState(() {
            _inputController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final chat = await LocalStore.loadChat();
    final comps = await LocalStore.loadComplaints();
    if (!mounted) return;
    setState(() {
      _messages.addAll(chat);
      _complaints.addAll(comps);
      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          id: 'welcome',
          text: 'नमस्ते 🙏 मैं Sahayak AI हूँ। आप फोटो अपलोड कर सकते हैं, माइक बटन दबाकर बोलकर सवाल पूछ सकते हैं, या टाइप कर सकते हैं।',
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      _booting = false;
    });
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/sahayak_media');
      if (!await folder.exists()) await folder.create(recursive: true);
      final target = '${folder.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(target);

      final userMsgId = 'user_img_${DateTime.now().millisecondsSinceEpoch}_${++_idSeed}';
      setState(() {
        _messages.add(ChatMessage(
          id: userMsgId,
          text: '[फोटो अपलोड की गई]',
          isUser: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          imagePath: target,
        ));
        _aiTyping = true;
      });
      LocalStore.saveChat(_messages);

      final aiReplyText = await GeminiService.getGeminiResponse("इस फोटो को analyse करके बताएं कि यह किस प्रकार की समस्या है।", imagePath: target);
      final aiMsgId = 'ai_img_${DateTime.now().millisecondsSinceEpoch}_${++_idSeed}';

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(id: aiMsgId, text: aiReplyText, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
        _aiTyping = false;
      });
      LocalStore.saveChat(_messages);
      _speakText(aiMsgId, aiReplyText);
    } catch (_) {
      setState(() => _aiTyping = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _aiTyping) return;
    _inputController.clear();

    final userMsgId = 'user_${DateTime.now().millisecondsSinceEpoch}_${++_idSeed}';
    setState(() {
      _messages.add(ChatMessage(id: userMsgId, text: text, isUser: true, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = true;
    });
    LocalStore.saveChat(_messages);

    final aiReplyText = await GeminiService.getGeminiResponse(text);
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}_${++_idSeed}';

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(id: aiMsgId, text: aiReplyText, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = false;
    });
    LocalStore.saveChat(_messages);
    _speakText(aiMsgId, aiReplyText);
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Reset/Change API Key',
            onPressed: () async {
              await LocalStore.clearApiKey();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ApiKeyWrapper()));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AI Assistant'),
            Tab(text: 'My Complaints'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => _pickAndUploadImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      label: const Text('Camera', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                      onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 18, color: Colors.white),
                      label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_aiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) {
                      return const ListTile(title: Text('Gemini AI is thinking...'));
                    }
                    final msg = _messages[index];
                    final bool isSpeaking = _currentlySpeakingId == msg.id;

                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: msg.isUser ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.imagePath != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(msg.imagePath!), width: 180, height: 120, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(msg.text, style: const TextStyle(fontSize: 14, height: 1.3)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _speakText(msg.id, msg.text),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSpeaking ? Colors.red.withOpacity(0.3) : AppColors.highlight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                      size: 14,
                                      color: isSpeaking ? Colors.redAccent : AppColors.highlight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeaking ? 'Stop' : 'Listen',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSpeaking ? Colors.redAccent : AppColors.highlight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : AppColors.highlight,
                      ),
                      onPressed: _listenVoice,
                      tooltip: 'बोलकर सवाल पूछें',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: _isListening ? 'सुन रहे हैं... बोलिए...' : 'अपनी समस्या या सवाल पूछें...',
                          filled: true,
                          fillColor: AppColors.card,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _handleSend,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _complaints.isEmpty
              ? const Center(child: Text('कोई शिकायत दर्ज नहीं है।'))
              : ListView.builder(
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.highlight)),
                          const SizedBox(height: 4),
                          Text('🎫 टिकट आईडी: ${c.ticketId}'),
                          Text('🏛️ विभाग: ${c.department}'),
                          Text('📍 विवरण: ${c.ward}'),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
