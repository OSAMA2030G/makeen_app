import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/app_theme.dart';
import '../core/db_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddShopScreen extends StatefulWidget {
  final Map<String, dynamic>? shop;

  const AddShopScreen({super.key, this.shop});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final DbHelper _dbHelper = DbHelper();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _mainImage;
  String? _existingMainImagePath;
  List<File> _galleryImages = [];
  bool _isLoading = false;

  String? _selectedCategory;
  bool _isAddingNewCat = false;
  String _discountType = 'permanent';
  List<Map<String, dynamic>> _categories = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storeDescController = TextEditingController();
  final TextEditingController _discountDescController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _newCatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _checkIfEditMode();
  }

  void _checkIfEditMode() {
    if (widget.shop != null) {
      final s = widget.shop!;
      _titleController.text = s['title'] ?? "";
      _storeDescController.text = s['store_description'] ?? "";
      _discountDescController.text = s['discount_description'] ?? "";
      _percentageController.text = s['discount_percentage'] ?? "";
      _locationController.text = s['location_url'] ?? "";
      _selectedCategory = s['category_name'];
      _discountType = s['discount_type'] ?? 'permanent';
      _expiryDateController.text = s['expiry_date'] ?? "";
      _existingMainImagePath = s['image'];
    }
  }

  void _loadCategories() async {
    var cats = await _dbHelper.getAllCategories();
    setState(() => _categories = cats);
  }

  Future<String> _saveImageToAppDirectory(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = "${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}";
    final File savedImage = await image.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() {
      _mainImage = File(image.path);
      _existingMainImagePath = null;
    });
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _galleryImages.addAll(images.map((e) => File(e.path))));
    }
  }

  // --- الدالة المعدلة لإرسال إشعار تلقائي عند الحفظ ---
  void _saveShop() async {
    if (_formKey.currentState!.validate()) {
      if (_mainImage == null && _existingMainImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار الصورة الأساسية")));
        return;
      }

      setState(() => _isLoading = true);

      try {
        String finalImagePath = _mainImage != null
            ? await _saveImageToAppDirectory(_mainImage!)
            : _existingMainImagePath!;

        String finalCategory = _isAddingNewCat ? _newCatController.text.trim() : _selectedCategory!;

        if (_isAddingNewCat) {
          await _dbHelper.insertCategory({'name': finalCategory, 'image': 'assets/images/default_cat.png'});
        }

        Map<String, dynamic> shopData = {
          'title': _titleController.text.trim(),
          'store_description': _storeDescController.text.trim(),
          'discount_description': _discountDescController.text.trim(),
          'discount_percentage': _percentageController.text.trim(),
          'image': finalImagePath,
          'location_url': _locationController.text.trim(),
          'category_name': finalCategory,
          'discount_type': _discountType,
          'expiry_date': _discountType == 'temporary' ? _expiryDateController.text : null,
          'rating': widget.shop != null ? widget.shop!['rating'] : "5.0",
          'views_count': widget.shop != null ? widget.shop!['views_count'] : 0,
          'status': widget.shop != null ? widget.shop!['status'] : 1,
        };

        if (widget.shop == null) {
          // 1. حالة إضافة متجر جديد
          int shopId = await _dbHelper.insertShop(shopData);
          for (File img in _galleryImages) {
            String galleryPath = await _saveImageToAppDirectory(img);
            await _dbHelper.insertImagesToGallery(shopId, [galleryPath]);
          }

          // بث إشعار تلقائي بالإضافة
          await _dbHelper.sendNotification(
            "متجر جديد في مكين! 😍",
            "تم إضافة ${_titleController.text.trim()} في قسم $finalCategory. اكتشف العروض الآن!",
          );

        } else {
          // 2. حالة التعديل
          await _dbHelper.updateShop(widget.shop!['id'], shopData);
          for (File img in _galleryImages) {
            String galleryPath = await _saveImageToAppDirectory(img);
            await _dbHelper.insertImagesToGallery(widget.shop!['id'], [galleryPath]);
          }

          // بث إشعار تلقائي بالتحديث
          await _dbHelper.sendNotification(
            "تحديث في العروض ✨",
            "قام متجر ${_titleController.text.trim()} بتحديث تفاصيل عروضه، ألقِ نظرة!",
          );
        }

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.shop == null ? "تم الحفظ وإرسال التنبيه!" : "تم التحديث بنجاح!"),
                backgroundColor: Colors.green,
              )
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint("Error saving shop: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.shop == null ? "إضافة عرض جديد" : "تعديل العرض",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("الصورة الأساسية للعرض", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 20),

              CustomTextField(label: "اسم المتجر", hint: "مثلاً: مطعم مأكولاتنا", controller: _titleController, icon: Icons.store_rounded),
              const SizedBox(height: 15),

              CustomTextField(label: "عن المتجر (الوصف العام)", hint: "اكتب نبذة عن المتجر هنا...", controller: _storeDescController, icon: Icons.info_outline),
              const SizedBox(height: 15),

              const Text("تصنيف المتجر", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),

              if (_isAddingNewCat) ...[
                const SizedBox(height: 15),
                CustomTextField(label: "اسم الصنف الجديد", hint: "أدخل النوع هنا", controller: _newCatController, icon: Icons.create_new_folder_rounded),
              ],

              const SizedBox(height: 15),
              CustomTextField(label: "وصف التخفيض", hint: "مثلاً: خصم بمناسبة الافتتاح", controller: _discountDescController, icon: Icons.local_offer_rounded),
              const SizedBox(height: 15),
              CustomTextField(label: "نسبة التخفيض", hint: "مثلاً: 25%", controller: _percentageController, icon: Icons.percent, keyboardType: TextInputType.number),

              const SizedBox(height: 15),
              const Text("نوع التخفيض", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("دائم", style: TextStyle(fontSize: 14)),
                      value: "permanent",
                      groupValue: _discountType,
                      activeColor: AppTheme.primaryRed,
                      onChanged: (val) => setState(() => _discountType = val.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("مؤقت", style: TextStyle(fontSize: 14)),
                      value: "temporary",
                      groupValue: _discountType,
                      activeColor: AppTheme.primaryRed,
                      onChanged: (val) => setState(() => _discountType = val.toString()),
                    ),
                  ),
                ],
              ),

              if (_discountType == "temporary") ...[
                const SizedBox(height: 10),
                CustomTextField(
                  label: "تاريخ انتهاء العرض",
                  hint: "اختر التاريخ من هنا",
                  controller: _expiryDateController,
                  icon: Icons.calendar_today,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _expiryDateController.text = picked.toString().split(' ')[0];
                    }
                  },
                ),
              ],

              const SizedBox(height: 15),
              CustomTextField(label: "رابط الموقع", hint: "رابط Google Maps", controller: _locationController, icon: Icons.location_on_rounded),

              const SizedBox(height: 25),
              const Text("صور المعرض (إضافية داخل المتجر)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              _buildGalleryPicker(),

              const SizedBox(height: 40),
              CustomButton(
                  text: widget.shop == null ? "حفظ ونشر العرض" : "حفظ التعديلات",
                  onPressed: _isLoading ? () {} : _saveShop
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickMainImage,
      child: Container(
        width: double.infinity, height: 180,
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 2)
        ),
        child: _mainImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_mainImage!, fit: BoxFit.cover))
            : (_existingMainImagePath != null
            ? ClipRRect(borderRadius: BorderRadius.circular(18),
            child: _existingMainImagePath!.startsWith('assets/')
                ? Image.asset(_existingMainImagePath!, fit: BoxFit.cover)
                : Image.file(File(_existingMainImagePath!), fit: BoxFit.cover))
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 60, color: Colors.grey),
            Text("اختر صورة الواجهة", style: TextStyle(color: Colors.grey)),
          ],
        )),
      ),
    );
  }

  Widget _buildGalleryPicker() {
    return Column(
      children: [
        if (_galleryImages.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3))
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_galleryImages[index], fit: BoxFit.cover)),
                  ),
                  Positioned(
                    top: 0, left: 5,
                    child: GestureDetector(
                      onTap: () => setState(() => _galleryImages.removeAt(index)),
                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 15, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickGalleryImages,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryRed, style: BorderStyle.solid),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.collections_rounded, color: AppTheme.primaryRed),
                SizedBox(width: 10),
                Text("إضافة المزيد من الصور", style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _isAddingNewCat ? "new" : _selectedCategory,
      isExpanded: true,
      hint: const Text("اختر نوع المتجر"),
      items: [
        ..._categories.map((cat) => DropdownMenuItem(value: cat['name'] as String, child: Text(cat['name']))).toList(),
        const DropdownMenuItem(value: "new", child: Text("➕ صنف جديد غير موجود", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
      ],
      onChanged: (val) => setState(() {
        _isAddingNewCat = (val == "new");
        _selectedCategory = _isAddingNewCat ? null : val;
      }),
      decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!))
      ),
    );
  }
}