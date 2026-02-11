import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart'; // استيراد مساعد قاعدة البيانات

// تم تغيير الاسم إلى NotificationsScreen ليتطابق مع ما تبحث عنه الصفحة الرئيسية
// وتم تحويله إلى StatefulWidget ليتمكن من تحديث البيانات جلبها من قاعدة البيانات
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // تعريف متغيرات جلب البيانات
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _notificationsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications(); // استدعاء دالة الجلب فور تشغيل الصفحة
  }

  // دالة جلب الإشعارات الحقيقية من قاعدة البيانات
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    // جلب البيانات باستخدام الدالة التي وضعناها في DbHelper
    final data = await _dbHelper.getNotifications();

    setState(() {
      _notificationsList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("التنبيهات", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        elevation: 0,
      ),
      // استخدام RefreshIndicator للسماح للمستخدم بسحب الصفحة لتحديث الإشعارات
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppTheme.primaryRed,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
            : _notificationsList.isEmpty
            ? _buildEmptyState() // عرض واجهة "لا توجد تنبيهات"
            : _buildNotificationsList(), // عرض القائمة الحقيقية
      ),
    );
  }

  // ويدجت بناء قائمة الإشعارات
  Widget _buildNotificationsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _notificationsList.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 20),
      itemBuilder: (context, index) {
        final item = _notificationsList[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFF1F0),
            child: Icon(Icons.notifications_active, color: AppTheme.primaryRed, size: 20),
          ),
          // عرض العنوان الحقيقي المخزن بواسطة الأدمن
          title: Text(
            item['title'] ?? "تنبيه",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          // عرض نص التنبيه الحقيقي
          subtitle: Text(
            item['body'] ?? "",
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          // عرض التاريخ (يمكنك لاحقاً تحسينه ليظهر "منذ ساعة" باستخدام مكتبة intl)
          trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        );
      },
    );
  }

  // واجهة تظهر في حال كان جدول التنبيهات فارغاً
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("لا توجد تنبيهات جديدة حالياً",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}