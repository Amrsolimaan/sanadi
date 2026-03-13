import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import '../../../../core/constants/app_colors.dart';

class AddEditDoctorDialog extends StatefulWidget {
  final String? doctorId;
  final Map<String, dynamic>? doctorData;

  const AddEditDoctorDialog({
    super.key,
    this.doctorId,
    this.doctorData,
  });

  @override
  State<AddEditDoctorDialog> createState() => _AddEditDoctorDialogState();
}

class _AddEditDoctorDialogState extends State<AddEditDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _specialtyArController = TextEditingController();
  final _specialtyEnController = TextEditingController();
  final _aboutArController = TextEditingController();
  final _aboutEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Doctor specific fields
  bool _isAvailable = true;
  String? _imageUrl;
  File? _selectedImage;
  bool _isLoading = false;

  bool get isEditing => widget.doctorId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.doctorData != null) {
      final data = widget.doctorData!;
      
      // Name
      if (data['name'] is Map) {
        _nameArController.text = data['name']['ar'] ?? '';
        _nameEnController.text = data['name']['en'] ?? '';
      } else {
        _nameArController.text = data['nameAr'] ?? '';
        _nameEnController.text = data['nameEn'] ?? '';
      }

      // Specialty
      if (data['specialty'] is Map) {
        _specialtyArController.text = data['specialty']['ar'] ?? '';
        _specialtyEnController.text = data['specialty']['en'] ?? '';
      } else {
        _specialtyArController.text = data['specialtyAr'] ?? '';
        _specialtyEnController.text = data['specialtyEn'] ?? '';
      }

      // About
      if (data['about'] is Map) {
        _aboutArController.text = data['about']['ar'] ?? '';
        _aboutEnController.text = data['about']['en'] ?? '';
      } else {
        _aboutArController.text = data['aboutAr'] ?? '';
        _aboutEnController.text = data['aboutEn'] ?? '';
      }

      _phoneController.text = data['phone'] ?? '';
      _priceController.text = (data['sessionPrice'] ?? 0).toString();
      _isAvailable = data['isAvailable'] ?? true;
      _imageUrl = data['imageUrl'];
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _specialtyArController.dispose();
    _specialtyEnController.dispose();
    _aboutArController.dispose();
    _aboutEnController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600.w, // Wider dialog for doctors
        constraints: BoxConstraints(maxHeight: 800.h),
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? 'admin.edit_doctor'.tr()
                          : 'admin.add_doctor'.tr(),
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

                // Helper function for row layout
                _buildRowLayout([
                  _buildImagePicker(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Available', style: TextStyle(fontSize: 14.sp)),
                          Switch(
                            value: _isAvailable,
                            onChanged: (v) => setState(() => _isAvailable = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  )
                ]),
                SizedBox(height: 24.h),

                Text('Basic Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(height: 12.h),
                _buildRowLayout([
                  _buildTextField(_nameArController, 'الاسم بالعربية'),
                  _buildTextField(_nameEnController, 'Name in English'),
                ]),
                SizedBox(height: 12.h),
                _buildRowLayout([
                   _buildTextField(_phoneController, 'Phone', icon: Icons.phone, inputType: TextInputType.phone),
                   _buildTextField(_priceController, 'Session Price', icon: Icons.attach_money, inputType: TextInputType.number),
                ]),

                SizedBox(height: 24.h),
                Text('Specialty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(height: 12.h),
                _buildRowLayout([
                  _buildTextField(_specialtyArController, 'التخصص بالعربية'),
                  _buildTextField(_specialtyEnController, 'Specialty in English'),
                ]),

                SizedBox(height: 24.h),
                Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(height: 12.h),
                _buildTextField(_aboutArController, 'نبذة بالعربية', maxLines: 3),
                SizedBox(height: 12.h),
                _buildTextField(_aboutEnController, 'About in English', maxLines: 3),

                SizedBox(height: 24.h),

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

  Widget _buildRowLayout(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((c) => Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8.w), child: c))).toList(),
        );
      } else {
        return Column(
          children: children.map((c) => Padding(padding: EdgeInsets.only(bottom: 12.h), child: c)).toList(),
        );
      }
    });
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, TextInputType? inputType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: icon != null ? Icon(icon) : null,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (v) => v?.isEmpty == true ? 'general.required'.tr() : null,
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
              ? Icon(Icons.person, size: 40.sp, color: AppColors.textHint)
              : null,
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? uploadedUrl = _imageUrl;

      if (_selectedImage != null) {
        uploadedUrl = await SupabaseStorageService.uploadFile(_selectedImage!, 'doctors');
      }

      final data = {
        'name': {
          'ar': _nameArController.text.trim(),
          'en': _nameEnController.text.trim(),
        },
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        
        'specialty': {
           'ar': _specialtyArController.text.trim(),
           'en': _specialtyEnController.text.trim(),
        },
        'specialtyAr': _specialtyArController.text.trim(),
        'specialtyEn': _specialtyEnController.text.trim(),
        
        'about': {
           'ar': _aboutArController.text.trim(),
           'en': _aboutEnController.text.trim(),
        },
        'aboutAr': _aboutArController.text.trim(),
        'aboutEn': _aboutEnController.text.trim(),
        
        'phone': _phoneController.text.trim(),
        'sessionPrice': double.tryParse(_priceController.text) ?? 0,
        'isAvailable': _isAvailable,
        'imageUrl': uploadedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('doctor')
            .doc(widget.doctorId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['rating'] = 5.0; // Default
        data['reviewsCount'] = 0;
        data['points'] = 0;
        
        await FirebaseFirestore.instance
            .collection('doctor')
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
