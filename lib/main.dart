import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
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
      home: const MainDashboard(), // लॉगिन हटाकर सीधा डैशबोर्ड सेट किया गया है
    );
  }
}

class ComplaintModel {
  final String title;
  final String department;
  final String date;
  final String details;

  ComplaintModel({required this.title, required this.department, required this.date, required this.details});

  Map<String, dynamic> toJson() => {
    'title': title,
    'department': department,
    'date': date,
    'details': details,
  };

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
    title: json['title'] ?? '',
    department: json['department'] ?? '',
    date: json['date'] ?? '',
    details: json['details'] ?? '',
  );
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
  
  final List<Map<String, String>> _chatMessages = [
    {"role": "ai", "text": "नमस्ते! मैं 'Sahayak AI' हूँ। आपकी क्या समस्या है? फोटो खींचें या बोलकर बताएं, डेटा सुरक्षित रहेगा।"}
  ];

  List<ComplaintModel> _savedComplaints = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _loadSavedData();
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.5);
    } catch (_) {}
  }

  // लोकल स्टोरेज से पिछला डेटा और कंप्लेंट्स लोड करना
  Future<void> _loadSavedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? complaintsStr = prefs.getString('saved_complaints');
      if (complaintsStr != null) {
        List decoded = jsonDecode(complaintsStr);
        setState(() {
          _savedComplaints = decoded.map((e) => ComplaintModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  // कंप्लेंट्स को परमानेंट सेव करना
  Future<void> _saveComplaintsToLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String encoded = jsonEncode(_savedComplaints.map((e) => e.toJson()).toList());
      await prefs.setString('saved_complaints', encoded);
    } catch (_) {}
  }

  GenerativeModel _getModel() {
    String apiKey = _geminiApiKey.isNotEmpty ? _geminiApiKey : "AIzaSyDummyKeyForBuildSafety12345";
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
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
        _chatMessages.add({"role": "user", "text": "[फोटो कंप्लेंट अपलोड की गई]"});
      });

      final model = _getModel();
      final imageBytes = await _selectedImage!.readAsBytes();
      
      final prompt = TextPart("आप एक सरकारी नागरिक सहायक (Sahayak AI) हैं। इस तस्वीर में दिखाई गई नागरिक समस्या की पहचान करें और संबंधित विभाग (जैसे नगर निगम, पीडब्ल्यूडी, जल बोर्ड) का नाम बताएं। हिंदी में स्पष्ट उत्तर दें।");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String aiReply = response.text ?? "समस्या दर्ज कर ली गई है।";

      // ऑटोमैटिक कंप्लेंट रिकॉर्ड में जोड़ना
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": aiReply});
        _savedComplaints.insert(0, ComplaintModel(
          title: "फोटो आधारित कंप्लेंट",
          department: "संबंधित सरकारी विभाग",
          date: DateTime.now().toString().substring(0, 16),
          details: aiReply,
        ));
      });

      _saveComplaintsToLocal();

      try {
        await _flutterTts.speak(aiReply);
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": "त्रुटि: इंटरनेट कनेक्शन या API Key जाँचें।"});
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
      final model = _getModel();
      final response = await model.generateContent([Content.text("आप एक सरकारी नागरिक सहायक (Sahayak AI) हैं। नागरिक की इस समस्या का समाधान और सही विभाग बताएं: $messageText")]);
      String aiReply = response.text ?? "शिकायत दर्ज हो गई है।";

      // कंप्लेंट लिस्ट में सेव करना
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": aiReply});
        _savedComplaints.insert(0, ComplaintModel(
          title: messageText.length > 25 ? "${messageText.substring(0, 25)}..." : messageText,
          department: "नगर प्रशासन / संबंधित विभाग",
          date: DateTime.now().toString().substring(0, 16),
          details: aiReply,
        ));
      });

      _saveComplaintsToLocal();

      try {
        await _flutterTts.speak(aiReply);
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": "त्रुटि: सर्वर से संपर्क नहीं हो पा रहा है।"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sahayak AI - Live & Saved Data'),
          backgroundColor: const Color(0xFF1E293B),
          bottom: const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            tabs: [
              Tab(icon: Icon(Icons.chat), text: "AI सहायक चैट"),
              Tab(icon: Icon(Icons.list_alt), text: "मेरी सभी कंप्लेंट्स"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // टैब 1: चैट और वॉयस/कैमरा असिस्टेंट
            Column(
              children: [
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
                            hintText: 'अपनी समस्या यहाँ लिखें...',
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

            // टैब 2: सहेजी गई सभी कंप्लेंट्स और उनकी पूरी डिटेल्स
            _savedComplaints.isEmpty
                ? const Center(
                    child: Text(
                      'अभी तक कोई कंप्लेंट दर्ज नहीं की गई है।\nचैट या फोटो अपलोड करके कंप्लेंट दर्ज करें!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _savedComplaints.length,
                    itemBuilder: (context, index) {
                      final item = _savedComplaints[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                                Text(item.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("विभाग: ${item.department}", style: const TextStyle(fontSize: 13, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text("विवरण: ${item.details}", style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3)),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
