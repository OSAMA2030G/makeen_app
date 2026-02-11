import 'package:flutter/material.dart';
import 'package:makin/scoren/manage_shops.dart';
import 'package:makin/scoren/reports.dart';
import 'package:makin/scoren/manage_users.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'add_shop.dart';
import 'login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DbHelper _dbHelper = DbHelper();
  final TextEditingController _alertController = TextEditingController();
  int _shopsCount = 0;
  int _usersCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() async {
    int shops = await _dbHelper.getShopsCount();
    int users = await _dbHelper.getUsersCount();
    if (mounted) {
      setState(() {
        _shopsCount = shops;
        _usersCount = users;
      });
    }
  }

  void _confirmSendNotification() {
    if (_alertController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى كتابة نص الإشعار أولاً")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تأكيد الإرسال", textAlign: TextAlign.right),
        content: Text("سيتم إرسال: ${_alertController.text}", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.sendNotification("تنبيه من الإدارة", _alertController.text.trim());
              _alertController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال بنجاح")));
            },
            child: const Text("إرسال الآن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("لوحة التحكم", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()))
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard("المتاجر", "$_shopsCount", Icons.store, Colors.blue),
                _buildStatCard("المستخدمين", "$_usersCount", Icons.people, Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            // إضافة الـ hint هنا لحل المشكلة
            CustomTextField(
              label: "إشعار سريع لجميع المستخدمين",
              hint: "اكتب محتوى الإشعار هنا...",
              controller: _alertController,
              icon: Icons.campaign,
            ),
            const SizedBox(height: 10),
            CustomButton(text: "بث إشعار عام", onPressed: _confirmSendNotification),
            const SizedBox(height: 25),
            const Align(alignment: Alignment.centerRight, child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text("إدارة النظام", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            )),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.4,
              children: [
                _buildMenuCard(context, "إضافة متجر", Icons.add_business, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddShopScreen())).then((_) => _refreshStats());
                }),
                _buildMenuCard(context, "إدارة المتاجر", Icons.settings_suggest, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageShopsScreen())).then((_) => _refreshStats());
                }),
                _buildMenuCard(context, "إدارة المستخدمين", Icons.person_search, Colors.blueAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersScreen())).then((_) => _refreshStats());
                }),
                _buildMenuCard(context, "التقارير", Icons.insights, Colors.blueGrey, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Reports()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 5),
              Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}