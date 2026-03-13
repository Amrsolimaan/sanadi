import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_widgets.dart';

class RecordsScreen extends StatelessWidget {
  final bool showAppBar;
  final int initialTab;

  const RecordsScreen({super.key, this.showAppBar = true, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: showAppBar ? _buildAppBar() : null,
        body: Column(
          children: [
            if (!showAppBar) _buildTabBarOnly(),
            Expanded(
              child: TabBarView(
                children: [_AppointmentsHistoryTab(), _MedicalRecordsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: Text('records.title'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      centerTitle: true,
      bottom: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        tabs: [Tab(text: 'records.history'.tr()), Tab(text: 'records.medical_records'.tr())],
      ),
    );
  }

  Widget _buildTabBarOnly() {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('records.title'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              tabs: [Tab(text: 'records.history'.tr()), Tab(text: 'records.medical_records'.tr())],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.history,
      title: 'records.no_history'.tr(),
      message: 'records.no_history_message'.tr(),
    );
  }
}

class _MedicalRecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.folder_open,
      title: 'records.no_records'.tr(),
      message: 'records.no_records_message'.tr(),
    );
  }
}
