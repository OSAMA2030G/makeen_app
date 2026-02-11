import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/db_helper.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController(); // حقل الهاتف الجديد
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isObscured = true;
  bool _isConfirmObscured = true;

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
                      height: 200, // عدلت الحجم قليلاً ليتناسب مع الحقول الإضافية
                      fit: BoxFit.contain,
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
                        _buildTabItem("انشاء حساب", true),
                        _buildTabItem("تسجيل الدخول", false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text("إنشاء حساب جديد",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: nameController,
                    label: "الاسم الكامل",
                    hint: "أدخل اسمك الثلاثي",
                    icon: Icons.person_outline,
                    validator: (v) => v!.trim().isEmpty ? "يرجى إدخال الاسم" : null,
                  ),
                  const SizedBox(height: 15),

                  // حقل البريد الإلكتروني
                  CustomTextField(
                    controller: emailController,
                    label: "البريد الالكتروني",
                    hint: "example@mail.com",
                    icon: Icons.email_outlined,
                    validator: (v) {
                      if (v!.trim().isEmpty) return "يرجى إدخال البريد";
                      if (!v.contains('@')) return "صيغة البريد غير صحيحة";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // حقل رقم الهاتف الجديد (متوافق مع DB)
                  CustomTextField(
                    controller: phoneController,
                    label: "رقم الهاتف",
                    hint: "777000000",
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.trim().isEmpty ? "يرجى إدخال رقم الهاتف" : null,
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
                    validator: (v) => v!.trim().length < 6 ? "كلمة المرور قصيرة جداً" : null,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: confirmPasswordController,
                    label: "تأكيد كلمة المرور",
                    hint: "*********",
                    isPassword: _isConfirmObscured,
                    icon: Icons.lock_reset,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmObscured ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                    ),
                    validator: (v) => v!.trim() != passwordController.text.trim() ? "كلمة المرور غير متطابقة" : null,
                  ),
                  const SizedBox(height: 30),

                  CustomButton(
                    text: "إنشاء حساب",
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // تجهيز البيانات وفقاً لجدول users الجديد
      Map<String, dynamic> newUser = {
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(), // الحقل الجديد
        'password': passwordController.text.trim(),
        'isBlocked': 0, // قيمة افتراضية
      };

      try {
        // تأكد أن دالة registerUser في DbHelper تستخدم جدول users
        int result = await DbHelper().insertUser(newUser);
        if (result > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")),
            );
            Navigator.pop(context); // العودة لتسجيل الدخول
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("البريد أو رقم الهاتف مسجل مسبقاً")),
          );
        }
      }
    }
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) Navigator.pop(context);
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