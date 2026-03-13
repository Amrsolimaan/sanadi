import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../model/doctor_model.dart';
import '../viewmodel/booking_cubit.dart';
import '../viewmodel/booking_state.dart';
import 'booking_success_screen.dart';

class BookingScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<BookingCubit>().initWithDoctor(widget.doctor);
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingSuccessScreen(
                    appointment: state.appointment,
                    doctor: state.doctor,
                  ),
                ),
              );
            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (isLarge) {
              return _buildDesktopLayout(context, state, lang);
            }
            return _buildMobileLayout(context, state, lang);
          },
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
      BuildContext context, BookingState state, String lang) {
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
                  _buildContent(context, state, lang, isDesktop: true),
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
      BuildContext context, BookingState state, String lang) {
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
          'booking.title'.tr(),
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
        child: _buildContent(context, state, lang, isDesktop: false),
      ),
    );
  }

  // Content
  Widget _buildContent(BuildContext context, BookingState state, String lang,
      {required bool isDesktop}) {
    if (state is BookingInProgress) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    DateTime? selectedDate;
    String? selectedTime;
    List<String> bookedSlots = [];
    bool isLoadingSlots = false;

    if (state is BookingReady) {
      selectedDate = state.selectedDate;
      selectedTime = state.selectedTime;
      bookedSlots = state.bookedSlots;
      isLoadingSlots = state.isLoadingSlots;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 48 : 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  Text(
                    'booking.title'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Calendar
                _buildCalendar(context, selectedDate, isDesktop),

                SizedBox(height: isDesktop ? 32 : 24.h),

                // Time Slots
                Text(
                  'booking.available_slots'.tr(),
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : 12.h),

                if (selectedDate == null)
                  Text(
                    'booking.select_date_first'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13.sp,
                      color: AppColors.textHint,
                    ),
                  )
                else if (isLoadingSlots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else
                  _buildTimeSlots(
                      context, selectedTime, bookedSlots, isDesktop),
              ],
            ),
          ),
        ),

        // Book Now Button
        _buildBottomButton(context, state, isDesktop),
      ],
    );
  }

  // Calendar
  Widget _buildCalendar(
      BuildContext context, DateTime? selectedDate, bool isDesktop) {
    final cubit = context.read<BookingCubit>();
    final now = DateTime.now();

    // Get days in current month
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Column(
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthNames[_currentMonth.month - 1],
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentMonth.month > now.month ||
                          _currentMonth.year > now.year
                      ? () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month - 1);
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth =
                          DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: isDesktop ? 16 : 12.h),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
            return SizedBox(
              width: isDesktop ? 40 : 36.w,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: isDesktop ? 8 : 6.h),

        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: isDesktop ? 8 : 4.h,
            crossAxisSpacing: isDesktop ? 8 : 4.w,
          ),
          itemCount: 42, // 6 weeks
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date =
                DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            final isAvailable = cubit.isDayAvailable(date);
            final isSelected = selectedDate != null &&
                selectedDate.year == date.year &&
                selectedDate.month == date.month &&
                selectedDate.day == date.day;
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            return GestureDetector(
              onTap: isAvailable ? () => cubit.selectDate(date) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isAvailable
                          ? AppColors.error.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12.sp,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.white
                          : isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textHint.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Time Slots
  Widget _buildTimeSlots(BuildContext context, String? selectedTime,
      List<String> bookedSlots, bool isDesktop) {
    final cubit = context.read<BookingCubit>();
    final slots = widget.doctor.availableSlots;

    if (slots.isEmpty) {
      return Text(
        'booking.no_slots'.tr(),
        style: TextStyle(
          fontSize: isDesktop ? 14 : 13.sp,
          color: AppColors.textHint,
        ),
      );
    }

    return Wrap(
      spacing: isDesktop ? 12 : 8.w,
      runSpacing: isDesktop ? 12 : 8.h,
      children: slots.map((slot) {
        final isBooked = bookedSlots.contains(slot);
        final isSelected = selectedTime == slot;

        return GestureDetector(
          onTap: isBooked ? null : () => cubit.selectTime(slot),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16.w,
              vertical: isDesktop ? 12 : 10.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isBooked
                      ? AppColors.lightGrey.withOpacity(0.5)
                      : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isBooked
                        ? AppColors.lightGrey
                        : AppColors.primary,
              ),
            ),
            child: Text(
              _formatTime(slot),
              style: TextStyle(
                fontSize: isDesktop ? 13 : 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.white
                    : isBooked
                        ? AppColors.textHint
                        : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Format time
  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return time;
    }
  }

  // Bottom Button
  Widget _buildBottomButton(
      BuildContext context, BookingState state, bool isDesktop) {
    final canBook = state is BookingReady && state.canBook;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: isDesktop ? 52 : 48.h,
        child: ElevatedButton(
          onPressed: canBook
              ? () => context.read<BookingCubit>().bookAppointment()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.lightGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'booking.book_now'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
