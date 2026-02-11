import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';
import 'add_shop.dart';

class ManageShopsScreen extends StatefulWidget {
  const ManageShopsScreen({super.key});

  @override
  State<ManageShopsScreen> createState() => _ManageShopsScreenState();
}

class _ManageShopsScreenState extends State<ManageShopsScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _allShops = []; // القائمة الأصلية
  List<Map<String, dynamic>> _filteredShops = []; // القائمة المفلترة للبحث
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  void _fetchShops() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> shops = await _dbHelper.getAllShops();
    setState(() {
      _allShops = shops;
      _filteredShops = shops; // في البداية نعرض الكل
      _isLoading = false;
    });
  }

  // دالة الفلترة (البحث)
  void _filterShops(String query) {
    setState(() {
      _filteredShops = _allShops
          .where((shop) =>
      shop['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
          shop['category_name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleStatus(int id, int currentStatus) async {
    int newStatus = (currentStatus == 1) ? 0 : 1;
    await _dbHelper.updateShopStatus(id, newStatus);
    _fetchShops();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 1 ? "تم تفعيل ظهور المتجر" : "تم إخفاء المتجر عن المستخدمين"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _deleteShop(int id) async {
    final db = await _dbHelper.database;
    await db.delete('shops', where: 'id = ?', whereArgs: [id]);
    _fetchShops();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف المتجر بنجاح")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("إدارة المتاجر", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- حقل البحث الجديد ---
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryRed,
            child: TextField(
              controller: _searchController,
              onChanged: _filterShops,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "ابحث عن اسم المتجر أو التصنيف...",
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

          // --- القائمة ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
                : _filteredShops.isEmpty
                ? const Center(child: Text("لا توجد نتائج مطابقة للبحث"))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredShops.length,
              itemBuilder: (context, index) {
                final shop = _filteredShops[index];
                bool isActive = (shop['status'] ?? 1) == 1;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: shop['image'].startsWith('assets/')
                                  ? Image.asset(shop['image'], width: 65, height: 65, fit: BoxFit.cover)
                                  : Image.file(File(shop['image']), width: 65, height: 65, fit: BoxFit.cover),
                            ),
                            title: Text(shop['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(shop['category_name'] ?? "بدون تصنيف", style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.remove_red_eye, size: 16, color: AppTheme.primaryRed),
                                    const SizedBox(width: 5),
                                    Text("${shop['views_count'] ?? 0} مشاهدة",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddShopScreen(shop: shop)),
                                  ).then((value) {
                                    if (value == true) _fetchShops();
                                  });
                                },
                                icon: const Icon(Icons.edit_note, color: Colors.blue),
                                label: const Text("تعديل", style: TextStyle(color: Colors.blue)),
                              ),
                              Row(
                                children: [
                                  Text(isActive ? "ظاهر" : "مخفي", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Switch(
                                    value: isActive,
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.grey,
                                    onChanged: (val) => _toggleStatus(shop['id'], shop['status'] ?? 1),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _showDeleteDialog(shop['id'], shop['title']),
                              ),
                            ],
                          )
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

  void _showDeleteDialog(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
        content: Text("هل أنت متأكد من حذف '$title'؟", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _deleteShop(id);
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}