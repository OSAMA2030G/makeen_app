import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  // أضفنا هذا السطر لاستقبال المتحكم
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.isPassword = false,
    this.validator,
    this.controller, // أضفناه هنا في المنشئ
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            // ربط المتحكم بـ TextFormField الفعلي
            controller: controller,
            textAlign: TextAlign.start,
            obscureText: isPassword,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.fieldGrey,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey, size: 20) : null,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}