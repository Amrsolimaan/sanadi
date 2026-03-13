import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import '../../../../core/constants/app_colors.dart';

class AddEditProductDialog extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const AddEditProductDialog({
    super.key,
    this.productId,
    this.productData,
  });

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController(); // ✅ للخصم
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitValueController = TextEditingController(text: '1'); // ✅ قيمة الوحدة

  String? _selectedCategoryId;
  String? _imageUrl; // ✅ صورة واحدة بدلاً من List
  File? _selectedImage;
  bool _isAvailable = true;
  bool _isLoading = false;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.productData != null) {
      _nameArController.text = widget.productData!['nameAr'] ?? '';
      _nameEnController.text = widget.productData!['nameEn'] ?? '';
      _descArController.text = widget.productData!['descriptionAr'] ?? '';
      _descEnController.text = widget.productData!['descriptionEn'] ?? '';
      _priceController.text = (widget.productData!['price'] ?? 0).toString();
      _oldPriceController.text = (widget.productData!['oldPrice'] ?? '').toString();
      if (_oldPriceController.text == '0' || _oldPriceController.text == 'null') {
        _oldPriceController.text = '';
      }
      _stockController.text = (widget.productData!['stockQuantity'] ?? 0).toString();
      _unitController.text = widget.productData!['unit'] ?? '';
      _unitValueController.text = (widget.productData!['unitValue'] ?? 1).toString();
      _selectedCategoryId = widget.productData!['categoryId'];
      
      // ✅ قراءة الصورة - تدعم imageUrl أو images[0]
      if (widget.productData!['imageUrl'] != null && widget.productData!['imageUrl'].toString().isNotEmpty) {
        _imageUrl = widget.productData!['imageUrl'];
      } else if (widget.productData!['images'] is List && (widget.productData!['images'] as List).isNotEmpty) {
        _imageUrl = (widget.productData!['images'] as List)[0].toString();
      }
      
      _isAvailable = widget.productData!['isAvailable'] ?? true;
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
    _unitController.dispose();
    _unitValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500.w,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'admin.edit_product'.tr()
                        : 'admin.add_product'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ صورة واحدة بدلاً من List
                      Text('صورة المنتج *',
                          style: TextStyle(
                              fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_imageUrl != null || _selectedImage != null)
                                  ? AppColors.success
                                  : AppColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
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
                          child: (_imageUrl == null && _selectedImage == null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        size: 40.sp, color: AppColors.textHint),
                                    SizedBox(height: 8.h),
                                    Text('اضغط لاختيار صورة',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary)),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _imageUrl = null;
                                        _selectedImage = null;
                                      }),
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close,
                                            size: 16.sp, color: AppColors.white),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Category Dropdown
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('grocery_categories')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final categories = snapshot.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'التصنيف *',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: categories.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = lang == 'ar'
                                  ? (data['nameAr'] ?? data['nameEn'])
                                  : (data['nameEn'] ?? data['nameAr']);
                              return DropdownMenuItem(
                                  value: doc.id, child: Text(name));
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategoryId = v),
                            validator: (v) =>
                                v == null ? 'مطلوب' : null,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Name Arabic
                      TextFormField(
                        controller: _nameArController,
                        decoration: InputDecoration(
                          labelText: 'الاسم بالعربية *',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Name English
                      TextFormField(
                        controller: _nameEnController,
                        decoration: InputDecoration(
                          labelText: 'Name in English *',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Description Arabic
                      TextFormField(
                        controller: _descArController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'الوصف بالعربية',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Description English
                      TextFormField(
                        controller: _descEnController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description in English',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ✅ Price & Old Price Row (للخصم)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'السعر الحالي *',
                                suffixText: 'ج.م',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v?.isEmpty == true
                                  ? 'مطلوب'
                                  : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _oldPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'السعر القديم (للخصم)',
                                suffixText: 'ج.م',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Stock & Unit Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'الكمية المتاحة',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: InputDecoration(
                                labelText: 'الوحدة (kg, قطعة...)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Available Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('متاح للبيع', style: TextStyle(fontSize: 14.sp)),
                          Switch(
                            value: _isAvailable,
                            onChanged: (v) => setState(() => _isAvailable = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
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
                                  strokeWidth: 2, color: AppColors.white),
                            )
                          : Text('general.save'.tr(),
                              style: const TextStyle(color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تم إزالة _buildImagePreview لأنها لم تعد مستخدمة

  void _pickImage() async {
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ التحقق من وجود صورة
    if (_imageUrl == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة للمنتج'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // ✅ رفع الصورة الجديدة إلى Supabase
      if (_selectedImage != null) {
        finalImageUrl = await SupabaseStorageService.uploadFile(
            _selectedImage!, 'grocery_products');
      }

      // ✅ قراءة السعر القديم
      final oldPriceText = _oldPriceController.text.trim();
      final oldPrice = oldPriceText.isNotEmpty ? double.tryParse(oldPriceText) : null;

      final data = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'descriptionAr': _descArController.text.trim(),
        'descriptionEn': _descEnController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'oldPrice': oldPrice, // ✅ للخصم
        'stockQuantity': int.tryParse(_stockController.text) ?? 0,
        'unit': _unitController.text.trim(),
        'unitValue': double.tryParse(_unitValueController.text) ?? 1,
        'categoryId': _selectedCategoryId,
        'imageUrl': finalImageUrl, // ✅ صورة واحدة
        'isAvailable': _isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('grocery_products')
            .doc(widget.productId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['rating'] = 0.0;
        data['reviewsCount'] = 0;
        await FirebaseFirestore.instance
            .collection('grocery_products')
            .add(data);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'تم التعديل بنجاح ✅' : 'تم الإضافة بنجاح ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

