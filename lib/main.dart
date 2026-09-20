import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SahayakAIApp());
}

class SahayakAIApp extends StatelessWidget {
  const SahayakAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF2563EB),
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sahayak AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              const Text('Smart Interactive\nCitizen Assistant', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, height: 1.2)),
              const Spacer(),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_bubble_outline, size: 45, color: Color(0xFFFBBF24)),
                    SizedBox(height: 10),
                    Icon(Icons.psychology, size: 35, color: Color(0xFF34D399)),
                    SizedBox(height: 12),
                    Text('AI Smart Q&A & Department Routing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Get Started ➔', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sahayak AI', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 5)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to\nSahayak AI login now!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.3),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleLogin,
                    child: const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _chatController = TextEditingController();

  bool _isListening = false;
  bool _isLoading = false;
  String _statusText = "माइक से बोलें या फोटो अपलोड करें...";
  
  // चैट इतिहास जिसमें एआई के सवाल और यूजर के जवाब रहेंगे
  final List<Map<String, String>> _chatMessages = [
    {"role": "ai", "text": "नमस्ते! मैं 'Sahayak AI' हूँ। आप किस नागरिक समस्या (सड़क, कचरा, पानी आदि) का सामना कर रहे हैं? फोटो खींचें या बोलकर बताएं।"}
  ];

  File? _selectedImage;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _initGeminiChat();
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.5);
    } catch (_) {}
  }

  void _initGeminiChat() {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey.isNotEmpty ? _geminiApiKey : "YOUR_API_KEY",
      );
      // चैट सेशन शुरू किया गया है ताकि एआई संदर्भ (Context) याद रखे और क्रॉस-क्वेश्चन कर सके
      _chatSession = model.startChat(history: [
        Content.text("आप एक सरकारी नागरिक सहायक (Sahayak AI) हैं। आपका काम नागरिकों की समस्याओं को समझना है। यदि जानकारी अधूरी है, तो संबंधित विभाग (जैसे नगर निगम, पीडब्ल्यूडी, जल बोर्ड) तक सही से शिकायत दर्ज करने के लिए उपयोगकर्ता से सटीक सवाल (जैसे लोकेशन, वार्ड नंबर, समस्या कितने दिनों से है) पूछें। हमेशा हिंदी में बात करें।")
      ]);
    } catch (_) {}
  }

  void _listen() async {
    try {
      if (!_isListening) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) => setState(() {
              _statusText = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _sendMessageToAI(_statusText);
              }
            }),
          );
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _statusText = "माइक्रोफोन अनुमति त्रुटि";
      });
    }
  }

  Future<void> _pickImageAndAnalyze(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
        _chatMessages.add({"role": "user", "text": "[फोटो अपलोड की गई]"});
      });

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey.isNotEmpty ? _geminiApiKey : "YOUR_API_KEY",
      );

      final imageBytes = await _selectedImage!.readAsBytes();
      final prompt = TextPart("इस तस्वीर में दिखाई गई नागरिक समस्या की पहचान करें। इसके बाद इसे सही सरकारी विभाग में भेजने के लिए उपयोगकर्ता से जरूरी सवाल (जैसे किस वार्ड/इलाके की है) पूछें ताकि सही जगह शिकायत दर्ज हो सके। हिंदी में उत्तर दें।");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String aiReply = response.text ?? "कृपया इस समस्या से जुड़ी लोकेशन और वार्ड नंबर बताएं।";

      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": aiReply});
      });

      try {
        await _flutterTts.speak(aiReply);
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": "त्रुटि: फोटो का विश्लेषण करने में असफल। ($e)"});
      });
    }
  }

  Future<void> _sendMessageToAI(String messageText) async {
    if (messageText.trim().isEmpty) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add({"role": "user", "text": messageText});
      _isLoading = true;
    });

    try {
      String aiReply;
      if (_chatSession != null) {
        final response = await _chatSession!.sendMessage(Content.text(messageText));
        aiReply = response.text ?? "कृपया अधिक जानकारी दें ताकि सही विभाग को सूचित किया जा सके।";
      } else {
        aiReply = "सत्र सक्रिय नहीं है। कृपया ऐप रीस्टार्ट करें।";
      }

      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": aiReply});
      });

      try {
        await _flutterTts.speak(aiReply);
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": "त्रुटि: $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI - Smart Q&A Assistant'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // टॉप पर माइक और कैमरा शॉर्टकट
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _listen,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                  onPressed: () => _pickImageAndAnalyze(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () => _pickImageAndAnalyze(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ),
          if (_selectedImage != null)
            Container(
              height: 70,
              width: 70,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
              ),
            ),
          // चैट और Q&A इतिहास सूची
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                bool isAi = msg["role"] == "ai";
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isAi ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isAi ? const Color(0xFF334155) : Colors.transparent),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // नीचे टेक्स्ट इनपुट और भेजने का बटन
          Container(
            padding: const EdgeInsets.all(8.0),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'अपनी समस्या या जवाब यहाँ लिखें...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _sendMessageToAI(_chatController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
