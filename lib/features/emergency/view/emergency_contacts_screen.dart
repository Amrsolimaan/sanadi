import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../model/emergency_contact_model.dart';
import '../viewmodel/emergency_contacts_cubit.dart';
import '../viewmodel/emergency_contacts_state.dart';
import 'add_edit_contact_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmergencyContactsCubit>().loadContacts();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _addContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditContactScreen()),
    ).then((_) {
      context.read<EmergencyContactsCubit>().loadContacts();
    });
  }

  void _editContact(EmergencyContactModel contact) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditContactScreen(contact: contact)),
    ).then((_) {
      context.read<EmergencyContactsCubit>().loadContacts();
    });
  }

  void _deleteContact(EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('emergency.delete_contact'.tr()),
        content: Text('emergency.delete_confirm'.tr(args: [contact.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EmergencyContactsCubit>().deleteContact(contact.id);
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

  void _setPrimaryContact(EmergencyContactModel contact) {
    context.read<EmergencyContactsCubit>().setPrimaryContact(contact.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('emergency.primary_set'.tr(args: [contact.name])),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _removePrimaryContact() {
    context.read<EmergencyContactsCubit>().removePrimaryContact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('emergency.primary_removed'.tr()),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _callContact(EmergencyContactModel contact) {
    context.read<EmergencyContactsCubit>().callContact(contact);
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<EmergencyContactsCubit, EmergencyContactsState>(
          listener: (context, state) {
            if (state is EmergencyContactsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is EmergencyContactDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('emergency.contact_deleted'.tr()),
                  backgroundColor: AppColors.success,
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'emergency.contacts_description'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side - Content
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 80, 48, 48),
                    child: _buildContent(context, state, isDesktop: true),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
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
          'emergency.emergency_contacts'.tr(),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildContent(context, state, isDesktop: false),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  // Shared Content
  Widget _buildContent(BuildContext context, EmergencyContactsState state,
      {required bool isDesktop}) {
    // Show loading only on initial load (when contacts list is empty)
    if (state is EmergencyContactsLoading) {
      final cubit = context.read<EmergencyContactsCubit>();
      if (cubit.contacts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    // Get data from cubit directly to ensure consistency
    final cubit = context.read<EmergencyContactsCubit>();
    List<EmergencyContactModel> contacts = cubit.contacts;
    String? primaryContactId = cubit.primaryContactId;

    // Update from state if available
    if (state is EmergencyContactsLoaded) {
      contacts = state.contacts;
      primaryContactId = state.primaryContactId;
    }

    if (contacts.isEmpty) {
      return _buildEmptyState(isDesktop);
    }

    return _buildContactsList(contacts, primaryContactId, isDesktop);
  }

  // Empty State
  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_phone_outlined,
            size: isDesktop ? 80 : 64.sp,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: isDesktop ? 24 : 16.h),
          Text(
            'emergency.no_contacts'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isDesktop ? 8 : 8.h),
          Text(
            'emergency.add_contacts_hint'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 14 : 14.sp,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Contacts List
  Widget _buildContactsList(List<EmergencyContactModel> contacts,
      String? primaryContactId, bool isDesktop) {
    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 12 : 12.h),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isPrimary = primaryContactId == contact.id;
        return _buildContactCard(contact, isPrimary, isDesktop);
      },
    );
  }

  // Contact Card
  Widget _buildContactCard(
      EmergencyContactModel contact, bool isPrimary, bool isDesktop) {
    return InkWell(
      onTap: () => _callContact(contact),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Phone Icon
            Container(
              width: isDesktop ? 48 : 44.w,
              height: isDesktop ? 48 : 44.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.phone,
                color: AppColors.primary,
                size: isDesktop ? 24 : 22.sp,
              ),
            ),

            SizedBox(width: isDesktop ? 16 : 12.w),

            // Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isPrimary) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6.w,
                            vertical: isDesktop ? 4 : 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'emergency.primary_badge'.tr(),
                            style: TextStyle(
                              fontSize: isDesktop ? 10 : 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isDesktop ? 4 : 4.h),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (contact.relationship != null &&
                      contact.relationship!.isNotEmpty) ...[
                    SizedBox(height: isDesktop ? 2 : 2.h),
                    Text(
                      contact.relationship!,
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Options Menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: isDesktop ? 24 : 20.sp,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'call':
                    _callContact(contact);
                    break;
                  case 'edit':
                    _editContact(contact);
                    break;
                  case 'delete':
                    _deleteContact(contact);
                    break;
                  case 'set_primary':
                    _setPrimaryContact(contact);
                    break;
                  case 'remove_primary':
                    _removePrimaryContact();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 20),
                      const SizedBox(width: 8),
                      Text('emergency.call'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text('general.edit'.tr()),
                    ],
                  ),
                ),
                if (!isPrimary)
                  PopupMenuItem(
                    value: 'set_primary',
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 20, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('emergency.set_as_primary'.tr()),
                      ],
                    ),
                  ),
                if (isPrimary)
                  PopupMenuItem(
                    value: 'remove_primary',
                    child: Row(
                      children: [
                        const Icon(Icons.star_border, size: 20),
                        const SizedBox(width: 8),
                        Text('emergency.remove_primary'.tr()),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'general.delete'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
