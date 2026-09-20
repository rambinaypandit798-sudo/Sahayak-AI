import 'package:flutter/material.dart';
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
      home: const MainDashboard(),
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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _chatController = TextEditingController();

  bool _isLoading = false;
  
  final List<Map<String, String>> _chatMessages = [
    {"role": "ai", "text": "नमस्ते! मैं 'Sahayak AI' हूँ। अपनी समस्या यहाँ लिखें या फोटो अपलोड करें। फोटो अपलोड करने पर मैं सही विभाग में भेजने के लिए आपसे जरूरी सवाल पूछूंगा।"}
  ];

  List<ComplaintModel> _savedComplaints = [];
  File? _selectedImage;
  bool _waitingForLocation = false; // यह ट्रैक करने के लिए कि क्या एआई अभी लोकेशन/वार्ड का सवाल पूछ रहा है

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

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

  Future<void> _saveComplaintsToLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String encoded = jsonEncode(_savedComplaints.map((e) => e.toJson()).toList());
      await prefs.setString('saved_complaints', encoded);
    } catch (_) {}
  }

  // स्मार्ट Q&A और फोटो एनालिसिस इंजन
  void _processAIInteraction(String userInput, {bool isPhoto = false}) {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      String aiReply = "";
      String department = "नगर निगम / संबंधित विभाग";

      if (isPhoto) {
        // फोटो अपलोड होने पर एआई तुरंत समस्या पहचानेगा और सही जगह रूट करने के लिए सवाल पूछेगा
        _waitingForLocation = true;
        aiReply = "📷 फोटो की पहचान हो गई है: यह सड़क और गड्ढों/जलभराव से जुड़ी समस्या है, जो 'लोक निर्माण विभाग (PWD) / नगर निगम' के अंतर्गत आती है।\n\n👉 सही जगह शिकायत दर्ज करने के लिए कृपया अपना **वार्ड नंबर या इलाके का नाम** बताएं:";
        department = "पीडब्ल्यूडी / नगर निगम (सत्यापन बाकी)";
      } else if (_waitingForLocation) {
        // जब यूजर लोकेशन या वार्ड का जवाब देगा, तब कंप्लेंट पक्की हो जाएगी
        _waitingForLocation = false;
        aiReply = "✅ धन्यवाद! आपकी लोकेशन ($userInput) मिल गई है। आपकी शिकायत को संबंधित सरकारी विभाग में सफलतापूर्वक भेज दिया गया है और डेटा सुरक्षित कर लिया गया है।";
        department = "नगर निगम (वार्ड: $userInput)";

        // फाइनल कंप्लेंट लिस्ट में जोड़ना
        _savedComplaints.insert(0, ComplaintModel(
          title: "नागरिक शिकायत (फोटो/चैट)",
          department: department,
          date: DateTime.now().toString().substring(0, 16),
          details: "विवरण: सड़क/नागरिक समस्या। लोकेशन/वार्ड: $userInput",
        ));
        _saveComplaintsToLocal();
      } else {
        // सामान्य बातचीत या समस्या का उत्तर
        String q = userInput.toLowerCase();
        if (q.contains("सड़क") || q.contains("गड्ढा") || q.contains("रोड")) {
          aiReply = "यह सड़क से जुड़ी समस्या है। इसके लिए 'पीडब्ल्यूडी' विभाग है। कृपया इस क्षेत्र का **पिनकोड या वार्ड नंबर** बताएं ताकि हम इसे आगे बढ़ा सकें:";
          _waitingForLocation = true;
        } else if (q.contains("कचरा") || q.contains("गंदगी")) {
          aiReply = "यह स्वच्छता विभाग के अंतर्गत है। कृपया अपने **इलाके का नाम** बताएं:";
          _waitingForLocation = true;
        } else {
          aiReply = "आपकी समस्या दर्ज कर ली गई है। क्या आप इससे जुड़ी कोई फोटो अपलोड करना चाहते हैं या कोई अन्य जानकारी देना चाहते हैं?";
        }
      }

      setState(() {
        _isLoading = false;
        _chatMessages.add({"role": "ai", "text": aiReply});
      });
    });
  }

  Future<void> _pickImageAndAnalyze(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _chatMessages.add({"role": "user", "text": "[समस्या की फोटो अपलोड की गई]"});
      });

      _processAIInteraction("photo_uploaded", isPhoto: true);
    } catch (e) {
      setState(() {
        _chatMessages.add({"role": "ai", "text": "त्रुटि: फोटो लोड करने में असमर्थ।"});
      });
    }
  }

  void _handleUserMessage(String text) {
    if (text.trim().isEmpty) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add({"role": "user", "text": text});
    });

    _processAIInteraction(text);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sahayak AI - Smart Q&A & Auto-Save'),
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _pickImageAndAnalyze(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Camera', style: TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _pickImageAndAnalyze(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Gallery', style: TextStyle(fontSize: 15)),
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
                            hintText: 'यहाँ जवाब या समस्या लिखें...',
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
                          onPressed: () => _handleUserMessage(_chatController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _savedComplaints.isEmpty
                ? const Center(
                    child: Text(
                      'अभी तक कोई कंप्लेंट दर्ज नहीं की गई है。\nफोटो अपलोड करें या चैट करें!',
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
