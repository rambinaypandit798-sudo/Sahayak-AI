// ============================================================================
//  Sahayak AI — Smart Citizen Assistant with Built-in TTS Voice Reader
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  static const String _chatKey = 'sahayak_chat_v3';
  static const String _complaintsKey = 'sahayak_complaints_v3';

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
  static Future<String> getAiResponse(String prompt) async {
    try {
      String p = prompt.toLowerCase();
      if (p.contains('bca') || p.contains('इग्नू')) {
        return "आप इंदिरा गांधी राष्ट्रीय मुक्त विश्वविद्यालय से बीसीए (BCA) की पढ़ाई कर रहे हैं। अपनी पढ़ाई और कोडिंग पर पूरा ध्यान दें!";
      } else if (p.contains('सड़क') || p.contains('गड्ढा') || p.contains('pothole')) {
        return "यह सड़क एवं गड्ढों की समस्या है, जो लोक निर्माण विभाग (PWD) के अंतर्गत आती है। कृपया अपना वार्ड नंबर या लोकेशन बताएं।";
      } else if (p.contains('कचरा') || p.contains('garbage')) {
        return "यह कचरा और स्वच्छता से जुड़ी समस्या है, जो नगर निगम स्वच्छता विभाग के अंतर्गत आती है। अपना क्षेत्र बताएं।";
      }
      return "नमस्ते! मैंने आपकी बात सुन ली है। यदि यह कोई नागरिक शिकायत है, तो कृपया अपना वार्ड नंबर या लोकेशन बताएं ताकि मैं इसे दर्ज कर सकूँ।";
    } catch (_) {
      return "माफ़ कीजिए, अभी प्रोसेस करने में असमर्थ हूँ।";
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
      home: const HomeShell(),
    );
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

  final List<ChatMessage> _messages = [];
  final List<Complaint> _complaints = [];
  bool _booting = true;
  bool _aiTyping = false;
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
      await _flutterTts.setLanguage("hi-IN"); // हिंदी भाषा सेट करना
      await _flutterTts.setSpeechRate(0.5); // बोलने की सामान्य गति
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
        // अगर पहले से यही मैसेज बोल रहा है, तो रोक (Stop) दें
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

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _flutterTts.stop();
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
          text: 'नमस्ते 🙏 मैं Sahayak AI हूँ। आप अपनी समस्या पूछ सकते हैं या नीचे दिए गए बटन से मैसेज सुन सकते हैं।',
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      _booting = false;
    });
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

    final aiReplyText = await GeminiService.getAiResponse(text);
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}_${++_idSeed}';

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(id: aiMsgId, text: aiReplyText, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = false;
    });
    LocalStore.saveChat(_messages);

    // ऑटोमैटिक एआई के जवाब को बोलकर सुनाना
    _speakText(aiMsgId, aiReplyText);
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI (Voice Reader)'),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_aiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) {
                      return const ListTile(title: Text('AI is thinking...'));
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
                            Text(msg.text, style: const TextStyle(fontSize: 14, height: 1.3)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'अपनी समस्या या सवाल यहाँ लिखें...',
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              ? const Center(child: Text('कोई कंप्लेंट दर्ज नहीं है।'))
              : ListView.builder(
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text('Ticket: ${c.ticketId} | Ward: ${c.ward}'),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
