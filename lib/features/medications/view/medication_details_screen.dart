import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/medications/viewmodel/medication_state.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodel/medication_cubit.dart';
import '../model/medication_model.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final MedicationModel medication;

  const MedicationDetailsScreen({super.key, required this.medication});

  @override
  State<MedicationDetailsScreen> createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  late MedicationModel _medication;

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    return BlocListener<MedicationCubit, MedicationState>(
      listener: (context, state) {
        if (state is MedicationUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('medications.updated_success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is MedicationDeleted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _medication.getName(lang),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _showDeleteDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication Icon Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          MedicationModel.getTypeIcon(_medication.type),
                          color: AppColors.primary,
                          size: 40.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _medication.getName(lang),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_medication.dose} • ${_medication.getTypeLabel(lang)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Details Section
                _buildSectionTitle('medications.details'.tr()),
                SizedBox(height: 12.h),

                _buildDetailCard([
                  _buildEditableDetailRow(
                    context,
                    Icons.medication,
                    'medications.type'.tr(),
                    _medication.getTypeLabel(lang),
                    () => _showTypeSelector(context),
                  ),
                  _buildDivider(),
                  _buildEditableDetailRow(
                    context,
                    Icons.fitness_center,
                    'medications.dose'.tr(),
                    _medication.dose,
                    () => _showDoseEditor(context),
                  ),
                  if (_medication.purpose != null &&
                      _medication.purpose!.isNotEmpty) ...[
                    _buildDivider(),
                    _buildEditableDetailRow(
                      context,
                      Icons.info_outline,
                      'medications.purpose'.tr(),
                      _medication.getPurpose(lang) ?? '',
                      () => _showPurposeEditor(context),
                    ),
                  ],
                ]),

                SizedBox(height: 24.h),

                // Schedule Section
                _buildSectionTitle('medications.schedule'.tr()),
                SizedBox(height: 12.h),

                _buildDetailCard([
                  _buildDetailRow(
                    Icons.repeat,
                    'medications.frequency'.tr(),
                    _getFrequencyText(lang),
                  ),
                  if (_medication.frequency ==
                      MedicationFrequency.specificDays) ...[
                    _buildDivider(),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'medications.days'.tr(),
                      _getDaysText(lang),
                    ),
                  ],
                  _buildDivider(),
                  _buildEditableDetailRow(
                    context,
                    Icons.access_time,
                    'medications.times'.tr(),
                    _medication.times.map((t) => _formatTime(t)).join(', '),
                    () => _showTimesEditor(context),
                  ),
                ]),

                SizedBox(height: 32.h),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton.icon(
                    onPressed: () => _showFullEditSheet(context),
                    icon: Icon(Icons.edit, size: 20.sp),
                    label: Text(
                      'medications.edit_medication'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: AppColors.textHint,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.lightGrey);
  }

  String _getFrequencyText(String lang) {
    switch (_medication.frequency) {
      case MedicationFrequency.daily:
        return lang == 'ar' ? 'يومياً' : 'Daily';
      case MedicationFrequency.specificDays:
        return lang == 'ar' ? 'أيام محددة' : 'Specific days';
      case MedicationFrequency.asNeeded:
        return lang == 'ar' ? 'عند الحاجة' : 'As needed';
    }
  }

  String _getDaysText(String lang) {
    final dayNames = lang == 'ar'
        ? [
            'الاثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
            'السبت',
            'الأحد'
          ]
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _medication.specificDays.map((d) => dayNames[d - 1]).join(', ');
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('medications.delete'.tr()),
        content: Text('medications.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationCubit>().deleteMedication(_medication.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'general.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Edit Functions
  // ============================================

  void _showDoseEditor(BuildContext context) {
    final controller = TextEditingController(text: _medication.dose);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'medications.edit_dose'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'medications.dose_hint'.tr(),
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('general.cancel'.tr()),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          _updateMedication(dose: controller.text);
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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
    );
  }

  void _showPurposeEditor(BuildContext context) {
    final lang = context.locale.languageCode;
    final controller =
        TextEditingController(text: _medication.getPurpose(lang));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'medications.edit_purpose'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'medications.purpose_hint'.tr(),
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('general.cancel'.tr()),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateMedication(
                          purpose: controller.text,
                          purposeAr: lang == 'ar' ? controller.text : null,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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
    );
  }

  void _showTypeSelector(BuildContext context) {
    final lang = context.locale.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'medications.select_type'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1),
            ...MedicationType.values.map((type) {
              final isSelected = type == _medication.type;
              return ListTile(
                leading: Icon(
                  MedicationModel.getTypeIcon(type),
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  _getTypeName(type, lang),
                  style: TextStyle(
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  _updateMedication(type: type);
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showTimesEditor(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final newTimes = [..._medication.times];

      // Show option to add or replace
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'medications.time_action'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.add, color: AppColors.primary),
                  title: Text('medications.add_time'.tr()),
                  onTap: () {
                    newTimes.add(newTime);
                    newTimes.sort();
                    _updateMedication(times: newTimes);
                    Navigator.pop(ctx);
                  },
                ),
                if (_medication.times.isNotEmpty)
                  ListTile(
                    leading:
                        Icon(Icons.swap_horiz, color: AppColors.logoOrange),
                    title: Text('medications.replace_time'.tr()),
                    onTap: () {
                      _updateMedication(times: [newTime]);
                      Navigator.pop(ctx);
                    },
                  ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      }
    }
  }

  void _showFullEditSheet(BuildContext context) {
    // Navigate to AddMedicationScreen in edit mode
    // For now, show a comprehensive edit bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('medications.edit_hint'.tr()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _getTypeName(MedicationType type, String lang) {
    final labels = {
      MedicationType.tablet: lang == 'ar' ? 'أقراص' : 'Tablet',
      MedicationType.capsule: lang == 'ar' ? 'كبسولة' : 'Capsule',
      MedicationType.liquid: lang == 'ar' ? 'شراب' : 'Liquid',
      MedicationType.injection: lang == 'ar' ? 'حقنة' : 'Injection',
      MedicationType.drops: lang == 'ar' ? 'قطرة' : 'Drops',
      MedicationType.cream: lang == 'ar' ? 'كريم' : 'Cream',
      MedicationType.other: lang == 'ar' ? 'أخرى' : 'Other',
    };
    return labels[type] ?? '';
  }

  void _updateMedication({
    String? dose,
    MedicationType? type,
    String? purpose,
    String? purposeAr,
    List<String>? times,
  }) {
    final updated = MedicationModel(
      id: _medication.id,
      visitorId: _medication.visitorId,
      name: _medication.name,
      nameAr: _medication.nameAr,
      dose: dose ?? _medication.dose,
      type: type ?? _medication.type,
      purpose: purpose ?? _medication.purpose,
      purposeAr: purposeAr ?? _medication.purposeAr,
      frequency: _medication.frequency,
      specificDays: _medication.specificDays,
      times: times ?? _medication.times,
      isActive: _medication.isActive,
      createdAt: _medication.createdAt,
    );

    setState(() {
      _medication = updated;
    });

    context.read<MedicationCubit>().updateMedication(updated);
  }
}
