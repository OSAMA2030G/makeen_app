import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _allReports = []; // القائمة الكاملة
  List<Map<String, dynamic>> _filteredReports = []; // القائمة المفلترة للبحث
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() async {
    setState(() => _isLoading = true);
    var data = await _dbHelper.getShopsReport();
    setState(() {
      _allReports = data;
      _filteredReports = data; // في البداية عرض الكل
      _isLoading = false;
    });
  }

  // دالة البحث في التقارير
  void _filterReports(String query) {
    setState(() {
      _filteredReports = _allReports
          .where((shop) => shop['title'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showInterestedUsers(int shopId, String shopName) async {
    var users = await _dbHelper.getUsersInterestedInShop(shopId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Directionality(
          textDirection: TextDirection.rtl, // لضمان ظهور الأسماء والبيانات بشكل صحيح
          child: Column(
            children: [
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Text(
                "المستخدمون المهتمون بـ $shopName",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text("لا يوجد مهتمون حالياً لهذا المتجر"))
                    : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryRed,
                        child: Icon(Icons.person, color: Colors.white)
                    ),
                    title: Text(users[index]['fullName'] ?? "مستخدم مجهول"),
                    subtitle: Text("الهاتف: ${users[index]['phone']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone_forwarded, color: Colors.green),
                      onPressed: () {
                        // هنا يمكنك إضافة كود للاتصال مباشرة بالمستخدم إذا أردت
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("تقارير التفاعل", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- حقل البحث العلوي بنفس تصميم صفحة الإدارة ---
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryRed,
            child: TextField(
              controller: _searchController,
              onChanged: _filterReports,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "بحث عن تقرير متجر معين...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- قائمة التقارير ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
                : _filteredReports.isEmpty
                ? const Center(child: Text("لا توجد تقارير مطابقة لبحثك"))
                : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                var shop = _filteredReports[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEEEEEE),
                        child: Icon(Icons.analytics_outlined, color: AppTheme.primaryRed),
                      ),
                      title: Text(shop['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.blueGrey),
                          Text(" المشاهدات: ${shop['views_count']}"),
                          const SizedBox(width: 15),
                          const Icon(Icons.favorite_border, size: 14, color: Colors.red),
                          Text(" المفضلة: ${shop['fav_count']}"),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () => _showInterestedUsers(shop['id'], shop['title']),
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