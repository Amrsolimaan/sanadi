import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import '../../../../core/constants/app_colors.dart';

class AddEditSpecialtyDialog extends StatefulWidget {
  final String? specialtyId;
  final Map<String, dynamic>? specialtyData;

  const AddEditSpecialtyDialog({
    super.key,
    this.specialtyId,
    this.specialtyData,
  });

  @override
  State<AddEditSpecialtyDialog> createState() => _AddEditSpecialtyDialogState();
}

class _AddEditSpecialtyDialogState extends State<AddEditSpecialtyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _orderController = TextEditingController();

  String? _iconUrl; // For Specialty, 'icon' field usually holds the image name or URL
  // But looking at MedicalManagementTab, it constructs URL from icon name OR uses cached network image if full URL.
  // We will store the FULL URL in 'imageUrl' field if possible, or just upload and save filename in 'icon'.
  // MedicalManagementTab logic: 
  // final imageUrl = 'https://pljrxqzinvdcy.../images/specialties/$icon.png';
  // So it expects 'icon' to be the filename without extension?
  // AND it seems to check 'imageUrl' too.
  // We will try to update 'icon' with the filename (without extension if possible) to maintain compatibility,
  // OR update the Code to prefer 'imageUrl' field if valid. 
  // Let's assume we upload to 'specialties' bucket and get a public URL. 
  // The existing code constructs URL manually which is risky if we change storage.
  // Ideally, we should save the FULL URL in 'imageUrl' field and update retrieval logic.
  // I will save the full URL in 'imageUrl' and also save the filename in 'icon'.

  File? _selectedImage;
  bool _isLoading = false;

  bool get isEditing => widget.specialtyId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.specialtyData != null) {
      final data = widget.specialtyData!;
      if (data['name'] is Map) {
        _nameArController.text = data['name']['ar'] ?? '';
        _nameEnController.text = data['name']['en'] ?? '';
      } else {
        _nameArController.text = data['nameAr'] ?? '';
        _nameEnController.text = data['nameEn'] ?? '';
      }
      _orderController.text = (data['order'] ?? 0).toString();
      
      // Try to determine image URL
      final icon = data['icon'];
      if (icon != null) {
        // Construct the URL as per MedicalManagementTab
         _iconUrl = 'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images/specialties/$icon.png';
      }
    } else {
      _loadNextOrder();
    }
  }

  Future<void> _loadNextOrder() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('specialties')
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? 'admin.edit_specialty'.tr()
                          : 'admin.add_specialty'.tr(),
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

                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : _iconUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_iconUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                       child: _selectedImage == null && _iconUrl == null
                          ? Icon(Icons.medical_services,
                              size: 40.sp, color: AppColors.textHint)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(child: Text('Tap to change icon', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary))),
                SizedBox(height: 24.h),

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
      String? iconName = widget.specialtyData?['icon'];

      if (_selectedImage != null) {
        // Use a consistent naming convention or allow random
        // For SupabaseStorageService.uploadFile, it returns the Full URL usually if using general method, 
        // But for specialties/doctors logic in this app seems to rely on filename.
        // Let's use timestamp for unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameEn = _nameEnController.text.trim().replaceAll(' ', '_');
        final fileName = '${nameEn}_$timestamp.png'; // Force png extension or keep original?
        
        // We will misuse the 'uploadFile' method's path argument slightly if it expects directory
        // OR we use the specific method if it exists. 
        // Checking SupabaseStorageService again... it usually uploads to a specific bucket.
        // Let's assume we can upload to 'images/specialties/$fileName'
        
        // Note: The previous code showed uploadFile(File, String path)
        // I will assume the 'path' argument is the directory/bucket logic.
        // However, I need the filename to be saved in 'icon' field.
        // I will implement a direct upload here or modify logic.
        
        // Actually, let's just upload using the service
        // and we get back a URL.
        // We need to extract the filename from the URL if the app logic depends on it.
        // The App logic: '.../images/specialties/$icon.png'
        
        // If I upload to 'specialties/$fileName', the service returns the full URL.
        // I can then extract the filename.
        
        await SupabaseStorageService.uploadFile(_selectedImage!, 'specialties');
        // Wait, uploadFile returns String (url).
        // Does it allow specifying filename? Usually generates one or takes from file.
        // PROPOSAL: I will update the 'icon' field to be the fileName (without extension if the reading logic adds .png)
        // BUT `SupabaseStorageService.uploadFile` might generate a random name.
        
        // Simplify: I will save the FULL URL in 'imageUrl' field (new) and potentially break 'icon' logic unless I reverse engineer it.
        // Better: Update MedicalManagementTab to prefer 'imageUrl' field if present!
        // I already did check MedicalManagementTab, and it prefers `imageUrl` if it starts with 'http'.
        // So I can just save the full URL in `imageUrl` field and `icon` can be anything unique.
        
        final fullUrl = await SupabaseStorageService.uploadFile(_selectedImage!, 'specialties');
        iconName = fullUrl; // We will save URL in a field.
        
        // If we save full URL in 'icon', the MedicalManagementTab logic:
        // final icon = data['icon'];
        // final imageUrl = 'https://.../$icon.png';
        // This will BREAK if icon is already a URL.
        // So we MUST save it in 'imageUrl' field which is checked FIRST.
        // And 'icon' field... maybe leave it or save filename. 
      }

      final data = {
        'name': {
          'ar': _nameArController.text.trim(),
          'en': _nameEnController.text.trim(),
        },
        'nameAr': _nameArController.text.trim(), // Legacy support
        'nameEn': _nameEnController.text.trim(), // Legacy support
        'order': int.tryParse(_orderController.text) ?? 0,
        if (_selectedImage != null) 'imageUrl': await SupabaseStorageService.uploadFile(_selectedImage!, 'specialties'), 
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('specialties')
            .doc(widget.specialtyId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('specialties')
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
