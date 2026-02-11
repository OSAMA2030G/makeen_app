import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart'; // مكتبة الباركود
import '../core/app_theme.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "جاري التحميل...";
  String _userPhone = "...";
  String _userId = "0"; // سنستخدم هذا لتوليد الباركود

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "مستخدم ضيف";
      _userPhone = prefs.getString('userPhone') ?? "لا يوجد رقم جوال";
      // نأخذ الـ ID ونحوله لنص لاستخدامه في الباركود
      _userId = (prefs.getInt('userId') ?? 0).toString();
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // قسم معلومات المستخدم
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryRed,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(_userPhone, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // قسم الباركود (QR Code)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    const Text("كود التحقق الخاص بك", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 15),
                    QrImageView(
                      data: "USER_ID:$_userId", // البيانات المشفرة داخل الكود
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      foregroundColor: AppTheme.primaryRed,
                    ),
                    const SizedBox(height: 10),
                    const Text("أبرز الكود لمزود الخدمة عند الشراء", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // القائمة المختصرة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildProfileMenu(Icons.developer_mode, "دعم المطور", () {
                        _showDeveloperInfo();
                      }),
                      const Divider(height: 1),
                      _buildProfileMenu(Icons.logout, "تسجيل الخروج", () {
                        _showLogoutDialog();
                      }, isExit: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu(IconData icon, String title, VoidCallback onTap, {bool isExit = false}) {
    return ListTile(
      leading: Icon(icon, color: isExit ? Colors.red : AppTheme.primaryRed),
      title: Text(title, style: TextStyle(color: isExit ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // معلومات المطور
  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("عن المطور", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("تم تطوير هذا التطبيق بواسطة فريق مكين التقني.", textAlign: TextAlign.center),
            SizedBox(height: 15),
            Text("للدعم الفني والاستفسارات:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("support@makeen.com"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل أنت متأكد أنك تريد الخروج؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(onPressed: _logout, child: const Text("خروج", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}