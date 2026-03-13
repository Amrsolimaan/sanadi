import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/grocery_admin/view/add_edit_doctor_dialog.dart';
import 'package:sanadi/features/grocery_admin/view/add_edit_specialty_dialog.dart';
import 'package:sanadi/features/grocery_admin/view/screens/appointment_details_screen.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_cubit.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_state.dart';
import '../../../../core/constants/app_colors.dart';

class MedicalManagementTab extends StatefulWidget {
  final String? searchQuery;
  const MedicalManagementTab({super.key, this.searchQuery});

  @override
  State<MedicalManagementTab> createState() => _MedicalManagementTabState();
}

class _MedicalManagementTabState extends State<MedicalManagementTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    // ... existing build ...
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(isLarge ? 24 : 16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            tabs: [
              Tab(text: 'admin.specialties'.tr()),
              Tab(text: 'admin.doctors'.tr()),
              Tab(text: 'admin.appointments_title'.tr()),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSpecialtiesTab(context, isLarge, lang),
              _buildDoctorsTab(context, isLarge, lang),
              _buildAppointmentsTab(context, isLarge, lang),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // Specialties Tab
  // ============================================
  Widget _buildSpecialtiesTab(BuildContext context, bool isLarge, String lang) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final canAdd = state is AdminLoaded && state.currentAdmin.canAdd();

        return Column(
          children: [
            if (canAdd)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEditSpecialtyDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text('admin.add_specialty'.tr()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white),
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('specialties')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                    final query = widget.searchQuery!.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nameAr = (data['nameAr'] ?? data['name']?['ar'] ?? '').toString().toLowerCase();
                      final nameEn = (data['nameEn'] ?? data['name']?['en'] ?? '').toString().toLowerCase();
                      return nameAr.contains(query) || nameEn.contains(query);
                    }).toList();
                  }

                  if (docs.isEmpty)
                    return Center(child: Text('admin.no_data'.tr()));

                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildSpecialtyCard(
                          context, doc.id, data, isLarge, lang, canAdd);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecialtyCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isLarge, String lang, bool canEdit) {
    // قراءة الاسم بالشكل الصحيح - يمكن أن يكون Map أو String مباشر
    String name = '';
    if (data['name'] is Map) {
      final nameMap = data['name'] as Map<String, dynamic>;
      name = lang == 'ar'
          ? (nameMap['ar'] ?? nameMap['en'] ?? '')
          : (nameMap['en'] ?? nameMap['ar'] ?? '');
    } else {
      name = lang == 'ar'
          ? (data['nameAr'] ?? data['nameEn'] ?? data['name'] ?? '')
          : (data['nameEn'] ?? data['nameAr'] ?? data['name'] ?? '');
    }
    
    final icon = data['icon'] ?? 'medical_services';
    final order = data['order'] ?? 0;
    
    // بناء رابط الصورة من Supabase بناءً على icon
    final imageUrl = 'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images/specialties/$icon.png';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // صورة التخصص من Supabase
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 56.w,
              height: 56.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medical_services,
                    color: AppColors.primary, size: 28.sp),
              ),
              errorWidget: (context, url, error) => Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medical_services,
                    color: AppColors.primary, size: 28.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: isLarge ? 16 : 14.sp,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.tag, size: 14.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text('ترتيب: $order',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit')
                  _showAddEditSpecialtyDialog(context, specialtyId: docId, data: data);
                if (v == 'delete')
                  _showDeleteDialog(context, 'specialties', docId);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit, size: 20),
                      SizedBox(width: 8.w),
                      Text('general.edit'.tr())
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete,
                          size: 20, color: AppColors.error),
                      SizedBox(width: 8.w),
                      Text('general.delete'.tr(),
                          style: const TextStyle(color: AppColors.error))
                    ])),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================
  // Doctors Tab
  // ============================================
  Widget _buildDoctorsTab(BuildContext context, bool isLarge, String lang) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final canAdd = state is AdminLoaded && state.currentAdmin.canAdd();

        return Column(
          children: [
            if (canAdd)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEditDoctorDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text('admin.add_doctor'.tr()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white),
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor')
                    .orderBy('points', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                    final query = widget.searchQuery!.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nameAr = (data['nameAr'] ?? data['name']?['ar'] ?? '').toString().toLowerCase();
                      final nameEn = (data['nameEn'] ?? data['name']?['en'] ?? '').toString().toLowerCase();
                      final specialty = (data['specialty'] ?? '').toString().toLowerCase();
                      return nameAr.contains(query) || nameEn.contains(query) || specialty.contains(query);
                    }).toList();
                  }

                  if (docs.isEmpty)
                    return Center(child: Text('admin.no_data'.tr()));

                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildDoctorCard(
                          context, doc.id, data, isLarge, lang, canAdd);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isLarge, String lang, bool canEdit) {
    // قراءة الاسم - يمكن أن يكون Map أو String
    String name = '';
    if (data['name'] is Map) {
      final nameMap = data['name'] as Map<String, dynamic>;
      name = lang == 'ar'
          ? (nameMap['ar'] ?? nameMap['en'] ?? '')
          : (nameMap['en'] ?? nameMap['ar'] ?? '');
    } else {
      name = lang == 'ar'
          ? (data['nameAr'] ?? data['nameEn'] ?? data['name'] ?? '')
          : (data['nameEn'] ?? data['nameAr'] ?? data['name'] ?? '');
    }

    // قراءة التخصص - يمكن أن يكون Map أو String
    String specialty = '';
    if (data['specialty'] is Map) {
      final specMap = data['specialty'] as Map<String, dynamic>;
      specialty = lang == 'ar'
          ? (specMap['ar'] ?? specMap['en'] ?? '')
          : (specMap['en'] ?? specMap['ar'] ?? '');
    } else {
      specialty = lang == 'ar'
          ? (data['specialtyAr'] ?? data['specialtyEn'] ?? data['specialty'] ?? '')
          : (data['specialtyEn'] ?? data['specialtyAr'] ?? data['specialty'] ?? '');
    }

    // بناء رابط الصورة - يمكن أن يكون imageUrl محفوظ أو نبنيه من الاسم
    String imageUrl = data['imageUrl'] ?? '';
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      // بناء الرابط من Supabase بناءً على اسم الطبيب
      final nameEn = data['name'] is Map 
          ? (data['name']['en'] ?? '') 
          : (data['nameEn'] ?? '');
      if (nameEn.isNotEmpty) {
        final fileName = nameEn
            .toLowerCase()
            .replaceAll('dr. ', 'dr_')
            .replaceAll(' ', '_');
        imageUrl = 'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images/doctors/$fileName.png';
      }
    }
    
    final rating = (data['rating'] ?? 0).toDouble();
    final points = data['points'] ?? 0;
    final phone = data['phone'] ?? '';
    final isAvailable = data['isAvailable'] ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: !isAvailable ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // صورة الطبيب
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 60.w,
                  height: 60.w,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60.w,
                    height: 60.w,
                    color: AppColors.lightGrey,
                    child: Icon(Icons.person, size: 30.sp, color: AppColors.textHint),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60.w,
                    height: 60.w,
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 30.sp, color: AppColors.primary),
                  ),
                ),
              ),
              if (!isAvailable)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.white, size: 12.sp),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: isLarge ? 16 : 14.sp,
                        fontWeight: FontWeight.w600)),
                Text(specialty,
                    style:
                        TextStyle(fontSize: 13.sp, color: AppColors.primary)),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text('$rating', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 12.w),
                    Icon(Icons.workspace_premium,
                        color: AppColors.primary, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text('$points نقطة', style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14.sp, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(phone, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showAddEditDoctorDialog(context, doctorId: docId, data: data);
                if (v == 'delete') _showDeleteDialog(context, 'doctor', docId);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit, size: 20),
                      SizedBox(width: 8.w),
                      Text('general.edit'.tr())
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete,
                          size: 20, color: AppColors.error),
                      SizedBox(width: 8.w),
                      Text('general.delete'.tr(),
                          style: const TextStyle(color: AppColors.error))
                    ])),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================
  // Appointments Tab
  // ============================================
  Widget _buildAppointmentsTab(
      BuildContext context, bool isLarge, String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('appointments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          final query = widget.searchQuery!.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final patientName = (data['patientName'] ?? data['userName'] ?? '').toString().toLowerCase();
            final doctorId = (data['doctorId'] ?? '').toString().toLowerCase();
            return patientName.contains(query) || doctorId.contains(query);
          }).toList();
        }

        if (docs.isEmpty)
          return Center(child: Text('admin.no_data'.tr()));

        return ListView.builder(
          padding: EdgeInsets.all(isLarge ? 24 : 16.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            // Extract doctor ID from path: doctor/{doctorId}/appointments/{appointmentId}
            final pathSegments = doc.reference.path.split('/');
            String doctorId = data['doctorId']?.toString() ?? '';
            if (doctorId.isEmpty && pathSegments.length >= 2 && pathSegments[0] == 'doctor') {
              doctorId = pathSegments[1];
            }

            return _buildAppointmentCard(
                context, doc.id, doctorId, data, isLarge, lang);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, String appointmentId,
      String doctorId, Map<String, dynamic> data, bool isLarge, String lang) {
    final status = data['status'] ?? 'upcoming';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';
    final patientName = data['patientName'] ?? data['userName'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(
            appointmentId: appointmentId,
            doctorId: doctorId,
            appointmentData: data,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.calendar_today, color: statusColor, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patientName,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  Text('$date - $time',
                      style: TextStyle(
                          fontSize: 13.sp, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                    fontSize: 12.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'admin.status_completed'.tr();
      case 'cancelled':
        return 'admin.status_cancelled'.tr();
      default:
        return 'admin.status_upcoming'.tr();
    }
  }

  void _showDeleteDialog(
      BuildContext context, String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.delete_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('general.cancel'.tr())),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('admin.delete_success'.tr())));
            },
            child: Text('general.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddEditSpecialtyDialog(BuildContext context, {String? specialtyId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (_) => AddEditSpecialtyDialog(specialtyId: specialtyId, specialtyData: data),
    );
  }

  void _showAddEditDoctorDialog(BuildContext context, {String? doctorId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (_) => AddEditDoctorDialog(doctorId: doctorId, doctorData: data),
    );
  }
}
