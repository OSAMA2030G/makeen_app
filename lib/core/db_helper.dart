import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), 'makeen_app.db');
    return await openDatabase(
        path,
        version: 2, // تم رفع الإصدار إلى 2 لأننا أضفنا جدولاً جديداً
        onCreate: (Database db, int version) async {
          await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullName TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');

          // إنشاء جدول المفضلة الجديد
          await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            shopTitle TEXT,
            shopSubtitle TEXT,
            shopImage TEXT,
            shopRating TEXT
          )
        ''');
          print("--- تم إنشاء الجداول بنجاح ---");
        },
        // هذه الدالة تنفذ إذا كان المستخدم لديه إصدار قديم من قاعدة البيانات
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE favorites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                userId INTEGER,
                shopTitle TEXT,
                shopSubtitle TEXT,
                shopImage TEXT,
                shopRating TEXT
              )
            ''');
          }
        }
    );
  }

  // --- دالات المستخدم ---
  Future<int> registerUser(Map<String, dynamic> userData) async {
    Database? dbClient = await db;
    return await dbClient!.insert('users', userData);
  }

  Future<Map<String, dynamic>?> loginCheck(String email, String password) async {
    Database? dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient!.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // --- دالات المفضلة الجديدة ---

  // إضافة أو حذف من المفضلة تلقائياً
  Future<bool> toggleFavorite(int userId, Map<String, dynamic> shopData) async {
    Database? dbClient = await db;

    // التحقق أولاً إذا كان موجوداً
    List<Map> res = await dbClient!.query('favorites',
        where: 'userId = ? AND shopTitle = ?',
        whereArgs: [userId, shopData['title']]);

    if (res.isEmpty) {
      // غير موجود -> أضفه
      await dbClient.insert('favorites', {
        'userId': userId,
        'shopTitle': shopData['title'],
        'shopSubtitle': shopData['subtitle'],
        'shopImage': shopData['image'],
        'shopRating': shopData['rating'],
      });
      return true; // تم الإضافة
    } else {
      // موجود -> احذفه
      await dbClient.delete('favorites',
          where: 'userId = ? AND shopTitle = ?',
          whereArgs: [userId, shopData['title']]);
      return false; // تم الحذف
    }
  }

  // جلب قائمة المفضلات لمستخدم معين
  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    Database? dbClient = await db;
    return await dbClient!.query('favorites', where: 'userId = ?', whereArgs: [userId]);
  }

  // التحقق من حالة متجر واحد (هل هو مفضل؟)
  Future<bool> isFav(int userId, String title) async {
    Database? dbClient = await db;
    List<Map> res = await dbClient!.query('favorites',
        where: 'userId = ? AND shopTitle = ?',
        whereArgs: [userId, title]);
    return res.isNotEmpty;
  }
}