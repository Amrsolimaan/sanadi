import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import '../../../../core/constants/app_colors.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final String? categoryId;
  final Map<String, dynamic>? categoryData;

  const AddEditCategoryDialog({
    super.key,
    this.categoryId,
    this.categoryData,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _orderController = TextEditingController();

  Color _selectedColor = AppColors.primary;
  String? _imageUrl;
  File? _selectedImage;
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.categoryData != null) {
      _nameArController.text = widget.categoryData!['nameAr'] ?? '';
      _nameEnController.text = widget.categoryData!['nameEn'] ?? '';
      _orderController.text = (widget.categoryData!['order'] ?? 0).toString();
      _imageUrl = widget.categoryData!['imageUrl'];
      _isActive = widget.categoryData!['isActive'] ?? true;

      final colorHex = widget.categoryData!['color'] ?? '#0095DA';
      _selectedColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } else {
      // ✅ حساب الترتيب تلقائياً للتصنيفات الجديدة
      _loadNextOrder();
    }
  }

  // ✅ جلب عدد التصنيفات الحالية وتعيين الترتيب
  Future<void> _loadNextOrder() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grocery_categories')
          .get();
      final nextOrder = snapshot.docs.length + 1;
      setState(() {
        _orderController.text = nextOrder.toString();
      });
    } catch (e) {
      _orderController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400.w,
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? 'admin.edit_category'.tr()
                          : 'admin.add_category'.tr(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : _imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _selectedImage == null && _imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 40.sp, color: AppColors.textHint),
                                SizedBox(height: 8.h),
                                Text(
                                  'Add Image',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textHint),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Name Arabic
                TextFormField(
                  controller: _nameArController,
                  decoration: InputDecoration(
                    labelText: 'الاسم بالعربية',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'general.required'.tr() : null,
                ),
                SizedBox(height: 16.h),

                // Name English
                TextFormField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    labelText: 'Name in English',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'general.required'.tr() : null,
                ),
                SizedBox(height: 16.h),

                // Order
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.sort),
                  ),
                ),
                SizedBox(height: 16.h),

                // Color Picker
                Row(
                  children: [
                    Text('Color:', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lightGrey),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(
                          fontSize: 14.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Active Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active', style: TextStyle(fontSize: 14.sp)),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text('general.cancel'.tr()),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'general.save'.tr(),
                                style: const TextStyle(color: AppColors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: _buildColorPicker(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Build a simple color picker widget
  Widget _buildColorPicker() {
    final List<Color> predefinedColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.logoGreen,
      AppColors.logoOrange,
      AppColors.logoYellow,
      AppColors.success,
      AppColors.error,
      AppColors.warning,
      AppColors.info,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: predefinedColors.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await SupabaseStorageService.uploadFile(
          _selectedImage!,
          'grocery_categories',
        );
      }

      final data = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'order': int.tryParse(_orderController.text) ?? 0,
        'color':
            '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'imageUrl': imageUrl,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('grocery_categories')
            .doc(widget.categoryId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('grocery_categories')
            .add(data);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.save_success'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
