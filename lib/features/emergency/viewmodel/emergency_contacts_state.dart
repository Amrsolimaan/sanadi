import 'package:equatable/equatable.dart';
import '../model/emergency_contact_model.dart';

abstract class EmergencyContactsState extends Equatable {
  const EmergencyContactsState();

  @override
  List<Object?> get props => [];
}

// Initial
class EmergencyContactsInitial extends EmergencyContactsState {}

// Loading
class EmergencyContactsLoading extends EmergencyContactsState {}

// Loaded
class EmergencyContactsLoaded extends EmergencyContactsState {
  final List<EmergencyContactModel> contacts;
  final String? primaryContactId;
  final EmergencyContactModel? primaryContact;

  const EmergencyContactsLoaded({
    required this.contacts,
    this.primaryContactId,
    this.primaryContact,
  });

  @override
  List<Object?> get props => [contacts, primaryContactId, primaryContact];
}

// Error
class EmergencyContactsError extends EmergencyContactsState {
  final String message;

  const EmergencyContactsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Contact Added
class EmergencyContactAdded extends EmergencyContactsState {
  final EmergencyContactModel contact;

  const EmergencyContactAdded({required this.contact});

  @override
  List<Object?> get props => [contact];
}

// Contact Updated
class EmergencyContactUpdated extends EmergencyContactsState {
  final EmergencyContactModel contact;

  const EmergencyContactUpdated({required this.contact});

  @override
  List<Object?> get props => [contact];
}

// Contact Deleted
class EmergencyContactDeleted extends EmergencyContactsState {}

// Primary Contact Set
class PrimaryContactSet extends EmergencyContactsState {
  final String contactId;

  const PrimaryContactSet({required this.contactId});

  @override
  List<Object?> get props => [contactId];
}

// Calling
class EmergencyCallInProgress extends EmergencyContactsState {
  final String phoneNumber;
  final String name;

  const EmergencyCallInProgress({
    required this.phoneNumber,
    required this.name,
  });

  @override
  List<Object?> get props => [phoneNumber, name];
}
