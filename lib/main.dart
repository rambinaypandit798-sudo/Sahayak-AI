import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _chatController = TextEditingController();
  
  final List<Map<String, String>> _chatMessages = [
    {"role": "ai", "text": "Hello! I am Sahayak AI. Type your civic issue below, and I will help route it to the correct department."}
  ];

  List<ComplaintModel> _savedComplaints = [];

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

  void _handleUserMessage(String text) {
    if (text.trim().isEmpty) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add({"role": "user", "text": text});
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      String aiReply = "Your complaint regarding '$text' has been successfully registered and routed to the Municipal Corporation / PWD department. Data is saved locally.";
      
      setState(() {
        _chatMessages.add({"role": "ai", "text": aiReply});
        _savedComplaints.insert(0, ComplaintModel(
          title: text.length > 25 ? "${text.substring(0, 25)}..." : text,
          department: "Municipal Corporation / PWD",
          date: DateTime.now().toString().substring(0, 16),
          details: "Issue: $text",
        ));
      });

      _saveComplaintsToLocal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sahayak AI - Dashboard'),
          backgroundColor: const Color(0xFF1E293B),
          bottom: const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            tabs: [
              Tab(icon: Icon(Icons.chat), text: "AI Chat"),
              Tab(icon: Icon(Icons.list_alt), text: "My Complaints"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
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
                            hintText: 'Type your issue here...',
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
                      'No complaints registered yet.\nType in the chat tab to create one!',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                                Text(item.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Department: ${item.department}", style: const TextStyle(fontSize: 13, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text("Details: ${item.details}", style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3)),
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
