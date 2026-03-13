import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore/appointment_service.dart';
import '../model/appointment_model.dart';
import 'appointments_state.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  final AppointmentService _appointmentService = AppointmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedDate; // Nullable for "All"
  AppointmentStatus _selectedStatus = AppointmentStatus.upcoming;
  List<AppointmentModel> _appointments = [];

  AppointmentsCubit() : super(AppointmentsInitial());

  String? get _userId => _auth.currentUser?.uid;

  // Getters
  DateTime? get selectedDate => _selectedDate;
  AppointmentStatus get selectedStatus => _selectedStatus;

  // ============================================
  // Load appointments with error handling
  // ============================================
  Future<void> loadAppointments() async {
    if (_userId == null) {
      emit(const AppointmentsError(
          message: 'Please login to view your appointments'));
      return;
    }

    emit(AppointmentsLoading());

    try {
      // تحديث الحجوزات القديمة في الخلفية بدون انتظار
      _appointmentService.updateOldAppointments(_userId!).catchError((error) {
        // نتجاهل أخطاء التحديث الخلفي
        print('Background update error: $error');
      });

      // تحميل الحجوزات
      await _loadByDateAndStatus();
    } on FirebaseAuthException catch (e) {
      emit(AppointmentsError(
          message: 'Authentication error. Please login again.'));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        emit(const AppointmentsError(
            message: 'Access denied. Please check your permissions.'));
      } else if (e.code == 'unavailable') {
        emit(const AppointmentsError(
            message: 'Service unavailable. Please try again later.'));
      } else {
        emit(const AppointmentsError(
            message: 'Unable to load appointments. Please try again.'));
      }
    } catch (e) {
      emit(const AppointmentsError(
          message:
              'Failed to load appointments. Please check your connection.'));
    }
  }

  // ============================================
  // Select date (Toggle logic)
  // ============================================
  Future<void> selectDate(DateTime date) async {
    // If same date selected -> Deselect (Show All)
    if (_selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day) {
      _selectedDate = null;
    } else {
      // New date selected
      _selectedDate = date;
    }
    await _loadByDateAndStatus();
  }

  // ============================================
  // Select All (Clear Date Filter)
  // ============================================
  Future<void> selectAll() async {
    _selectedDate = null;
    await _loadByDateAndStatus();
  }

  // ============================================
  // Select status
  // ============================================
  Future<void> selectStatus(AppointmentStatus status) async {
    _selectedStatus = status;
    await _loadByDateAndStatus();
  }

  // ============================================
  // Load by date and status with error handling
  // ============================================
  Future<void> _loadByDateAndStatus() async {
    if (_userId == null) return;

    emit(AppointmentsLoading());

    try {
      if (_selectedDate == null) {
        // Fetch ALL by status
        _appointments = await _appointmentService.getAppointmentsByStatus(
          _userId!,
          _selectedStatus,
        );
      } else {
        // Fetch specific date
        final dateStr = _formatDate(_selectedDate!);
        _appointments =
            await _appointmentService.getAppointmentsByDateAndStatus(
          _userId!,
          dateStr,
          _selectedStatus,
        );
      }

      if (_appointments.isEmpty) {
        emit(AppointmentsEmpty(
          selectedDate: _selectedDate,
          selectedStatus: _selectedStatus,
        ));
      } else {
        emit(AppointmentsLoaded(
          appointments: _appointments,
          selectedDate: _selectedDate,
          selectedStatus: _selectedStatus,
        ));
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        emit(const AppointmentsError(
            message: 'Access denied. Please check your permissions.'));
      } else if (e.code == 'unavailable') {
        emit(const AppointmentsError(
            message: 'Service unavailable. Please try again later.'));
      } else {
        emit(const AppointmentsError(
            message: 'Unable to load appointments. Please try again.'));
      }
    } catch (e) {
      emit(const AppointmentsError(
          message:
              'Failed to load appointments. Please check your connection.'));
    }
  }

  // ============================================
  // Cancel appointment with error handling
  // ============================================

  Future<void> cancelAppointment(String appointmentId) async {
    if (_userId == null) return;

    try {
      await _appointmentService.cancelAppointment(_userId!, appointmentId);

      emit(AppointmentCancelled());

      // إعادة تحميل الحجوزات
      await _loadByDateAndStatus();
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        emit(const AppointmentsError(message: 'Appointment not found.'));
      } else if (e.code == 'permission-denied') {
        emit(const AppointmentsError(
            message: 'You do not have permission to cancel this appointment.'));
      } else {
        emit(const AppointmentsError(
            message: 'Failed to cancel appointment. Please try again.'));
      }
      // إعادة تحميل الحجوزات بعد الخطأ
      await _loadByDateAndStatus();
    } catch (e) {
      emit(const AppointmentsError(
          message:
              'Failed to cancel appointment. Please check your connection.'));
      await _loadByDateAndStatus();
    }
  }

  // ============================================
  // Format date
  // ============================================
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================
  // Get dates for the week starting from today
  // ============================================
  List<DateTime> getWeekDates({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (index) {
      return DateTime(now.year, now.month, now.day + index);
    });
  }

  // ============================================
  // Refresh
  // ============================================
  Future<void> refresh() async {
    await loadAppointments();
  }
}
