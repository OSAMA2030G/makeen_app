import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _currentFilter = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllUsersWithActivity();
    setState(() {
      _allUsers = data;
      _applyFilterAndSearch();
      _isLoading = false;
    });
  }

  void _applyFilterAndSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        bool matchesSearch = user['fullName'].toString().toLowerCase().contains(query) ||
            user['phone'].toString().contains(query);

        int activity = user['activity_count'] ?? 0;
        bool matchesFilter = true;
        if (_currentFilter == 'الأكثر نشاطاً') matchesFilter = activity > 5;
        if (_currentFilter == 'العاديون') matchesFilter = activity >= 1 && activity <= 5;
        if (_currentFilter == 'الخاملون') matchesFilter = activity == 0;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _toggleBlock(int id, int currentStatus, String name) async {
    int newStatus = (currentStatus == 1) ? 0 : 1;
    await _dbHelper.updateUserBlockStatus(id, newStatus);
    _fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(newStatus == 1 ? "تم حظر $name" : "تم إلغاء حظر $name")),
    );
  }

  void _sendPrivateMessage(String userName) {
    TextEditingController msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("إرسال رسالة إلى $userName"),
        content: TextField(
          controller: msgController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "اكتب نص الرسالة هنا..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (msgController.text.isNotEmpty) {
                await _dbHelper.sendPrivateNotification("رسالة خاصة", "عزيزي $userName: ${msgController.text}");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الرسالة")));
              }
            },
            child: const Text("إرسال"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("إدارة المستخدمين", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // حقل البحث
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryRed,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _applyFilterAndSearch(),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "ابحث عن اسم أو رقم هاتف...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          // أزرار الفرز
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['الكل', 'الأكثر نشاطاً', 'العاديون', 'الخاملون'].map((filter) {
                bool isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _currentFilter = filter);
                      _applyFilterAndSearch();
                    },
                    selectedColor: AppTheme.primaryRed,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                bool isBlocked = user['isBlocked'] == 1;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isBlocked ? Colors.red[100] : Colors.green[100],
                        child: Icon(Icons.person, color: isBlocked ? Colors.red : Colors.green),
                      ),
                      title: Text(user['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("النشاط: ${user['activity_count']} مفضلة"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message_outlined, color: Colors.blue),
                            onPressed: () => _sendPrivateMessage(user['fullName']),
                          ),
                          IconButton(
                            icon: Icon(isBlocked ? Icons.lock_open : Icons.block, color: Colors.orange),
                            onPressed: () => _toggleBlock(user['id'], user['isBlocked'] ?? 0, user['fullName']),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}