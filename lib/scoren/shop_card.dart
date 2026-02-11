import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final Function() onFavTap;
  final Function() onRatingTap;
  final Function() onLocationTap;

  const ShopCard({
    super.key,
    required this.shop,
    required this.onFavTap,
    required this.onRatingTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // الجزء العلوي: الصورة والمفضلة
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  shop['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
              // زر المفضلة
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onFavTap,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    child: Icon(
                      shop['isFav'] ? Icons.favorite : Icons.favorite_border,
                      color: shop['isFav'] ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // الجزء السفلي: البيانات
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onRatingTap,
                      child: Row(
                        children: [
                          Text(shop['rating'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        ],
                      ),
                    ),
                    Text(shop['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (shop['location_url'] != null && shop['location_url'].isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: onLocationTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text("الموقع", style: TextStyle(fontSize: 12)),
                      )
                    else
                      const SizedBox(),
                    Expanded(
                      child: Text(
                        shop['subtitle'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}