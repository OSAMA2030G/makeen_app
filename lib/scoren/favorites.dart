import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("المفضلة", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildFavoriteItem("مطعم بلادي", "أفضل المأكولات العربية", "4.8", "assets/images/food.png"),
                  _buildFavoriteItem("نادي كول", "لياقة، قوة، وصلابة", "3.8", "assets/images/gym.png"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(String title, String subtitle, String rate, String img) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(img, width: 60, height: 60, fit: BoxFit.cover),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.favorite, color: AppTheme.primaryRed), // أيقونة المفضلة مفعلة
      ),
    );
  }
}