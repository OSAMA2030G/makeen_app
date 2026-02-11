import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final GlobalKey<_MainContentState> _mainContentKey = GlobalKey<_MainContentState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
          index: _currentIndex,
          children: [
            const ProfileScreen(),
            const NotificationsScreen(),
            const FavoritesScreen(),
            MainContent(key: _mainContentKey),
          ]
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 3) {
            _mainContentKey.currentState?._loadData();
          }
        },
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

  String _selectedCategory = "الكل";
  List<Map<String, dynamic>> _allShops = [];
  List<Map<String, dynamic>> _filteredShops = [];
  List<Map<String, dynamic>> _dynamicCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    var dbCats = await _dbHelper.getAllCategories();
    var dbShops = await _dbHelper.getActiveShops();
    List<Map<String, dynamic>> loadedShops = List.from(dbShops);

    if (userId != null) {
      for (int i = 0; i < loadedShops.length; i++) {
        bool isFav = await _dbHelper.isFav(userId!, loadedShops[i]['id']);
        Map<String, dynamic> shopWithFav = Map.from(loadedShops[i]);
        shopWithFav['isFav'] = isFav;
        loadedShops[i] = shopWithFav;
      }
    }

    if (mounted) {
      setState(() {
        _dynamicCategories = dbCats;
        _allShops = loadedShops;
        _runFilter();
      });
    }
  }

  void _runFilter() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredShops = _allShops.where((shop) {
        bool matchesSearch = shop['title'].toLowerCase().contains(query) ||
            (shop['store_description']?.toLowerCase().contains(query) ?? false);
        bool matchesCategory = (_selectedCategory == "الكل") || (shop['category_name'] == _selectedCategory);
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // --- الترويسة الفخمة مع شعار أكثر وضوحاً ---
  Widget _buildHeader() {
    return Stack(
      children: [
        // الخلفية الأساسية
        Container(
          width: double.infinity,
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
          ),
        ),
        // الشعار المموه (تم رفع الوضوح)
        Positioned(
          top: -10,
          left: -20,
          child: Opacity(
            opacity: 0.12, // زيادة الوضوح هنا
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(Icons.local_mall, size: 180, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: -30,
          child: Opacity(
            opacity: 0.08, // زيادة الوضوح هنا أيضاً
            child: Transform.rotate(
              angle: 0.4,
              child: const Icon(Icons.shopping_bag, size: 220, color: Colors.white),
            ),
          ),
        ),
        // المحتوى
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 40, 25, 0),
          child: Column(
            children: [
              const Text(
                "مكين",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 15, color: Colors.black38, offset: Offset(0, 5))],
                ),
              ),
              const Text(
                "دليلك للشراء بدون متاعب",
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 25),
              // حقل البحث
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _runFilter(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "ابحث عن عروضك المفضلة...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white, size: 28),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "استكشف عالمك الحصري من الخصومات",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 25), // مسافة بسيطة قبل التصنيفات
              _buildCategories(),
              const SizedBox(height: 10),
              if (_filteredShops.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text("لا توجد نتائج بحث"))
              else
                ..._filteredShops.map((shop) => ShopCardWithPulse(
                  shop: shop,
                  onTap: () => _showExpandedShop(shop),
                  showCategory: _selectedCategory == "الكل",
                  onFav: () async {
                    if (userId != null) {
                      await _dbHelper.toggleFavorite(userId!, shop['id']);
                      _loadData();
                    }
                  },
                )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- قسم التصنيفات وتفاصيل المتجر ---

  Widget _buildCategories() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _dynamicCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _categoryItem("الكل", Icons.grid_view);
          var cat = _dynamicCategories[index - 1];
          return _categoryItem(cat['name'], Icons.store_mall_directory);
        },
      ),
    );
  }

  Widget _categoryItem(String label, IconData icon) {
    bool isActive = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          _runFilter();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryRed : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: isActive ? Colors.white : Colors.black54, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _showExpandedShop(Map<String, dynamic> shop) async {
    bool isNewView = await _dbHelper.incrementViews(shop['id']);
    if (isNewView && mounted) {
      setState(() { shop['views_count'] = (shop['views_count'] ?? 0) + 1; });
    }
    int currentPage = 0;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        child: SizedBox(
                          height: 300,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _dbHelper.getShopGallery(shop['id']),
                            builder: (context, snapshot) {
                              List<String> allImages = [shop['image']];
                              if (snapshot.hasData) { allImages.addAll(snapshot.data!.map((e) => e['imagePath'] as String)); }
                              return Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  PageView.builder(
                                    reverse: true,
                                    itemCount: allImages.length,
                                    onPageChanged: (index) => setStateDialog(() => currentPage = index),
                                    itemBuilder: (context, index) {
                                      return allImages[index].startsWith('assets')
                                          ? Image.asset(allImages[index], fit: BoxFit.cover)
                                          : Image.file(File(allImages[index]), fit: BoxFit.cover);
                                    },
                                  ),
                                  if (allImages.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(allImages.length, (index) => AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          height: 8, width: currentPage == index ? 22 : 8,
                                          decoration: BoxDecoration(color: currentPage == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                                        )),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(top: 20, left: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.close, color: Colors.white)))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("${shop['views_count']} مشاهدة", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 15),
                          Text(shop['store_description'] ?? "", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          const Divider(height: 30),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15)),
                            child: Row(children: [const Icon(Icons.local_offer, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text(shop['discount_description'] ?? "", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))]),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(shop['location_url'] ?? "");
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                            icon: const Icon(Icons.location_on, color: Colors.white),
                            label: const Text("فتح موقع المتجر", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShopCardWithPulse extends StatefulWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;
  final VoidCallback onFav;
  final bool showCategory;

  const ShopCardWithPulse({super.key, required this.shop, required this.onTap, required this.onFav, required this.showCategory});

  @override
  State<ShopCardWithPulse> createState() => _ShopCardWithPulseState();
}

class _ShopCardWithPulseState extends State<ShopCardWithPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: widget.shop['image'].startsWith('assets')
                        ? Image.asset(widget.shop['image'], height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(widget.shop['image']), height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  if (widget.shop['discount_percentage'] != null && widget.shop['discount_percentage'] != "")
                    Positioned(
                      top: 15, right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), borderRadius: BorderRadius.circular(12)),
                        child: Text("خصم ${widget.shop['discount_percentage']}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(widget.shop['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                          GestureDetector(onTap: widget.onFav, child: Icon((widget.shop['isFav'] ?? false) ? Icons.favorite : Icons.favorite_border, color: (widget.shop['isFav'] ?? false) ? Colors.red : Colors.grey, size: 26)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.shop['discount_description'] ?? "", style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}