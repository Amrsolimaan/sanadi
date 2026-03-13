import 'package:equatable/equatable.dart';
import '../model/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial
class AuthInitial extends AuthState {}

// Loading
class AuthLoading extends AuthState {}

// Success
class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

// Error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// OTP Sent
class OtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const OtpSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

// OTP Verified
class OtpVerified extends AuthState {
  final String verificationId;

  const OtpVerified({required this.verificationId});

  @override
  List<Object?> get props => [verificationId];
}

// Password Reset Done
class PasswordResetDone extends AuthState {}

// Logged Out
class AuthLoggedOut extends AuthState {}
