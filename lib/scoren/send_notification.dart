import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';

class SendNotification extends StatefulWidget {
  const SendNotification({super.key});

  @override
  State<SendNotification> createState() => _SendNotificationState();
}

class _SendNotificationState extends State<SendNotification> {
  // كائنات التحكم في النصوص المدخلة
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _dbHelper = DbHelper();

  // دالة الإرسال: تتحقق من البيانات ثم تخزنها في قاعدة البيانات
  void _submitNotification() async {
    String title = _titleController.text.trim();
    String body = _bodyController.text.trim();

    // منع الإرسال إذا كانت الحقول فارغة
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى كتابة عنوان ورسالة التنبيه")),
      );
      return;
    }

    // حفظ التنبيه في قاعدة البيانات (جدول notifications)
    await _dbHelper.sendNotification(title, body);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال التنبيه بنجاح")),
      );
      Navigator.pop(context); // العودة للوحة التحكم بعد الإرسال
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إرسال تنبيه جديد"),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // حقل العنوان
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "عنوان التنبيه",
                hintText: "مثلاً: عرض خاص من مطعم زيد",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // حقل نص الرسالة
            TextField(
              controller: _bodyController,
              maxLines: 4, // جعل الحقل يتسع لرسالة طويلة
              decoration: const InputDecoration(
                labelText: "نص الرسالة",
                hintText: "اكتب تفاصيل العرض هنا...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            // زر الإرسال النهائي
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                onPressed: _submitNotification,
                child: const Text("إرسال الآن", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}