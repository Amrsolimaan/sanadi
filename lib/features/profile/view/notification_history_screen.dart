import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/medications/model/notification_event_model.dart';
import 'package:sanadi/services/firestore/notification_history_service.dart';
import '../../../core/constants/app_colors.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationHistoryService _historyService =
      NotificationHistoryService();

  NotificationEventType? _selectedFilter;
  List<NotificationEventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      List<NotificationEventModel> events;

      if (_selectedFilter != null) {
        events = await _historyService.getEventsByType(_selectedFilter!);
      } else {
        events = await _historyService.getUserNotificationHistory(
          limitCount: 100,
        );
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('profile.notification_history'.tr()),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Events List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(_events[index], isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: context.locale.languageCode == 'ar' ? 'الكل' : 'All',
              isSelected: _selectedFilter == null,
              onTap: () {
                setState(() => _selectedFilter = null);
                _loadEvents();
              },
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              label: context.locale.languageCode == 'ar' ? '🔔 رنّ' : '🔔 Rang',
              isSelected: _selectedFilter == NotificationEventType.alarmRang,
              onTap: () {
                setState(() => _selectedFilter = NotificationEventType.alarmRang);
                _loadEvents();
              },
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              label:
                  context.locale.languageCode == 'ar' ? '⏰ فائت' : '⏰ Missed',
              isSelected: _selectedFilter == NotificationEventType.alarmMissed,
              onTap: () {
                setState(() =>
                    _selectedFilter = NotificationEventType.alarmMissed);
                _loadEvents();
              },
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              label: context.locale.languageCode == 'ar'
                  ? '✅ تم التناول'
                  : '✅ Taken',
              isSelected:
                  _selectedFilter == NotificationEventType.medicationTaken,
              onTap: () {
                setState(() =>
                    _selectedFilter = NotificationEventType.medicationTaken);
                _loadEvents();
              },
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              label:
                  context.locale.languageCode == 'ar' ? '⏭️ تخطي' : '⏭️ Skipped',
              isSelected:
                  _selectedFilter == NotificationEventType.medicationSkipped,
              onTap: () {
                setState(() =>
                    _selectedFilter = NotificationEventType.medicationSkipped);
                _loadEvents();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(NotificationEventModel event, bool isDark) {
    final isArabic = context.locale.languageCode == 'ar';
    final timeAgo = _getTimeAgo(event.timestamp, isArabic);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: _getEventColor(event.eventType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                event.getEventIcon(),
                style: TextStyle(fontSize: 24.sp),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.medicationName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  event.getEventLabel(isArabic ? 'ar' : 'en'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _getEventColor(event.eventType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${isArabic ? "الموعد" : "Time"}: ${event.scheduledTime}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Time ago
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isArabic = context.locale.languageCode == 'ar';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            isArabic ? 'لا توجد إشعارات' : 'profile.no_notifications'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isArabic
                ? 'ستظهر سجلات المنبهات والأدوية هنا'
                : 'Alarm and medication logs will appear here',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getEventColor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.alarmRang:
        return Colors.blue;
      case NotificationEventType.alarmMissed:
        return Colors.orange;
      case NotificationEventType.medicationTaken:
        return Colors.green;
      case NotificationEventType.medicationSkipped:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime timestamp, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Now';
    } else if (difference.inMinutes < 60) {
      return isArabic
          ? 'منذ ${difference.inMinutes} د'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return isArabic
          ? 'منذ ${difference.inHours} س'
          : '${difference.inHours}h ago';
    } else {
      return isArabic
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    }
  }
}
