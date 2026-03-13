import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanadi/core/constants/app_colors.dart';
import 'package:http/http.dart' as http;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '100');
  final _unitValueController = TextEditingController(text: '1');

  File? _selectedImage;
  String? _selectedCategoryId;
  String _selectedUnit = 'kg';
  bool _isAvailable = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _categories = [];

  final List<Map<String, String>> _units = [
    {'id': 'kg', 'ar': 'كيلوجرام', 'en': 'kg'},
    {'id': 'g', 'ar': 'جرام', 'en': 'g'},
    {'id': 'piece', 'ar': 'قطعة', 'en': 'piece'},
    {'id': 'pack', 'ar': 'عبوة', 'en': 'pack'},
    {'id': 'bottle', 'ar': 'زجاجة', 'en': 'bottle'},
    {'id': 'can', 'ar': 'علبة', 'en': 'can'},
    {'id': 'liter', 'ar': 'لتر', 'en': 'liter'},
    {'id': 'ml', 'ar': 'مل', 'en': 'ml'},
  ];

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      debugPrint('🔍 Loading categories...');

      final snapshot = await FirebaseFirestore.instance
          .collection('grocery_categories')
          .where('isActive', isEqualTo: true)
          .get(); // ⬅️ حذفنا .orderBy('order')

      final categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nameAr': doc['nameAr'],
          'nameEn': doc['nameEn'],
          'order': doc['order'] ?? 999, // للترتيب
        };
      }).toList();

      // ترتيب يدوي
      categories
          .sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      debugPrint('✅ Loaded ${categories.length} categories');

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل التصنيفات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _stockController.dispose();
    _unitValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة للمنتج'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار التصنيف'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageName = 'product_$timestamp.png';

      // 1. Upload image to Supabase
      final imageUrl = await _uploadImageToSupabase(_selectedImage!, imageName);

      // 2. Parse prices
      final price = double.parse(_priceController.text.trim());
      final oldPriceText = _oldPriceController.text.trim();
      final oldPrice =
          oldPriceText.isNotEmpty ? double.parse(oldPriceText) : null;

      // 3. Save to Firestore
      final productData = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'descriptionAr': _descArController.text.trim(),
        'descriptionEn': _descEnController.text.trim(),
        'price': price,
        'oldPrice': oldPrice,
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
        'unit': _selectedUnit,
        'unitValue': double.parse(_unitValueController.text.trim()),
        'isAvailable': _isAvailable,
        'stockQuantity': int.parse(_stockController.text.trim()),
        'rating': 0.0,
        'reviewsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('grocery_products')
          .add(productData);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المنتج بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadImageToSupabase(File imageFile, String fileName) async {
    const supabaseUrl = 'https://pljrxqzinvdcyxffablj.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsanJ4cXppbnZkY3l4ZmZhYmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MjAwMjcsImV4cCI6MjA4Mjk5NjAyN30.d_3_rgPfSBhxQgHu3Ht8wuOQMBtLCKtd9DNBjFo3tgc';

    final filePath = 'grocery/products/$fileName';
    final uploadUrl = '$supabaseUrl/storage/v1/object/images/$filePath';

    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'image/png',
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return '$supabaseUrl/storage/v1/object/public/images/$filePath';
    } else {
      throw Exception('فشل رفع الصورة: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🛒 إضافة منتج جديد',
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // زرار refresh للتصنيفات
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadCategories,
            tooltip: 'تحديث التصنيفات',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isLarge ? 32 : 20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                _buildImagePicker(isLarge),
                SizedBox(height: isLarge ? 24 : 20.h),

                // Category Dropdown
                _buildCategoryDropdown(isLarge),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Arabic Name
                _buildTextField(
                  controller: _nameArController,
                  label: 'اسم المنتج بالعربية *',
                  hint: 'مثال: طماطم',
                  icon: Icons.text_fields,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // English Name
                _buildTextField(
                  controller: _nameEnController,
                  label: 'اسم المنتج بالإنجليزية *',
                  hint: 'Example: Tomatoes',
                  icon: Icons.translate,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Arabic Description
                _buildTextField(
                  controller: _descArController,
                  label: 'الوصف بالعربية',
                  hint: 'وصف قصير للمنتج...',
                  icon: Icons.description,
                  maxLines: 2,
                  isLarge: isLarge,
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // English Description
                _buildTextField(
                  controller: _descEnController,
                  label: 'الوصف بالإنجليزية',
                  hint: 'Short description...',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                  isLarge: isLarge,
                ),
                SizedBox(height: isLarge ? 24 : 20.h),

                // Price Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'السعر الحالي *',
                        hint: '0.00',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        isLarge: isLarge,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _oldPriceController,
                        label: 'السعر القديم (للخصم)',
                        hint: '0.00',
                        icon: Icons.money_off,
                        keyboardType: TextInputType.number,
                        isLarge: isLarge,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Unit Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildUnitDropdown(isLarge),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _unitValueController,
                        label: 'قيمة الوحدة',
                        hint: '1',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        isLarge: isLarge,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Stock
                _buildTextField(
                  controller: _stockController,
                  label: 'الكمية المتاحة *',
                  hint: '100',
                  icon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 24 : 20.h),

                // Available Switch
                _buildAvailableSwitch(isLarge),
                SizedBox(height: isLarge ? 32 : 24.h),

                // Save Button
                _buildSaveButton(isLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isLarge) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: isLarge ? 200 : 180.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedImage != null
                ? AppColors.success
                : AppColors.lightGrey,
            width: 2,
          ),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: AppColors.error,
                      radius: isLarge ? 18 : 16.r,
                      child: IconButton(
                        icon: Icon(Icons.close, size: isLarge ? 18 : 16.sp),
                        color: AppColors.white,
                        onPressed: () => setState(() => _selectedImage = null),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: isLarge ? 56 : 48.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'اضغط لاختيار صورة المنتج',
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'التصنيف *',
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            if (_categories.isEmpty)
              Text(
                '(لا توجد تصنيفات)',
                style: TextStyle(
                  fontSize: isLarge ? 12 : 11.sp,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              hint: Text(
                _categories.isEmpty ? 'لا توجد تصنيفات' : 'اختر التصنيف',
                style: TextStyle(color: AppColors.textHint),
              ),
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['id'],
                  child: Text('${cat['nameAr']} - ${cat['nameEn']}'),
                );
              }).toList(),
              onChanged: _categories.isEmpty
                  ? null
                  : (value) {
                      setState(() => _selectedCategoryId = value);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown(bool isLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وحدة القياس *',
          style: TextStyle(
            fontSize: isLarge ? 14 : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              items: _units.map((unit) {
                return DropdownMenuItem<String>(
                  value: unit['id'],
                  child: Text('${unit['ar']} (${unit['en']})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedUnit = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLarge,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSwitch(bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _isAvailable ? Icons.check_circle : Icons.cancel,
                color: _isAvailable ? AppColors.success : AppColors.error,
                size: isLarge ? 24 : 22.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                _isAvailable ? 'المنتج متاح للبيع' : 'المنتج غير متاح',
                style: TextStyle(
                  fontSize: isLarge ? 15 : 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _isAvailable = value);
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isLarge) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 56 : 52.h,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.save, size: isLarge ? 22 : 20.sp),
        label: Text(
          _isLoading ? 'جاري الحفظ...' : 'حفظ المنتج',
          style: TextStyle(
            fontSize: isLarge ? 16 : 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
