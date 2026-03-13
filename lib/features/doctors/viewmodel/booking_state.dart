import 'package:equatable/equatable.dart';
import '../model/doctor_model.dart';
import '../model/appointment_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

// Initial
class BookingInitial extends BookingState {}

// Loading
class BookingLoading extends BookingState {}

// Ready to book
class BookingReady extends BookingState {
  final DoctorModel doctor;
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> bookedSlots;
  final bool isLoadingSlots;

  const BookingReady({
    required this.doctor,
    this.selectedDate,
    this.selectedTime,
    this.bookedSlots = const [],
    this.isLoadingSlots = false,
  });

  @override
  List<Object?> get props => [
        doctor,
        selectedDate,
        selectedTime,
        bookedSlots,
        isLoadingSlots,
      ];

  BookingReady copyWith({
    DoctorModel? doctor,
    DateTime? selectedDate,
    String? selectedTime,
    List<String>? bookedSlots,
    bool? isLoadingSlots,
    bool clearDate = false,
    bool clearTime = false,
  }) {
    return BookingReady(
      doctor: doctor ?? this.doctor,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedTime: clearTime ? null : (selectedTime ?? this.selectedTime),
      bookedSlots: bookedSlots ?? this.bookedSlots,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
    );
  }

  bool get canBook => selectedDate != null && selectedTime != null;
}

// Booking in progress
class BookingInProgress extends BookingState {}

// Booking success
class BookingSuccess extends BookingState {
  final AppointmentModel appointment;
  final DoctorModel doctor;

  const BookingSuccess({
    required this.appointment,
    required this.doctor,
  });

  @override
  List<Object?> get props => [appointment, doctor];
}

// Booking error
class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}
