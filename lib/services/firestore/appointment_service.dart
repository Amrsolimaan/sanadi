import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/doctors/model/appointment_model.dart';
import '../../features/doctors/model/doctor_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/appointments
  CollectionReference _getCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('appointments');
  }

  // ============================================
  // Create appointment
  // ============================================
  Future<AppointmentModel> createAppointment({
    required String visitorId,
    required DoctorModel doctor,
    required String date,
    required String time,
    String? notes,
    String? patientName,
    String? patientPhone,
  }) async {
    try {
      // Create a reference to generate a unique ID
      final appointmentRef = _getCollection(visitorId).doc();
      final appointmentId = appointmentRef.id;

      final appointment = AppointmentModel(
        id: appointmentId,
        visitorId: visitorId,
        patientName: patientName,
        patientPhone: patientPhone,
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorImage: doctor.imageUrl, // ✅ Save Doctor Image
        specialty: doctor.specialty,
        date: date,
        time: time,
        status: AppointmentStatus.upcoming,
        createdAt: DateTime.now(),
        notes: notes,
      );

      final appointmentMap = appointment.toMap();

      // Batch write to ensure atomicity
      final batch = _firestore.batch();

      // 1. Save to user's appointments: users/{userId}/appointments/{appointmentId}
      batch.set(appointmentRef, appointmentMap);

      // 2. Save to doctor's appointments: doctor/{doctorId}/appointments/{appointmentId}
      final doctorAppointmentRef = _firestore
          .collection('doctor')
          .doc(doctor.id)
          .collection('appointments')
          .doc(appointmentId);
      
      batch.set(doctorAppointmentRef, appointmentMap);

      await batch.commit();

      return appointment;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // ============================================
  // Get user appointments
  // ============================================
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    try {
      final snapshot =
          await _getCollection(userId).orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  // ============================================
  // Get appointments by date
  // ============================================
  Future<List<AppointmentModel>> getAppointmentsByDate(
      String userId, String date) async {
    try {
      final snapshot =
          await _getCollection(userId).where('date', isEqualTo: date).get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // ترتيب حسب الوقت في الكود
      appointments.sort((a, b) => a.time.compareTo(b.time));

      return appointments;
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  // ============================================
  // Get appointments by status
  // ============================================
  Future<List<AppointmentModel>> getAppointmentsByStatus(
      String userId, AppointmentStatus status) async {
    try {
      final snapshot = await _getCollection(userId)
          .where('status', isEqualTo: status.name)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // ترتيب حسب التاريخ في الكود
      appointments.sort((a, b) => b.date.compareTo(a.date));

      return appointments;
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  // ============================================
  // Get appointments by date and status
  // الحل: جلب البيانات بدون orderBy ثم الفلترة والترتيب في الكود
  // ============================================
  Future<List<AppointmentModel>> getAppointmentsByDateAndStatus(
      String userId, String date, AppointmentStatus status) async {
    try {
      // جلب جميع حجوزات المستخدم
      final snapshot = await _getCollection(userId).get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // فلترة في الكود بدلاً من Firestore
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .where((appointment) =>
              appointment.date == date && appointment.status == status)
          .toList();

      // ترتيب حسب الوقت
      appointments.sort((a, b) => a.time.compareTo(b.time));

      return appointments;
    } on FirebaseException catch (e) {
      // معالجة أخطاء Firebase بشكل أفضل
      if (e.code == 'failed-precondition' || e.code == 'permission-denied') {
        throw Exception('Unable to load appointments. Please try again later.');
      }
      throw Exception('Connection error. Please check your internet.');
    } catch (e) {
      throw Exception('Failed to load appointments. Please try again.');
    }
  }

  // ============================================
  // Cancel appointment
  // ============================================
  Future<void> cancelAppointment(String userId, String appointmentId) async {
    try {
      await _getCollection(userId).doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // ============================================
  // Check if slot is booked
  // ============================================
  Future<bool> isSlotBooked({
    required String doctorId,
    required String date,
    required String time,
  }) async {
    try {
      // Check across all users' appointments
      final snapshot = await _firestore
          .collectionGroup('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .where('status', isEqualTo: AppointmentStatus.upcoming.name)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // If error, assume not booked to allow user to proceed
      print('Error checking slot: $e');
      return false;
    }
  }

  // ============================================
  // Get booked slots for a doctor on a date
  // ============================================
  Future<List<String>> getBookedSlots(String doctorId, String date) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: AppointmentStatus.upcoming.name)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['time'] as String? ?? '';
          })
          .where((time) => time.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting booked slots: $e');
      return [];
    }
  }

  // ============================================
  // Update old appointments to completed
  // ============================================
  Future<void> updateOldAppointments(String userId) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // جلب جميع الحجوزات القادمة
      final snapshot = await _getCollection(userId)
          .where('status', isEqualTo: AppointmentStatus.upcoming.name)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final appointmentDate = data['date'] as String? ?? '';

        // التحقق من أن التاريخ قديم
        if (appointmentDate.isNotEmpty &&
            appointmentDate.compareTo(todayStr) < 0) {
          batch.update(
              doc.reference, {'status': AppointmentStatus.completed.name});
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // نتجاهل الأخطاء في هذه العملية الخلفية
      print('Failed to update old appointments: $e');
    }
  }
}
