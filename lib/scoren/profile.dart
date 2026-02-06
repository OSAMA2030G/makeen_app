import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // مكتبة الجلسة
import '../core/app_theme.dart';
import 'login.dart'; // للعودة لصفحة الدخول عند الخروج

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "جاري التحميل...";
  String _userEmail = "...";

  @override
  void initState() {
    super.initState();
    _loadUserData(); // جلب البيانات فور فتح الصفحة
  }

  // دالة قراءة البيانات المحفوظة في الهاتف
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "مستخدم ضيف";
      _userEmail = prefs.getString('userEmail') ?? "guest@example.com";
    });
  }

  // دالة تسجيل الخروج
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // حذف كل البيانات المحفوظة (الجلسة)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
            (route) => false, // حذف كل الصفحات السابقة من الذاكرة
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // صورة المستخدم والبيانات الحقيقية
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryRed,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // القائمة
            _buildProfileMenu(Icons.person_outline, "تعديل الملف الشخصي", () {}),
            _buildProfileMenu(Icons.settings_outlined, "الإعدادات", () {}),
            _buildProfileMenu(Icons.help_outline, "مركز المساعدة", () {}),
            _buildProfileMenu(Icons.logout, "تسجيل الخروج", () {
              _showLogoutDialog(); // إظهار تأكيد الخروج
            }, isExit: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(IconData icon, String title, VoidCallback onTap, {bool isExit = false}) {
    return ListTile(
      leading: Icon(icon, color: isExit ? Colors.red : Colors.black87),
      title: Text(title, style: TextStyle(color: isExit ? Colors.red : Colors.black87, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // نافذة تأكيد تسجيل الخروج
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل أنت متأكد أنك تريد الخروج من التطبيق؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(onPressed: _logout, child: const Text("خروج", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}