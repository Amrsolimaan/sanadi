import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../../../core/utils/validators.dart';
import '../model/emergency_contact_model.dart';
import '../viewmodel/emergency_contacts_cubit.dart';
import '../viewmodel/emergency_contacts_state.dart';

class AddEditContactScreen extends StatefulWidget {
  final EmergencyContactModel? contact;

  const AddEditContactScreen({super.key, this.contact});

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone;
      _relationshipController.text = widget.contact!.relationship ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<EmergencyContactsCubit>();

      if (isEditing) {
        final updatedContact = widget.contact!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim().isEmpty
              ? null
              : _relationshipController.text.trim(),
          updatedAt: DateTime.now(),
        );
        cubit.updateContact(updatedContact);
      } else {
        cubit.addContact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim().isEmpty
              ? null
              : _relationshipController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<EmergencyContactsCubit, EmergencyContactsState>(
          listener: (context, state) {
            if (state is EmergencyContactAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('emergency.contact_added'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            } else if (state is EmergencyContactUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('emergency.contact_updated'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            } else if (state is EmergencyContactsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (isLarge) {
              return _buildDesktopLayout(context, state);
            }
            return _buildMobileLayout(context, state);
          },
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
      BuildContext context, EmergencyContactsState state) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          // Left Side - Branding
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.logo, height: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Sanadi',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side - Form
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildForm(context, state, isDesktop: true),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Positioned(
                    top: 24,
                    right: 24,
                    child: LanguageButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(
      BuildContext context, EmergencyContactsState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing
              ? 'emergency.edit_contact'.tr()
              : 'emergency.add_contact'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildForm(context, state, isDesktop: false),
        ),
      ),
    );
  }

  // Shared Form
  Widget _buildForm(BuildContext context, EmergencyContactsState state,
      {required bool isDesktop}) {
    final isLoading = state is EmergencyContactsLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title (Desktop only)
          if (isDesktop) ...[
            Text(
              isEditing
                  ? 'emergency.edit_contact'.tr()
                  : 'emergency.add_contact'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'emergency.contact_form_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],

          if (!isDesktop) SizedBox(height: 20.h),

          // Name Field
          _buildTextField(
            controller: _nameController,
            hintText: 'emergency.contact_name'.tr(),
            prefixIcon: Icons.person_outline,
            validator: Validators.validateName,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Phone Field
          _buildTextField(
            controller: _phoneController,
            hintText: 'emergency.contact_phone'.tr(),
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Relationship Field (Optional)
          _buildTextField(
            controller: _relationshipController,
            hintText: 'emergency.relationship'.tr(),
            prefixIcon: Icons.people_outline,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 8 : 8.h),

          // Hint for relationship
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 4.w),
            child: Text(
              'emergency.relationship_hint'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 12 : 11.sp,
                color: AppColors.textHint,
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 40 : 32.h),

          // Save Button
          _buildButton(
            text:
                isEditing ? 'general.save'.tr() : 'emergency.add_contact'.tr(),
            onPressed: _saveContact,
            isLoading: isLoading,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 0 : 24.h),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 22),
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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

    return CustomTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2.5),
                )
              : Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return CustomButton(text: text, onPressed: onPressed, isLoading: isLoading);
  }
}
