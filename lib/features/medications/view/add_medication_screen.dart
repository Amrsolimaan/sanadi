import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodel/medication_cubit.dart';
import '../viewmodel/medication_state.dart';
import '../model/medication_model.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _purposeController = TextEditingController();

  MedicationType _selectedType = MedicationType.tablet;
  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  List<String> _selectedTimes = ['08:00'];

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicationCubit, MedicationState>(
      listener: (context, state) {
        if (state is MedicationAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('medications.added_success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
        if (state is MedicationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'medications.add'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication Name
                _buildLabel('medications.name'.tr(), required: true),
                _buildTextField(
                  controller: _nameController,
                  hint: 'medications.name_hint'.tr(),
                  validator: (v) =>
                      v!.isEmpty ? 'medications.name_required'.tr() : null,
                ),
                SizedBox(height: 20.h),

                // Dose
                _buildLabel('medications.dose'.tr(), required: true),
                _buildTextField(
                  controller: _doseController,
                  hint: 'medications.dose_hint'.tr(),
                  validator: (v) =>
                      v!.isEmpty ? 'medications.dose_required'.tr() : null,
                ),
                SizedBox(height: 20.h),

                // Type
                _buildLabel('medications.type'.tr()),
                SizedBox(height: 8.h),
                _buildTypeSelector(),
                SizedBox(height: 20.h),

                // Purpose (Optional)
                _buildLabel('medications.purpose'.tr()),
                _buildTextField(
                  controller: _purposeController,
                  hint: 'medications.purpose_hint'.tr(),
                ),
                SizedBox(height: 20.h),

                // Frequency
                _buildLabel('medications.frequency'.tr()),
                SizedBox(height: 8.h),
                _buildFrequencySelector(),
                SizedBox(height: 16.h),

                // Days (if specific days selected)
                if (_selectedFrequency == MedicationFrequency.specificDays) ...[
                  _buildLabel('medications.select_days'.tr()),
                  SizedBox(height: 8.h),
                  _buildDaysSelector(),
                  SizedBox(height: 20.h),
                ],

                // Times
                _buildLabel('medications.times'.tr()),
                SizedBox(height: 8.h),
                _buildTimesSelector(),
                SizedBox(height: 32.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'medications.save'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: TextStyle(fontSize: 14.sp, color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14.sp),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: MedicationType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MedicationModel.getTypeIcon(type),
                  size: 18.sp,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        children: MedicationFrequency.values.map((freq) {
          final isLast = freq == MedicationFrequency.values.last;
          return Column(
            children: [
              RadioListTile<MedicationFrequency>(
                title: Text(
                  _getFrequencyLabel(freq),
                  style: TextStyle(fontSize: 14.sp),
                ),
                value: freq,
                groupValue: _selectedFrequency,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setState(() => _selectedFrequency = value!),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                visualDensity: VisualDensity.compact,
              ),
              if (!isLast) Divider(height: 1, color: AppColors.lightGrey),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaysSelector() {
    final lang = context.locale.languageCode;
    final days = lang == 'ar'
        ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = _selectedDays.contains(dayNum);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected && _selectedDays.length > 1) {
                _selectedDays.remove(dayNum);
              } else if (!isSelected) {
                _selectedDays.add(dayNum);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42.w,
            height: 42.h,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimesSelector() {
    return Column(
      children: [
        ..._selectedTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary, size: 22.sp),
                SizedBox(width: 12.w),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_selectedTimes.length > 1)
                  GestureDetector(
                    onTap: () => setState(() => _selectedTimes.removeAt(index)),
                    child: Icon(
                      Icons.remove_circle,
                      color: AppColors.error,
                      size: 22.sp,
                    ),
                  ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () => _selectTime(index),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => setState(() => _selectedTimes.add('12:00')),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'medications.add_time'.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(int index) async {
    final parts = _selectedTimes[index].split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTimes[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
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

  String _getTypeLabel(MedicationType type) {
    final lang = context.locale.languageCode;
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

  String _getFrequencyLabel(MedicationFrequency freq) {
    switch (freq) {
      case MedicationFrequency.daily:
        return 'medications.daily'.tr();
      case MedicationFrequency.specificDays:
        return 'medications.specific_days'.tr();
      case MedicationFrequency.asNeeded:
        return 'medications.as_needed'.tr();
    }
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('medications.select_time_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFrequency == MedicationFrequency.specificDays &&
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('medications.select_days_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final medication = MedicationModel(
      id: '',
      visitorId: '',
      name: _nameController.text.trim(),
      nameAr: null, // يمكن تحديده تلقائياً لاحقاً
      dose: _doseController.text.trim(),
      type: _selectedType,
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      frequency: _selectedFrequency,
      specificDays: _selectedFrequency == MedicationFrequency.specificDays
          ? _selectedDays
          : [],
      times: _selectedTimes,
      createdAt: DateTime.now(),
    );

    context.read<MedicationCubit>().addMedication(medication);
  }
}
