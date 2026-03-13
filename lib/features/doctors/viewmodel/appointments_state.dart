import 'package:equatable/equatable.dart';
import '../model/appointment_model.dart';

abstract class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object?> get props => [];
}

// Initial
class AppointmentsInitial extends AppointmentsState {}

// Loading
class AppointmentsLoading extends AppointmentsState {}

// Loaded
class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentModel> appointments;
  final DateTime? selectedDate;
  final AppointmentStatus selectedStatus;

  const AppointmentsLoaded({
    required this.appointments,
    this.selectedDate,
    required this.selectedStatus,
  });

  @override
  List<Object?> get props => [appointments, selectedDate, selectedStatus];

  AppointmentsLoaded copyWith({
    List<AppointmentModel>? appointments,
    DateTime? selectedDate,
    AppointmentStatus? selectedStatus,
  }) {
    return AppointmentsLoaded(
      appointments: appointments ?? this.appointments,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

// Empty
class AppointmentsEmpty extends AppointmentsState {
  final DateTime? selectedDate;
  final AppointmentStatus selectedStatus;

  const AppointmentsEmpty({
    this.selectedDate,
    required this.selectedStatus,
  });

  @override
  List<Object?> get props => [selectedDate, selectedStatus];
}

// Error
class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Appointment cancelled
class AppointmentCancelled extends AppointmentsState {}
