import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_theme.dart';
// تأكد أن المسار أدناه يطابق مكان ملف login.dart في مشروعك
import 'scoren/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MakeenApp());
}

class MakeenApp extends StatelessWidget {
  const MakeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق مكين',
      theme: AppTheme.lightTheme,

      // إعدادات اللغة العربية لضمان ظهور النصوص والاتجاهات بشكل صحيح
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      locale: const Locale('ar', 'SA'),

      // هنا تم استدعاء Login() بالاسم الجديد الذي اعتمدته في ملف login.dart
      home: const Login(),
    );
  }
}