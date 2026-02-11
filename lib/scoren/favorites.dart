import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/db_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _favoriteShops = [];
  int? userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // هذه الدالة تضمن تحديث البيانات عند العودة للشاشة
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      var favs = await _dbHelper.getFavorites(userId!);
      if (mounted) {
        setState(() {
          _favoriteShops = favs;
          _isLoading = false;
        });
      }
    }
  }

  void _showExpandedShop(Map<String, dynamic> shop) {
    // زيادة عدد المشاهدات حتى عند الفتح من المفضلة
    _dbHelper.incrementViews(shop['id']);

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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
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
                              if (snapshot.hasData) {
                                allImages.addAll(snapshot.data!.map((e) => e['imagePath'] as String));
                              }
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
                                        children: List.generate(allImages.length, (index) {
                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            height: 8,
                                            width: currentPage == index ? 22 : 8,
                                            decoration: BoxDecoration(
                                              color: currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (shop['discount_percentage'] != null && shop['discount_percentage'] != "")
                        Positioned(
                          top: 20, right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                            ),
                            child: Text(
                              "خصم ${shop['discount_percentage']}%",
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 20, left: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.close, color: Colors.white)),
                        ),
                      ),
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
                          const SizedBox(height: 10),
                          Text(shop['store_description'] ?? "", style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.4)),
                          const Divider(height: 30),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                const Icon(Icons.local_offer, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(child: Text(shop['discount_description'] ?? "", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(shop['location_url'] ?? "");
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                            icon: const Icon(Icons.location_on, color: Colors.white),
                            label: const Text("فتح موقع المتجر", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("المفضلة", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFavorites,
          color: AppTheme.primaryRed,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoriteShops.isEmpty
              ? ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("قائمة المفضلة فارغة", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          )
              : ListView.builder(
            itemCount: _favoriteShops.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final shop = _favoriteShops[index];
              return FavoriteCardWithPulse(
                shop: shop,
                onTap: () => _showExpandedShop(shop),
                onRemove: () async {
                  await _dbHelper.toggleFavorite(userId!, shop['id']);
                  setState(() {
                    _favoriteShops.removeAt(index);
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class FavoriteCardWithPulse extends StatefulWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteCardWithPulse({
    super.key,
    required this.shop,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<FavoriteCardWithPulse> createState() => _FavoriteCardWithPulseState();
}

class _FavoriteCardWithPulseState extends State<FavoriteCardWithPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: widget.shop['image'].startsWith('assets')
                        ? Image.asset(widget.shop['image'], width: 85, height: 85, fit: BoxFit.cover)
                        : Image.file(File(widget.shop['image']), width: 85, height: 85, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop['title'],
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF2D3436)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.shop['discount_description'] ?? "",
                          style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.shop['category_name'] ?? "",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppTheme.primaryRed, size: 28),
                    onPressed: widget.onRemove,
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