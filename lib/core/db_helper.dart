import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {

  // جلب المستخدمين مع إحصائيات بسيطة عن نشاطهم (عدد المفضلات لديهم)
  Future<List<Map<String, dynamic>>> getAllUsersWithActivity() async {
    Database dbClient = await database;
    return await dbClient.rawQuery('''
      SELECT u.*, 
      (SELECT COUNT(*) FROM favorites f WHERE f.userId = u.id) as activity_count
      FROM users u
      ORDER BY u.id DESC
    ''');
  }

  // تحديث حالة الحظر
  Future<int> updateUserBlockStatus(int id, int isBlocked) async {
    Database dbClient = await database;
    return await dbClient.update('users', {'isBlocked': isBlocked}, where: 'id = ?', whereArgs: [id]);
  }

  // إرسال رسالة خاصة لمستخدم معين (نستخدم جدول الإشعارات مع إضافة حقل userId إذا أردت تخصيصها مستقبلاً،
  // حالياً سنرسلها كإشعار عام بذكر اسم المستخدم في البداية لتبسيط الكود لك)
  Future<int> sendPrivateNotification(String title, String body) async {
    return await sendNotification(title, body);
  }

  static Database? _db;

  // قائمة تخزين المتاجر التي تمت مشاهدتها خلال الجلسة الحالية
  // ملاحظة: تساعد في منع تكرار احتساب المشاهدة لنفس المتجر حتى يغلق المستخدم التطبيق
  static final Set<int> _viewedShopsInSession = {};

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), "makeen_pro_v1.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // تفعيل المفاتيح الخارجية لضمان حذف البيانات المرتبطة تلقائياً (مثل الصور عند حذف المتجر)
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  _onCreate(Database db, int version) async {
    // 1. جدول المستخدمين
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, fullName TEXT, email TEXT UNIQUE, phone TEXT UNIQUE, password TEXT, isBlocked INTEGER DEFAULT 0)');

    // 2. جدول التصنيفات
    await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, image TEXT)');

    // 3. جدول المتاجر (يحتوي على تفاصيل العرض والإحصائيات)
    await db.execute('''
      CREATE TABLE shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        store_description TEXT, 
        discount_description TEXT, 
        discount_percentage TEXT, 
        image TEXT,
        location_url TEXT,
        rating TEXT DEFAULT "0.0",
        category_name TEXT,
        discount_type TEXT,
        expiry_date TEXT,
        views_count INTEGER DEFAULT 0,
        status INTEGER DEFAULT 1, 
        FOREIGN KEY (category_name) REFERENCES categories (name)
      )
    ''');

    // 4. جدول معرض الصور (صور إضافية للمتجر)
    await db.execute('''
      CREATE TABLE shop_gallery (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopId INTEGER,
        imagePath TEXT,
        FOREIGN KEY (shopId) REFERENCES shops (id) ON DELETE CASCADE
      )
    ''');

    // 5. جدول المفضلة
    await db.execute('CREATE TABLE favorites (id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, shopId INTEGER)');

    // 6. [جديد] جدول التنبيهات (لحفظ الرسائل التي يرسلها الأدمن للمستخدمين)
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,       -- عنوان التنبيه
        body TEXT,        -- محتوى الرسالة
        date TEXT,        -- وقت الإرسال
        isRead INTEGER DEFAULT 0 -- 0 للرسائل الجديدة
      )
    ''');
  }

  // --- دوال التنبيهات (Notifications) ---

  // دالة يستخدمها الأدمن لحفظ تنبيه جديد
  Future<int> sendNotification(String title, String body) async {
    Database dbClient = await database;
    return await dbClient.insert("notifications", {
      "title": title,
      "body": body,
      "date": DateTime.now().toString(),
      "isRead": 0
    });
  }

  // دالة يستخدمها التطبيق لعرض الإشعارات للمستخدم (مرتبة من الأحدث)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    Database dbClient = await database;
    return await dbClient.query("notifications", orderBy: "id DESC");
  }

  // --- دوال إحصائيات وتقارير الأدمن ---

  Future<int> getUsersCount() async {
    Database dbClient = await database;
    return Sqflite.firstIntValue(await dbClient.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
  }

  Future<int> getShopsCount() async {
    Database dbClient = await database;
    return Sqflite.firstIntValue(await dbClient.rawQuery('SELECT COUNT(*) FROM shops')) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getShopsReport() async {
    Database dbClient = await database;
    return await dbClient.rawQuery('''
      SELECT s.id, s.title, s.views_count, s.image,
      (SELECT COUNT(*) FROM favorites f WHERE f.shopId = s.id) as fav_count
      FROM shops s ORDER BY s.views_count DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getUsersInterestedInShop(int shopId) async {
    Database dbClient = await database;
    return await dbClient.rawQuery('''
      SELECT u.fullName, u.phone, u.email 
      FROM users u
      INNER JOIN favorites f ON u.id = f.userId
      WHERE f.shopId = ?
    ''', [shopId]);
  }

  // --- دوال الأدمن (Admin Ops) ---

  Future<int> updateShop(int id, Map<String, dynamic> data) async {
    Database dbClient = await database;
    return await dbClient.update('shops', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateShopStatus(int id, int status) async {
    Database dbClient = await database;
    return await dbClient.update('shops', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllShops() async {
    Database dbClient = await database;
    return await dbClient.query("shops", orderBy: "id DESC");
  }

  Future<int> insertShop(Map<String, dynamic> data) async {
    Database dbClient = await database;
    return await dbClient.insert("shops", data);
  }

  Future<int> insertCategory(Map<String, dynamic> data) async {
    Database dbClient = await database;
    return await dbClient.insert("categories", data);
  }

  Future<int> deleteCategory(int id) async {
    Database dbClient = await database;
    return await dbClient.delete("categories", where: "id = ?", whereArgs: [id]);
  }

  // --- دوال المستخدم (User Ops) ---

  Future<List<Map<String, dynamic>>> getActiveShops() async {
    Database dbClient = await database;
    String currentDate = DateTime.now().toString().split(' ')[0];
    return await dbClient.rawQuery('''
      SELECT * FROM shops 
      WHERE status = 1 AND (
        discount_type = 'permanent' 
        OR (discount_type = 'temporary' AND expiry_date >= ?)
      )
      ORDER BY id DESC
    ''', [currentDate]);
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    Database dbClient = await database;
    return await dbClient.rawQuery('''
      SELECT shops.*, 1 as isFav 
      FROM shops 
      INNER JOIN favorites ON shops.id = favorites.shopId 
      WHERE favorites.userId = ? AND shops.status = 1
    ''', [userId]);
  }

  Future<bool> incrementViews(int shopId) async {
    if (_viewedShopsInSession.contains(shopId)) return false;
    Database dbClient = await database;
    await dbClient.rawUpdate('UPDATE shops SET views_count = views_count + 1 WHERE id = ?', [shopId]);
    _viewedShopsInSession.add(shopId);
    return true;
  }

  // --- دوال المساعدة والأمان ---

  Future<Map<String, dynamic>?> loginCheck(String identifier, String password) async {
    Database dbClient = await database;
    var result = await dbClient.query("users",
        where: "(email = ? OR phone = ?) AND password = ?",
        whereArgs: [identifier, identifier, password]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertUser(Map<String, dynamic> data) async {
    Database dbClient = await database;
    return await dbClient.insert("users", data);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    Database dbClient = await database;
    return await dbClient.query("categories");
  }

  Future<bool> isFav(int userId, int shopId) async {
    Database dbClient = await database;
    var result = await dbClient.query("favorites", where: "userId = ? AND shopId = ?", whereArgs: [userId, shopId]);
    return result.isNotEmpty;
  }

  Future<bool> toggleFavorite(int userId, int shopId) async {
    Database dbClient = await database;
    var result = await dbClient.query("favorites", where: "userId = ? AND shopId = ?", whereArgs: [userId, shopId]);
    if (result.isEmpty) {
      await dbClient.insert("favorites", {"userId": userId, "shopId": shopId});
      return true;
    } else {
      await dbClient.delete("favorites", where: "usernpm -vId = ? AND shopId = ?", whereArgs: [userId, shopId]);
      return false;
    }
  }

  Future<void> insertImagesToGallery(int shopId, List<String> imagePaths) async {
    Database dbClient = await database;
    for (String path in imagePaths) {
      await dbClient.insert("shop_gallery", {"shopId": shopId, "imagePath": path});
    }
  }

  Future<List<Map<String, dynamic>>> getShopGallery(int shopId) async {
    Database dbClient = await database;
    return await dbClient.query("shop_gallery", where: "shopId = ?", whereArgs: [shopId]);
  }

  static void clearSessionViews() {
    _viewedShopsInSession.clear();
  }
}