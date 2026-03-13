import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/emergency_contact_model.dart';
import '../../../services/firestore/emergency_contact_service.dart';
import 'emergency_contacts_state.dart';

class EmergencyContactsCubit extends Cubit<EmergencyContactsState> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<EmergencyContactModel> _contacts = [];
  String? _primaryContactId;
  EmergencyContactModel? _primaryContact;

  EmergencyContactsCubit() : super(EmergencyContactsInitial());

  String? get _userId => _auth.currentUser?.uid;

  // Getters
  List<EmergencyContactModel> get contacts => _contacts;
  String? get primaryContactId => _primaryContactId;
  EmergencyContactModel? get primaryContact => _primaryContact;

  // Load all contacts
  Future<void> loadContacts() async {
    if (_userId == null) {
      emit(const EmergencyContactsError(message: 'User not logged in'));
      return;
    }

    emit(EmergencyContactsLoading());

    try {
      _contacts = await _contactService.getContacts(_userId!);
      _primaryContactId = await _contactService.getPrimaryContactId(_userId!);

      // Get primary contact from loaded contacts
      _primaryContact = null;
      if (_primaryContactId != null && _primaryContactId!.isNotEmpty) {
        for (var contact in _contacts) {
          if (contact.id == _primaryContactId) {
            _primaryContact = contact;
            break;
          }
        }
      }

      emit(EmergencyContactsLoaded(
        contacts: _contacts,
        primaryContactId: _primaryContactId,
        primaryContact: _primaryContact,
      ));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
    }
  }

  // Add contact
  Future<void> addContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    if (_userId == null) return;

    emit(EmergencyContactsLoading());

    try {
      final contact = EmergencyContactModel(
        id: '',
        name: name,
        phone: phone,
        relationship: relationship,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newContact = await _contactService.addContact(_userId!, contact);
      _contacts.insert(0, newContact);

      emit(EmergencyContactAdded(contact: newContact));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
    }
  }

  // Update contact
  Future<void> updateContact(EmergencyContactModel contact) async {
    if (_userId == null) return;

    emit(EmergencyContactsLoading());

    try {
      await _contactService.updateContact(_userId!, contact);

      // Update local list
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
      }

      // Update primary contact if it was updated
      if (_primaryContactId == contact.id) {
        _primaryContact = contact;
      }

      emit(EmergencyContactUpdated(contact: contact));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
    }
  }

  // Delete contact
  Future<void> deleteContact(String contactId) async {
    if (_userId == null) return;

    emit(EmergencyContactsLoading());

    try {
      // If deleting primary contact, clear it first
      if (_primaryContactId == contactId) {
        await _contactService.setPrimaryContact(_userId!, null);
        _primaryContactId = null;
        _primaryContact = null;
      }

      await _contactService.deleteContact(_userId!, contactId);
      _contacts.removeWhere((c) => c.id == contactId);

      emit(EmergencyContactDeleted());

      // Emit loaded state to update UI
      emit(EmergencyContactsLoaded(
        contacts: _contacts,
        primaryContactId: _primaryContactId,
        primaryContact: _primaryContact,
      ));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
    }
  }

  // Set primary contact
  Future<void> setPrimaryContact(String contactId) async {
    if (_userId == null) return;

    try {
      await _contactService.setPrimaryContact(_userId!, contactId);
      _primaryContactId = contactId;

      // Find primary contact from current list
      _primaryContact = null;
      for (var contact in _contacts) {
        if (contact.id == contactId) {
          _primaryContact = contact;
          break;
        }
      }

      // Emit loaded state directly with updated primary
      emit(EmergencyContactsLoaded(
        contacts: _contacts,
        primaryContactId: _primaryContactId,
        primaryContact: _primaryContact,
      ));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
      // Reload to restore state
      await loadContacts();
    }
  }

  // Remove primary contact
  Future<void> removePrimaryContact() async {
    if (_userId == null) return;

    try {
      await _contactService.setPrimaryContact(_userId!, null);
      _primaryContactId = null;
      _primaryContact = null;

      // Emit loaded state directly
      emit(EmergencyContactsLoaded(
        contacts: _contacts,
        primaryContactId: null,
        primaryContact: null,
      ));
    } catch (e) {
      emit(EmergencyContactsError(message: e.toString()));
      await loadContacts();
    }
  }

  // Call emergency number (123)
  Future<void> callEmergency() async {
    const emergencyNumber = 'tel:123';
    try {
      if (await canLaunchUrl(Uri.parse(emergencyNumber))) {
        await launchUrl(Uri.parse(emergencyNumber));
      }
    } catch (e) {
      emit(const EmergencyContactsError(message: 'Cannot make call'));
    }
  }

  // Call primary contact
  Future<void> callPrimaryContact() async {
    if (_primaryContact == null) {
      emit(
          const EmergencyContactsError(message: 'emergency.set_primary_first'));
      // Restore loaded state
      emit(EmergencyContactsLoaded(
        contacts: _contacts,
        primaryContactId: _primaryContactId,
        primaryContact: _primaryContact,
      ));
      return;
    }

    try {
      final phoneUrl = 'tel:${_primaryContact!.phone}';
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(Uri.parse(phoneUrl));
      }
    } catch (e) {
      emit(const EmergencyContactsError(message: 'Cannot make call'));
    }
  }

  // Call specific contact
  Future<void> callContact(EmergencyContactModel contact) async {
    try {
      final phoneUrl = 'tel:${contact.phone}';
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(Uri.parse(phoneUrl));
      }
    } catch (e) {
      emit(const EmergencyContactsError(message: 'Cannot make call'));
    }
  }

  // Check if contact is primary
  bool isPrimaryContact(String contactId) {
    return _primaryContactId == contactId;
  }
}
