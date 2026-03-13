import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/emergency/model/emergency_contact_model.dart';

class EmergencyContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get collection reference
  CollectionReference<Map<String, dynamic>> _getContactsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts');
  }

  // Get user document reference
  DocumentReference<Map<String, dynamic>> _getUserRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Get all contacts
  Future<List<EmergencyContactModel>> getContacts(String userId) async {
    final snapshot = await _getContactsRef(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => EmergencyContactModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get single contact
  Future<EmergencyContactModel?> getContact(
      String userId, String contactId) async {
    final doc = await _getContactsRef(userId).doc(contactId).get();

    if (doc.exists) {
      return EmergencyContactModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Add contact
  Future<EmergencyContactModel> addContact(
    String userId,
    EmergencyContactModel contact,
  ) async {
    final docRef = await _getContactsRef(userId).add(contact.toMap());
    return contact.copyWith(id: docRef.id);
  }

  // Update contact
  Future<void> updateContact(
    String userId,
    EmergencyContactModel contact,
  ) async {
    await _getContactsRef(userId).doc(contact.id).update({
      'name': contact.name,
      'phone': contact.phone,
      'relationship': contact.relationship,
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete contact
  Future<void> deleteContact(String userId, String contactId) async {
    await _getContactsRef(userId).doc(contactId).delete();
  }

  // Set primary contact
  Future<void> setPrimaryContact(String userId, String? contactId) async {
    await _getUserRef(userId).set({
      'primaryContactId': contactId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Get primary contact ID
  Future<String?> getPrimaryContactId(String userId) async {
    final userDoc = await _getUserRef(userId).get();

    if (!userDoc.exists) {
      return null;
    }

    return userDoc.data()?['primaryContactId'];
  }

  // Get primary contact
  Future<EmergencyContactModel?> getPrimaryContact(String userId) async {
    final primaryContactId = await getPrimaryContactId(userId);

    if (primaryContactId != null && primaryContactId.isNotEmpty) {
      return getContact(userId, primaryContactId);
    }
    return null;
  }

  // Stream contacts
  Stream<List<EmergencyContactModel>> streamContacts(String userId) {
    return _getContactsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContactModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
