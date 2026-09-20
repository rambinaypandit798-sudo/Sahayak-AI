// ============================================================================
//  Sahayak AI — Smart Citizen & Civil Grievance Assistant
//  Single-file production application (Android 11 → Android 16)
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  AppColors._();
  static const Color bg = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color primary = Color(0xFF2563EB);
  static const Color highlight = Color(0xFF38BDF8);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);
  static const Color danger = Color(0xFFF87171);
  static const Color primarySoft = Color(0x2E2563EB);
  static const Color highlightSoft = Color(0x3338BDF8);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? DateTime.now().millisecondsSinceEpoch;
  }
  return DateTime.now().millisecondsSinceEpoch;
}

String _asString(Object? value) {
  if (value == null) return '';
  return value.toString();
}

String _twoDigits(int n) => n < 10 ? '0$n' : '$n';

String _formatClock(int millis) {
  try {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final suffix = d.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${_twoDigits(d.minute)} $suffix';
  } catch (_) {
    return '';
  }
}

String _formatFullStamp(int millis) {
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  try {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final suffix = d.hour < 12 ? 'AM' : 'PM';
    final month = months[(d.month - 1).clamp(0, 11)];
    return '${_twoDigits(d.day)} $month ${d.year} • $hour12:${_twoDigits(d.minute)} $suffix';
  } catch (_) {
    return '';
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });

  final String id;
  final String text;
  final bool isUser;
  final int timestamp;
  final String? imagePath;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp,
        'imagePath': imagePath,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    final rawPath = _asString(json['imagePath']);
    return ChatMessage(
      id: _asString(json['id']),
      text: _asString(json['text']),
      isUser: json['isUser'] == true,
      timestamp: _asInt(json['timestamp']),
      imagePath: rawPath.isEmpty ? null : rawPath,
    );
  }
}

class Complaint {
  Complaint({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.categoryKey,
    required this.department,
    required this.details,
    required this.ward,
    required this.timestamp,
    required this.status,
    this.imagePath,
  });

  final String id;
  final String ticketId;
  final String title;
  final String categoryKey;
  final String department;
  final String details;
  final String ward;
  final int timestamp;
  final String status;
  final String? imagePath;

  IconData get icon => AiEngine.byKey(categoryKey).icon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ticketId': ticketId,
        'title': title,
        'categoryKey': categoryKey,
        'department': department,
        'details': details,
        'ward': ward,
        'timestamp': timestamp,
        'status': status,
        'imagePath': imagePath,
      };

  static Complaint fromJson(Map<String, dynamic> json) {
    final rawPath = _asString(json['imagePath']);
    return Complaint(
      id: _asString(json['id']),
      ticketId: _asString(json['ticketId']),
      title: _asString(json['title']),
      categoryKey: _asString(json['categoryKey']),
      department: _asString(json['department']),
      details: _asString(json['details']),
      ward: _asString(json['ward']),
      timestamp: _asInt(json['timestamp']),
      status: _asString(json['status']).isEmpty ? 'Submitted' : _asString(json['status']),
      imagePath: rawPath.isEmpty ? null : rawPath,
    );
  }
}

class IssueCategory {
  const IssueCategory({
    required this.key,
    required this.label,
    required this.department,
    required this.icon,
    required this.keywords,
  });

  final String key;
  final String label;
  final String department;
  final IconData icon;
  final List<String> keywords;
}

class AiEngine {
  AiEngine._();

  static const IssueCategory road = IssueCategory(
    key: 'road',
    label: 'Road Damage / Pothole',
    department: 'Public Works Department (PWD)',
    icon: Icons.construction_rounded,
    keywords: <String>['pothole', 'gaddha', 'road', 'crack', 'asphalt'],
  );

  static const IssueCategory garbage = IssueCategory(
    key: 'garbage',
    label: 'Garbage / Sanitation',
    department: 'Municipal Sanitation Department',
    icon: Icons.delete_sweep_rounded,
    keywords: <String>['garbage', 'trash', 'waste', 'kachra', 'dump', 'smell'],
  );

  static const IssueCategory water = IssueCategory(
    key: 'water',
    label: 'Water Leakage / Supply',
    department: 'Water Supply & Sewerage Board',
    icon: Icons.water_drop_rounded,
    keywords: <String>['water', 'leak', 'pipe', 'tap', 'supply'],
  );

  static const IssueCategory general = IssueCategory(
    key: 'general',
    label: 'General Civic Grievance',
    department: 'General Grievance Redressal Cell',
    icon: Icons.assignment_rounded,
    keywords: <String>[],
  );

  static const List<IssueCategory> all = <IssueCategory>[
    road, garbage, water, general,
  ];

  static IssueCategory byKey(String key) {
    for (final IssueCategory c in all) {
      if (c.key == key) return c;
    }
    return general;
  }

  static IssueCategory? classifyText(String raw) {
    try {
      final String text = raw.toLowerCase();
      IssueCategory? best;
      int bestScore = 0;
      for (final IssueCategory c in all) {
        int score = 0;
        for (final String k in c.keywords) {
          if (text.contains(k)) score += k.length;
        }
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  static IssueCategory classifyImage(String path) {
    try {
      final String name = path.toLowerCase();
      for (final IssueCategory c in all) {
        for (final String k in c.keywords) {
          if (name.contains(k)) return c;
        }
      }
      return road;
    } catch (_) {
      return road;
    }
  }
}

class LocalStore {
  LocalStore._();
  static const String _chatKey = 'sahayak_chat_v1';
  static const String _complaintsKey = 'sahayak_complaints_v1';
  static SharedPreferences? _cached;

  static Future<SharedPreferences?> _prefs() async {
    try {
      if (_cached != null) return _cached;
      _cached = await SharedPreferences.getInstance();
      return _cached;
    } catch (e) {
      return null;
    }
  }

  static Future<List<ChatMessage>> loadChat() async {
    try {
      final prefs = await _prefs();
      final raw = prefs?.getString(_chatKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChat(List<ChatMessage> messages) async {
    try {
      final prefs = await _prefs();
      if (prefs == null) return;
      final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(_chatKey, encoded);
    } catch (_) {}
  }

  static Future<List<Complaint>> loadComplaints() async {
    try {
      final prefs = await _prefs();
      final raw = prefs?.getString(_complaintsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => Complaint.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveComplaints(List<Complaint> complaints) async {
    try {
      final prefs = await _prefs();
      if (prefs == null) return;
      final encoded = jsonEncode(complaints.map((c) => c.toJson()).toList());
      await prefs.setString(_complaintsKey, encoded);
    } catch (_) {}
  }
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (details) => const Material(
      color: AppColors.bg,
      child: Center(child: Text('Something went wrong.', style: TextStyle(color: AppColors.textSecondary))),
    );
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
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.highlight,
          surface: AppColors.card,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class _Draft {
  _Draft({required this.category, required this.details, this.imagePath});
  final IssueCategory category;
  final String details;
  final String? imagePath;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  final List<ChatMessage> _messages = [];
  final List<Complaint> _complaints = [];

  bool _booting = true;
  bool _aiTyping = false;
  bool _awaitingLocation = false;
  _Draft? _draft;
  int _idSeed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final chat = await LocalStore.loadChat();
    final complaints = await LocalStore.loadComplaints();
    if (!mounted) return;
    setState(() {
      _messages.addAll(chat);
      _complaints.addAll(complaints);
      if (_messages.isEmpty) {
        _messages.add(_welcomeMessage());
      }
      _booting = false;
    });
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${++_idSeed}';

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      id: _newId(),
      text: 'Namaste 🙏 I am Sahayak AI, your civic grievance assistant.\n\nSend a photo or describe your issue, and I will help register your complaint.',
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _aiTyping) return;
    _inputController.clear();
    await _processUserText(text);
  }

  Future<void> _processUserText(String text) async {
    setState(() {
      _messages.add(ChatMessage(id: _newId(), text: text, isUser: true, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = true;
    });
    LocalStore.saveChat(_messages);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (_awaitingLocation && _draft != null) {
      await _finaliseComplaint(text);
    } else {
      await _answerTextQuery(text);
    }
  }

  Future<void> _answerTextQuery(String text) async {
    final category = AiEngine.classifyText(text) ?? AiEngine.general;
    _draft = _Draft(category: category, details: text);
    _awaitingLocation = true;

    final reply = '🧠 Understood: *${category.label}*.\n🏛️ Department: ${category.department}\n\nPlease provide your Ward Number or Locality Name:';

    setState(() {
      _messages.add(ChatMessage(id: _newId(), text: reply, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = false;
    });
    LocalStore.saveChat(_messages);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/sahayak_media');
      if (!await folder.exists()) await folder.create(recursive: true);
      final target = '${folder.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(target);

      if (!mounted) return;
      await _handlePickedImage(target);
    } catch (_) {}
  }

  Future<void> _handlePickedImage(String path) async {
    setState(() {
      _messages.add(ChatMessage(id: _newId(), text: '📷 Photo attached', isUser: true, timestamp: DateTime.now().millisecondsSinceEpoch, imagePath: path));
      _aiTyping = true;
    });
    LocalStore.saveChat(_messages);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final category = AiEngine.classifyImage(path);
    _draft = _Draft(category: category, details: '', imagePath: path);
    _awaitingLocation = true;

    final reply = '📷 Photo analyzed: ${category.label} (${category.department}).\n\nPlease provide your Ward Number or Locality Name:';

    setState(() {
      _messages.add(ChatMessage(id: _newId(), text: reply, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = false;
    });
    LocalStore.saveChat(_messages);
    _scrollToBottom();
  }

  Future<void> _finaliseComplaint(String ward) async {
    final draft = _draft;
    if (draft == null) {
      setState(() => _aiTyping = false);
      return;
    }

    final cleanWard = ward.trim().isEmpty ? 'Not specified' : ward.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final ticket = 'SHK${(now % 1000000).toString().padLeft(6, '0')}';

    final complaint = Complaint(
      id: _newId(),
      ticketId: ticket,
      title: draft.category.label,
      categoryKey: draft.category.key,
      department: draft.category.department,
      details: draft.details.isEmpty ? 'Reported via photo evidence.' : draft.details,
      ward: cleanWard,
      timestamp: now,
      status: 'Submitted',
      imagePath: draft.imagePath,
    );

    setState(() {
      _complaints.insert(0, complaint);
    });
    await LocalStore.saveComplaints(_complaints);

    final reply = '✅ Complaint registered successfully!\n🎫 Ticket ID: $ticket\n📍 Ward: $cleanWard\n\nSaved under "My Complaints".';

    setState(() {
      _messages.add(ChatMessage(id: _newId(), text: reply, isUser: false, timestamp: DateTime.now().millisecondsSinceEpoch));
      _aiTyping = false;
      _awaitingLocation = false;
      _draft = null;
    });
    LocalStore.saveChat(_messages);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI'),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            const Tab(text: 'AI Assistant'),
            Tab(text: 'My Complaints (${_complaints.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildChatTab(),
          _buildComplaintsTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_booting) return const Center(child: CircularProgressIndicator());
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_aiTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _messages.length) {
                return const ListTile(title: Text('Sahayak AI is typing...'));
              }
              final msg = _messages[index];
              return Align(
                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (msg.imagePath != null) ...[
                        Image.file(File(msg.imagePath!), width: 180, height: 120, fit: BoxFit.cover),
                        const SizedBox(height: 6),
                      ],
                      Text(msg.text),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
            const SizedBox(width: 10),
            ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('Gallery')),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(hintText: 'Type your issue or ward...'),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _handleSend),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintsTab() {
    if (_complaints.isEmpty) {
      return const Center(child: Text('No complaints registered yet.'));
    }
    return ListView.builder(
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final c = _complaints[index];
        return ListTile(
          title: Text(c.title),
          subtitle: Text('Ticket: ${c.ticketId} | Ward: ${c.ward}\nDept: ${c.department}'),
          isThreeLine: true,
        );
      },
    );
  }
}
