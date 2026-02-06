import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("التنبيهات", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1F0),
                    child: Icon(Icons.notifications_active, color: AppTheme.primaryRed),
                  ),
                  title: const Text("خصم جديد!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("احصل على خصم 20% في مطعم بلادي لفترة محدودة", style: TextStyle(fontSize: 12)),
                  trailing: const Text("منذ ساعة", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}