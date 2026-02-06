import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';
import 'favorites.dart';
import 'notifications.dart';
import 'profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 3;

  final List<Widget> _pages = [
    const ProfileScreen(),
    const NotificationsScreen(),
    const FavoritesScreen(),
    const MainContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'التنبيهات'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        ],
      ),
    );
  }
}

class MainContent extends StatefulWidget {
  const MainContent({super.key});
  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  final DbHelper _dbHelper = DbHelper();
  int? userId;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allShops = [
    {"title": "مطعم بلادي", "subtitle": "بيتك الثاني", "rating": "4.8", "image": "assets/images/food.png", "isFav": false},
    {"title": "نادي كول", "subtitle": "لياقة، قوة، وصلابة", "rating": "3.8", "image": "assets/images/gym.png", "isFav": false},
  ];
  List<Map<String, dynamic>> _filteredShops = [];

  @override
  void initState() {
    super.initState();
    _filteredShops = _allShops;
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    if (userId != null) {
      for (var shop in _allShops) {
        shop['isFav'] = await _dbHelper.isFav(userId!, shop['title']);
      }
      if (mounted) setState(() {});
    }
  }

  void _filterShops(String query) {
    setState(() {
      _filteredShops = _allShops.where((s) => s['title'].contains(query) || s['subtitle'].contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildBanner(),
            _buildSearchBar(),
            _buildCategories(), // إعادة أيقونات التصنيفات
            const SizedBox(height: 10),
            ..._filteredShops.map((shop) => _buildShopCard(shop)),
          ],
        ),
      ),
    );
  }

  // 1. البانر الكبير مع صورة خلفية
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      height: 190, // حجم كبير للمساحة
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/banner_bg.png'), // تأكد من وجود الصورة
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("مكين عالم من الخصومات", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text("اكتشف خصوماتك الحصرية الآن", style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // 2. حقل البحث
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: _filterShops,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن المتاجر.......",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // 3. التصنيفات (الأيقونات الدائرية تحت البحث)
  Widget _buildCategories() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true, // للعربية
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _categoryItem("الكل", Icons.grid_view, true),
          _categoryItem("المأكولات", Icons.fastfood, false),
          _categoryItem("صحة", Icons.favorite, false),
          _categoryItem("عناية", Icons.face, false),
          _categoryItem("متاجر", Icons.store, false),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isActive ? AppTheme.primaryRed : Colors.grey[200],
            child: Icon(icon, color: isActive ? Colors.white : Colors.black54),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 4. كرت المتجر مع زر المفضلة
  Widget _buildShopCard(Map<String, dynamic> shop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(shop['image'], height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.image))),
              ),
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () async {
                    bool res = await _dbHelper.toggleFavorite(userId!, shop);
                    setState(() => shop['isFav'] = res);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(shop['isFav'] ? Icons.favorite : Icons.favorite_border, color: shop['isFav'] ? Colors.red : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          ListTile(
            title: Text(shop['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(shop['subtitle']),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(shop['rating'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}