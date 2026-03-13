import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import 'package:http/http.dart' as http;

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _orderController = TextEditingController(text: '1');

  File? _selectedImage;
  Color _selectedColor = const Color(0xFF4CAF50);
  bool _isActive = true;
  bool _isLoading = false;

  final List<Color> _colors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFF2196F3), // Blue
    const Color(0xFFE53935), // Red
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF607D8B), // Grey
    const Color(0xFFFFEB3B), // Yellow
  ];

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة للتصنيف'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload image to Supabase
      final imageName = '${_idController.text.trim()}.png';
      final imageUrl = await _uploadImageToSupabase(_selectedImage!, imageName);

      // 2. Save to Firestore
      final categoryData = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'image': imageName,
        'color': '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
        'order': int.parse(_orderController.text.trim()),
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('grocery_categories')
          .doc(_idController.text.trim())
          .set(categoryData);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة التصنيف بنجاح'),
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

    final filePath = 'grocery/categories/$fileName';
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
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '➕ إضافة تصنيف جديد',
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
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

                // Category ID
                _buildTextField(
                  controller: _idController,
                  label: 'معرّف التصنيف (ID)',
                  hint: 'مثال: vegetables',
                  icon: Icons.tag,
                  isLarge: isLarge,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'مطلوب';
                    if (v!.contains(' ')) return 'لا يجب أن يحتوي على مسافات';
                    return null;
                  },
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Arabic Name
                _buildTextField(
                  controller: _nameArController,
                  label: 'الاسم بالعربية',
                  hint: 'مثال: خضروات',
                  icon: Icons.text_fields,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // English Name
                _buildTextField(
                  controller: _nameEnController,
                  label: 'الاسم بالإنجليزية',
                  hint: 'Example: Vegetables',
                  icon: Icons.translate,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 16 : 14.h),

                // Order
                _buildTextField(
                  controller: _orderController,
                  label: 'الترتيب',
                  hint: '1',
                  icon: Icons.sort,
                  keyboardType: TextInputType.number,
                  isLarge: isLarge,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                SizedBox(height: isLarge ? 24 : 20.h),

                // Color Picker
                _buildColorPicker(isLarge),
                SizedBox(height: isLarge ? 24 : 20.h),

                // Active Switch
                _buildActiveSwitch(isLarge),
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
                    'اضغط لاختيار صورة التصنيف',
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'PNG أو JPG (512x512)',
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLarge,
    TextInputType keyboardType = TextInputType.text,
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

  Widget _buildColorPicker(bool isLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لون التصنيف',
          style: TextStyle(
            fontSize: isLarge ? 14 : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(isLarge ? 16 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Wrap(
            spacing: isLarge ? 12 : 10.w,
            runSpacing: isLarge ? 12 : 10.h,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedColor = color);
                },
                child: Container(
                  width: isLarge ? 44 : 40.w,
                  height: isLarge ? 44 : 40.h,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: isLarge ? 24 : 20.sp,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch(bool isLarge) {
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
                _isActive ? Icons.visibility : Icons.visibility_off,
                color: _isActive ? AppColors.success : AppColors.textHint,
                size: isLarge ? 24 : 22.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                _isActive ? 'التصنيف مفعّل' : 'التصنيف معطّل',
                style: TextStyle(
                  fontSize: isLarge ? 15 : 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _isActive = value);
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
        onPressed: _isLoading ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
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
          _isLoading ? 'جاري الحفظ...' : 'حفظ التصنيف',
          style: TextStyle(
            fontSize: isLarge ? 16 : 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
