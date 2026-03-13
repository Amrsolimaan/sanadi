import 'package:equatable/equatable.dart';
import '../model/doctor_model.dart';

abstract class DoctorDetailsState extends Equatable {
  const DoctorDetailsState();

  @override
  List<Object?> get props => [];
}

// Initial
class DoctorDetailsInitial extends DoctorDetailsState {}

// Loading
class DoctorDetailsLoading extends DoctorDetailsState {}

// Loaded
class DoctorDetailsLoaded extends DoctorDetailsState {
  final DoctorModel doctor;
  final bool isFavorite;

  const DoctorDetailsLoaded({
    required this.doctor,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [doctor, isFavorite];

  DoctorDetailsLoaded copyWith({
    DoctorModel? doctor,
    bool? isFavorite,
  }) {
    return DoctorDetailsLoaded(
      doctor: doctor ?? this.doctor,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// Error
class DoctorDetailsError extends DoctorDetailsState {
  final String message;

  const DoctorDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Favorite toggled
class FavoriteToggled extends DoctorDetailsState {
  final bool isFavorite;

  const FavoriteToggled({required this.isFavorite});

  @override
  List<Object?> get props => [isFavorite];
}
