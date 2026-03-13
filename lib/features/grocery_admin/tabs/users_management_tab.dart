import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/auth/model/user_model.dart';
import 'package:sanadi/features/emergency/model/emergency_contact_model.dart'; // ✅ Import
import 'package:sanadi/features/grocery_admin/view/create_admin_dialog.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_cubit.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_state.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Import
import '../../../../core/constants/app_colors.dart';

class UsersManagementTab extends StatefulWidget {
  const UsersManagementTab({super.key});

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is AdminLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is AdminError) return Center(child: Text(state.message));
        if (state is! AdminLoaded) return const SizedBox.shrink();

        final canManageUsers = state.currentAdmin.canManageUsers();
        final users = state.filteredUsers;

        return Column(
          children: [
            // Search & Add Admin
            // Add Admin Button (search is in dashboard app bar)
            if (canManageUsers)
              Padding(
                padding: EdgeInsets.all(isLarge ? 24 : 16.w),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showCreateAdminDialog(context, state.currentAdmin.uid),
                    icon: const Icon(Icons.person_add),
                    label: Text('admin.add_admin'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                ),
              ),

            // Filter Chips
            SizedBox(
              height: 50.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                children: [
                  _buildFilterChip(
                      'all',
                      'admin.all_users'.tr(),
                      state.userStats['total'] ?? 0,
                      state.selectedFilter,
                      isLarge),
                  _buildFilterChip(
                      'users',
                      'admin.role_user'.tr(),
                      state.userStats['users'] ?? 0,
                      state.selectedFilter,
                      isLarge),
                  _buildFilterChip(
                      'admins',
                      'admin.admins'.tr(),
                      (state.userStats['admins'] ?? 0) +
                          (state.userStats['superAdmins'] ?? 0),
                      state.selectedFilter,
                      isLarge),
                  _buildFilterChip(
                      'moderators',
                      'admin.moderators'.tr(),
                      state.userStats['moderators'] ?? 0,
                      state.selectedFilter,
                      isLarge),
                  _buildFilterChip(
                      'active',
                      'admin.active_users'.tr(),
                      state.userStats['active'] ?? 0,
                      state.selectedFilter,
                      isLarge),
                  _buildFilterChip(
                      'inactive',
                      'admin.inactive_users'.tr(),
                      state.userStats['inactive'] ?? 0,
                      state.selectedFilter,
                      isLarge),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Users List
            Expanded(
              child: users.isEmpty
                  ? Center(child: Text('admin.no_data'.tr()))
                  : ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                      itemCount: users.length,
                      itemBuilder: (context, index) => _buildUserCard(
                          context, users[index], isLarge, lang, canManageUsers),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String filter, String label, int count,
      String selectedFilter, bool isLarge) {
    final isSelected = selectedFilter == filter;

    return GestureDetector(
      onTap: () => context.read<AdminCubit>().changeFilter(filter),
      child: Container(
        margin: EdgeInsetsDirectional.only(end: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withOpacity(0.2)
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: isLarge ? 12 : 11.sp,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, bool isLarge,
      String lang, bool canManage) {
    Color roleColor;
    switch (user.role) {
      case UserRole.superAdmin:
        roleColor = Colors.purple;
        break;
      case UserRole.admin:
        roleColor = Colors.blue;
        break;
      case UserRole.moderator:
        roleColor = Colors.orange;
        break;
      default:
        roleColor = AppColors.textSecondary;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: isLarge ? 28 : 24,
                backgroundImage:
                    user.profileImage != null && user.profileImage!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImage!)
                        : null,
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? Icon(Icons.person, size: isLarge ? 28 : 24.sp)
                    : null,
              ),
              if (!user.isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: TextStyle(
                            fontSize: isLarge ? 16 : 14.sp,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.getDisplayName(lang),
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: roleColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(user.email,
                    style: TextStyle(
                        fontSize: 12.sp, color: AppColors.textSecondary)),
                if (user.phone.isNotEmpty)
                  Text(user.phone,
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.textHint)),
              ],
            ),
          ),

          // Actions
          if (canManage)
            PopupMenuButton<String>(
              onSelected: (v) => _handleAction(context, v, user),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(children: [
                    const Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8.w),
                    Text('admin.user_details'.tr())
                  ]),
                ),
                PopupMenuItem(
                  value: 'role',
                  child: Row(children: [
                    const Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 8.w),
                    Text('admin.change_role'.tr())
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(user.isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                        color: user.isActive
                            ? AppColors.error
                            : AppColors.success),
                    SizedBox(width: 8.w),
                    Text(user.isActive
                        ? 'admin.deactivate'.tr()
                        : 'admin.activate'.tr()),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8.w),
                    Text('admin.delete_user'.tr(),
                        style: const TextStyle(color: AppColors.error))
                  ]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, UserModel user) {
    switch (action) {
      case 'view':
        _showUserDetailsSheet(context, user);
        break;
      case 'role':
        _showChangeRoleDialog(context, user);
        break;
      case 'toggle':
        context.read<AdminCubit>().toggleUserActive(user.uid, !user.isActive);
        break;
      case 'delete':
        _showDeleteUserDialog(context, user);
        break;
    }
  }

  void _showUserDetailsSheet(BuildContext context, UserModel user) {
    final lang = context.locale.languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Container(
          padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? CachedNetworkImageProvider(user.profileImage!)
                            : null,
                        child: user.profileImage == null ||
                                user.profileImage!.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      Text(user.fullName,
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold)),
                      Container(
                        margin: EdgeInsets.only(top: 8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(user.role.getDisplayName(lang),
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                _buildSectionTitle('Contact Info'),
                _buildDetailRow(Icons.email, user.email),
                if (user.phone.isNotEmpty)
                  _buildDetailRow(Icons.phone, user.phone),
                _buildDetailRow(Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(user.createdAt)),
                _buildDetailRow(
                    user.isActive ? Icons.check_circle : Icons.cancel,
                    user.isActive ? 'Active' : 'Inactive',
                    color: user.isActive ? AppColors.success : AppColors.error),
                SizedBox(height: 16.h),
                _buildSectionTitle('Location'),
                if (user.location != null) ...[
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(user.location!.googleMapsUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: AppColors.primary),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(user.location!.formattedCoordinates,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    decoration: TextDecoration.underline)),
                          ),
                          const Icon(Icons.open_in_new, size: 16),
                        ],
                      ),
                    ),
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text('No location data available',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.textSecondary)),
                  ),
                SizedBox(height: 16.h),
                _buildSectionTitle('Emergency Contacts'),
                SizedBox(height: 8.h),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('emergency_contacts')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text('No emergency contacts found',
                          style: TextStyle(
                              fontSize: 14.sp, color: AppColors.textSecondary));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final contact = EmergencyContactModel.fromMap(
                            doc.data() as Map<String, dynamic>, doc.id);
                        return Card(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: ListTile(
                            leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child:
                                    Icon(Icons.emergency, color: Colors.white)),
                            title: Text(contact.name),
                            subtitle: Text(contact.relationship ?? 'Unknown'),
                            trailing: IconButton(
                              icon: const Icon(Icons.call,
                                  color: AppColors.success),
                              onPressed: () async {
                                final url = Uri.parse('tel:${contact.phone}');
                                if (await canLaunchUrl(url))
                                  await launchUrl(url);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: color ?? AppColors.textSecondary),
          SizedBox(width: 12.w),
          Text(text,
              style: TextStyle(
                  fontSize: 14.sp, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, UserModel user) {
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('admin.change_role'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(role.getDisplayName(context.locale.languageCode)),
                value: role,
                groupValue: selectedRole,
                onChanged: (v) => setState(() => selectedRole = v!),
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('general.cancel'.tr())),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context
                    .read<AdminCubit>()
                    .changeUserRole(user.uid, selectedRole);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('general.save'.tr(),
                  style: const TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.delete_user'.tr()),
        content: Text('${user.fullName}\n\n${'admin.delete_confirm'.tr()}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('general.cancel'.tr())),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCubit>().deleteUser(user.uid);
            },
            child: Text('general.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminDialog(BuildContext context, String creatorUid) {
    showDialog(
      context: context,
      builder: (_) => CreateAdminDialog(creatorUid: creatorUid),
    ).then((result) {
      if (result == true) context.read<AdminCubit>().refresh();
    });
  }
}
