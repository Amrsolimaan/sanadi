import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore/appointment_service.dart';
import '../../../services/firestore/doctor_service.dart';
import '../model/doctor_model.dart';
import 'booking_state.dart';
import '../../../services/firestore/user_service.dart';

class BookingCubit extends Cubit<BookingState> {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DoctorModel? _doctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _bookedSlots = [];

  BookingCubit() : super(BookingInitial());

  String? get _userId => _auth.currentUser?.uid;

  // Initialize with doctor
  void initWithDoctor(DoctorModel doctor) {
    _doctor = doctor;
    _selectedDate = null;
    _selectedTime = null;
    _bookedSlots = [];

    emit(BookingReady(
      doctor: doctor,
      selectedDate: null,
      selectedTime: null,
      bookedSlots: [],
    ));
  }

  // Select date
  Future<void> selectDate(DateTime date) async {
    if (_doctor == null) return;

    _selectedDate = date;
    _selectedTime = null;

    // Emit with loading slots
    emit(BookingReady(
      doctor: _doctor!,
      selectedDate: _selectedDate,
      selectedTime: null,
      bookedSlots: [],
      isLoadingSlots: true,
    ));

    // Load booked slots for this date
    final dateStr = _formatDate(date);
    _bookedSlots =
        await _appointmentService.getBookedSlots(_doctor!.id, dateStr);

    emit(BookingReady(
      doctor: _doctor!,
      selectedDate: _selectedDate,
      selectedTime: null,
      bookedSlots: _bookedSlots,
      isLoadingSlots: false,
    ));
  }

  // Select time
  void selectTime(String time) {
    if (_doctor == null) return;

    _selectedTime = time;

    emit(BookingReady(
      doctor: _doctor!,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      bookedSlots: _bookedSlots,
    ));
  }

  // Book appointment
  Future<void> bookAppointment() async {
    if (_doctor == null || _selectedDate == null || _selectedTime == null) {
      emit(const BookingError(message: 'Please select date and time'));
      return;
    }

    if (_userId == null) {
      emit(const BookingError(message: 'User not logged in'));
      return;
    }

    emit(BookingInProgress());

    try {
      final dateStr = _formatDate(_selectedDate!);

      // Double check if slot is still available
      final isBooked = await _appointmentService.isSlotBooked(
        doctorId: _doctor!.id,
        date: dateStr,
        time: _selectedTime!,
      );

      if (isBooked) {
        emit(const BookingError(message: 'This slot is no longer available'));
        // Reload slots
        await selectDate(_selectedDate!);
        return;
      }

      // Fetch user details
      final userModel = await _userService.getUser(_userId!);

      // Create appointment
      final appointment = await _appointmentService.createAppointment(
        visitorId: _userId!,
        doctor: _doctor!,
        date: dateStr,
        time: _selectedTime!,
        patientName: userModel?.fullName,
        patientPhone: userModel?.phone,
      );

      // Add points to doctor
      await _doctorService.addPoints(_doctor!.id, 10);

      emit(BookingSuccess(
        appointment: appointment,
        doctor: _doctor!,
      ));
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  // Check if day is available
  bool isDayAvailable(DateTime date) {
    if (_doctor == null) return false;

    // Check if date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) return false;

    // Check if day of week is in availableDays
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    return _doctor!.availableDays.contains(date.weekday);
  }

  // Check if slot is available
  bool isSlotAvailable(String slot) {
    return !_bookedSlots.contains(slot);
  }

  // Format date to string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Reset
  void reset() {
    _doctor = null;
    _selectedDate = null;
    _selectedTime = null;
    _bookedSlots = [];
    emit(BookingInitial());
  }
}
