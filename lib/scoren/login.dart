import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'admin_dashboard.dart';
import 'home.dart';
import 'register.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem("انشاء حساب", false),
                        _buildTabItem("تسجيل الدخول", true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text("أهلاً بعودتك",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: identifierController,
                    label: "البريد الإلكتروني أو رقم الهاتف",
                    hint: "example@mail.com أو 777xxxxxx",
                    icon: Icons.person_outline,
                    validator: (v) => v!.trim().isEmpty ? "يرجى إدخال البيانات" : null,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: passwordController,
                    label: "كلمة المرور",
                    hint: "*********",
                    isPassword: _isObscured,
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isObscured = !_isObscured),
                    ),
                    validator: (v) => v!.isEmpty ? "يرجى إدخال كلمة المرور" : null,
                  ),
                  const SizedBox(height: 35),

                  CustomButton(
                    text: "تسجيل الدخول",
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        String input = identifierController.text.trim();
        String pass = passwordController.text.trim();

        // --- 1. فحص إذا كان الداخل هو الأدمن (حساب ثابت) ---
        if (input == "01" && pass == "001") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', "مدير النظام");
          await prefs.setInt('userId', 0); // رقم تعريفي خاص بالأدمن

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          }
          return; // الخروج فوراً لعدم الانتقال للكود بالأسفل
        }

        // --- 2. فحص المستخدم العادي في قاعدة البيانات ---
        var user = await DbHelper().loginCheck(input, pass);

        if (user != null) {
          if (user['isBlocked'] == 1) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("عذراً، هذا الحساب محظور")),
              );
            }
            return;
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('userId', user['id']);
          await prefs.setString('userName', user['fullName']);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("البيانات المدخلة غير صحيحة")),
            );
          }
        }
      } catch (e) {
        debugPrint("Login Error: $e");
      }
    }
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Register()));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}