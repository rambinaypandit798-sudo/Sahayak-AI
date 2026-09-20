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
              const Text('Control\nEverything in\nOne Place', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, height: 1.2)),
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
                    Icon(Icons.mic, size: 45, color: Color(0xFFFBBF24)),
                    SizedBox(height: 10),
                    Icon(Icons.camera_alt, size: 35, color: Color(0xFF34D399)),
                    SizedBox(height: 12),
                    Text('Real Gemini Vision & Voice Engine', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया ईमेल और पासवर्ड दर्ज करें!')),
      );
      return;
    }
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

  bool _isListening = false;
  bool _isLoading = false;
  String _statusText = "माइक से बोलें या फोटो अपलोड करें...";
  String _aiResponse = "यहाँ Gemini AI का विश्लेषण दिखाई देगा।";
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _statusText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _sendTextToGemini(_statusText);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImageAndAnalyze(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _isLoading = true;
      _aiResponse = "📷 फोटो अपलोड हो रही है और Gemini 1.5 Flash Vision द्वारा जांची जा रही है...";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey.isNotEmpty ? _geminiApiKey : "YOUR_API_KEY",
      );

      final imageBytes = await _selectedImage!.readAsBytes();
      final prompt = TextPart("इस तस्वीर में दिखाई गई नागरिक समस्या (जैसे टूटी सड़क, कचरा, गंदा पानी आदि) की पहचान करें और बताएं कि इसके समाधान के लिए किस सरकारी विभाग से संपर्क करना चाहिए।");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      setState(() {
        _isLoading = false;
        _aiResponse = response.text ?? "विश्लेषण पूर्ण हुआ।";
      });

      await _flutterTts.speak(_aiResponse);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = "त्रुटि: $e";
      });
    }
  }

  Future<void> _sendTextToGemini(String prompt) async {
    setState(() {
      _isLoading = true;
      _aiResponse = "Gemini AI सोच रहा है...";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey.isNotEmpty ? _geminiApiKey : "YOUR_API_KEY",
      );

      final response = await model.generateContent([Content.text("आप एक सरकारी नागरिक सहायक (Sahayak AI) हैं। उपयोगकर्ता की इस समस्या का सटीक समाधान और संबंधित विभाग का नाम बताएं: $prompt")]);

      setState(() {
        _isLoading = false;
        _aiResponse = response.text ?? "उत्तर नहीं मिला।";
      });

      await _flutterTts.speak(_aiResponse);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = "त्रुटि: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI - Live Assistant'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _listen,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent : const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10, spreadRadius: 3)],
                  ),
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_isListening ? "सुन रहा हूँ..." : "बोलने के लिए माइक टैप करें", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                  onPressed: () => _pickImageAndAnalyze(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () => _pickImageAndAnalyze(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (_selectedImage != null)
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Text("इनपुट: $_statusText", style: const TextStyle(fontSize: 13, color: Colors.amber)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🧠 Gemini AI Response & Routing:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Text(_aiResponse, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
