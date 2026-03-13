# 💻 أمثلة الكود المهمة للمناقشة

## 1. BLoC Pattern - مثال كامل

### Medication Cubit (مثال على State Management)

```dart
// ============================================
// State Definitions
// ============================================
abstract class MedicationState {}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<MedicationModel> medications;
  final List<MedicationModel> todayMedications;
  final double complianceRate;
  
  MedicationLoaded({
    required this.medications,
    required this.todayMedications,
    required this.complianceRate,
  });
}

class MedicationError extends MedicationState {
  final String message;
  MedicationError(this.message);
}

// ============================================
// Cubit Implementation
// ============================================
class MedicationCubit extends Cubit<MedicationState> {
  final MedicationService _service = MedicationService();
  
  MedicationCubit() : super(MedicationInitial());
  
  // Load all medications
  Future<void> loadMedications() async {
    emit(MedicationLoading());
    try {
      final medications = await _service.getMedications();
      final todayMeds = await _service.getTodayMedications();
      final compliance = await _service.getComplianceRate(days: 7);
      
      emit(MedicationLoaded(
        medications: medications,
        todayMedications: todayMeds,
        complianceRate: compliance,
      ));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
  
  // Add new medication
  Future<void> addMedication(MedicationModel medication) async {
    try {
      await _service.addMedication(medication);
      await loadMedications(); // Reload data
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
}
```

### استخدام Cubit في UI:

```dart
class MedicationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationCubit, MedicationState>(
      builder: (context, state) {
        // Loading state
        if (state is MedicationLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        // Error state
        if (state is MedicationError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        
        // Loaded state
        if (state is MedicationLoaded) {
          return ListView.builder(
            itemCount: state.medications.length,
            itemBuilder: (context, index) {
              final med = state.medications[index];
              return MedicationCard(medication: med);
            },
          );
        }
        
        // Initial state
        return Center(child: Text('No medications'));
      },
    );
  }
}
```

---

## 2. Firebase Service - مثال على CRUD Operations

```dart
class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ============================================
  // Helper: Get User ID
  // ============================================
  Future<String> _getValidUserId() async {
    var user = _auth.currentUser;
    
    if (user != null) {
      return user.uid;
    }
    
    // Wait for auth state if not ready
    user = await _auth
        .authStateChanges()
        .where((user) => user != null)
        .first
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Auth timeout'),
        );
    
    if (user != null) {
      return user.uid;
    }
    
    throw Exception('User not authenticated');
  }
  
  // ============================================
  // Helper: Get Collection Reference
  // ============================================
  CollectionReference _getMedicationsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications');
  }
  
  // ============================================
  // CREATE
  // ============================================
  Future<String> addMedication(MedicationModel medication) async {
    final userId = await _getValidUserId();
    
    final data = medication.toFirestore();
    data['visitorId'] = userId;
    data['createdAt'] = FieldValue.serverTimestamp();
    
    final doc = await _getMedicationsCollection(userId).add(data);
    return doc.id;
  }
  
  // ============================================
  // READ
  // ============================================
  Future<List<MedicationModel>> getMedications() async {
    try {
      final userId = await _getValidUserId();
      
      final snapshot = await _getMedicationsCollection(userId).get();
      
      final medications = snapshot.docs
          .map((doc) => MedicationModel.fromFirestore(doc))
          .where((med) => med.isActive)
          .toList();
      
      // Sort by creation date (newest first)
      medications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return medications;
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }
  
  // ============================================
  // UPDATE
  // ============================================
  Future<void> updateMedication(String id, MedicationModel medication) async {
    final userId = await _getValidUserId();
    
    await _getMedicationsCollection(userId)
        .doc(id)
        .update(medication.toFirestore());
  }
  
  // ============================================
  // DELETE (Soft Delete)
  // ============================================
  Future<void> deleteMedication(String id) async {
    final userId = await _getValidUserId();
    
    await _getMedicationsCollection(userId)
        .doc(id)
        .update({'isActive': false});
  }
  
  // ============================================
  // Business Logic: Get Today's Medications
  // ============================================
  Future<List<MedicationModel>> getTodayMedications() async {
    final medications = await getMedications();
    return medications.where((med) => med.shouldTakeToday()).toList();
  }
  
  // ============================================
  // Business Logic: Calculate Compliance Rate
  // ============================================
  Future<double> getComplianceRate({int days = 7}) async {
    try {
      final userId = await _getValidUserId();
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final logs = await _getLogsForDateRange(startDate, now);
      
      if (logs.isEmpty) return 0;
      
      final takenCount = logs
          .where((l) => l.status == MedicationLogStatus.taken)
          .length;
      
      return takenCount / logs.length;
    } catch (e) {
      return 0;
    }
  }
}
```

---

## 3. Data Models - مثال على Model Structure

```dart
class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency; // daily, weekly, monthly
  final List<String> times; // ["08:00", "14:00", "20:00"]
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;
  
  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.notes,
  });
  
  // ============================================
  // From Firestore
  // ============================================
  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MedicationModel(
      id: doc.id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? 'daily',
      times: List<String>.from(data['times'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
    );
  }
  
  // ============================================
  // To Firestore
  // ============================================
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }
  
  // ============================================
  // Business Logic: Should Take Today?
  // ============================================
  bool shouldTakeToday() {
    final now = DateTime.now();
    
    // Check if medication is active
    if (!isActive) return false;
    
    // Check if before start date
    if (now.isBefore(startDate)) return false;
    
    // Check if after end date
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    // Check frequency
    switch (frequency) {
      case 'daily':
        return true;
      case 'weekly':
        return now.weekday == startDate.weekday;
      case 'monthly':
        return now.day == startDate.day;
      default:
        return false;
    }
  }
  
  // ============================================
  // Copy With (for updates)
  // ============================================
  MedicationModel copyWith({
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
  }) {
    return MedicationModel(
      id: this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
```

---

## 4. Alarm Service - مثال على Background Tasks

```dart
class AlarmService {
  static const String _channelId = 'medication_alarms';
  static const String _channelName = 'Medication Reminders';
  
  // ============================================
  // Initialize
  // ============================================
  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await FlutterLocalNotificationsPlugin().initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Request permissions
    await _requestPermissions();
  }
  
  // ============================================
  // Schedule Alarm
  // ============================================
  static Future<void> scheduleAlarm({
    required String medicationId,
    required String medicationName,
    required String time, // "08:00"
    required String dosage,
  }) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Generate unique ID
    final alarmId = _generateAlarmId(medicationId, time);
    
    // Schedule notification
    await FlutterLocalNotificationsPlugin().zonedSchedule(
      alarmId,
      'وقت تناول الدواء',
      '$medicationName - $dosage',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'alarm.aiff',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: jsonEncode({
        'medicationId': medicationId,
        'medicationName': medicationName,
        'time': time,
      }),
    );
    
    // Also schedule with Android Alarm Manager (more reliable)
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      alarmId,
      _alarmCallback,
      startAt: scheduledDate,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
  
  // ============================================
  // Cancel Alarm
  // ============================================
  static Future<void> cancelAlarm(String medicationId, String time) async {
    final alarmId = _generateAlarmId(medicationId, time);
    
    await FlutterLocalNotificationsPlugin().cancel(alarmId);
    await AndroidAlarmManager.cancel(alarmId);
  }
  
  // ============================================
  // Cancel All Alarms for Medication
  // ============================================
  static Future<void> cancelAllAlarmsForMedication(
    String medicationId,
    List<String> times,
  ) async {
    for (final time in times) {
      await cancelAlarm(medicationId, time);
    }
  }
  
  // ============================================
  // Helpers
  // ============================================
  static int _generateAlarmId(String medicationId, String time) {
    return '${medicationId}_$time'.hashCode;
  }
  
  static Future<void> _alarmCallback() async {
    // This runs in background
    print('Alarm triggered!');
  }
  
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      // Navigate to medication details
      // Or show take/skip dialog
    }
  }
  
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
}
```

---

## 5. Localization - مثال على Multilingual Support

### Translation Files:

**en.json:**
```json
{
  "home": {
    "welcome": "Welcome",
    "search": "Search for doctors, services...",
    "popular": "Popular Doctors",
    "see_all": "See All"
  },
  "medications": {
    "title": "My Medications",
    "add": "Add Medication",
    "name": "Medication Name",
    "dosage": "Dosage",
    "frequency": "Frequency",
    "daily": "Daily",
    "weekly": "Weekly",
    "monthly": "Monthly"
  }
}
```

**ar.json:**
```json
{
  "home": {
    "welcome": "مرحباً",
    "search": "ابحث عن أطباء، خدمات...",
    "popular": "الأطباء الأكثر شعبية",
    "see_all": "عرض الكل"
  },
  "medications": {
    "title": "أدويتي",
    "add": "إضافة دواء",
    "name": "اسم الدواء",
    "dosage": "الجرعة",
    "frequency": "التكرار",
    "daily": "يومي",
    "weekly": "أسبوعي",
    "monthly": "شهري"
  }
}
```

### Usage in Code:

```dart
// Simple translation
Text('home.welcome'.tr())

// With parameters
Text('medications.take_at'.tr(args: ['08:00']))

// Plural
Text('medications.count'.plural(medicationCount))

// Change language
context.setLocale(Locale('ar'))

// Get current language
final lang = context.locale.languageCode
```

### Language Cubit:

```dart
class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageState(locale: const Locale('en')));
  
  Future<void> changeLanguage(Locale locale) async {
    emit(LanguageState(locale: locale));
    await _saveLanguagePreference(locale.languageCode);
  }
  
  Future<void> _saveLanguagePreference(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }
  
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    emit(LanguageState(locale: Locale(langCode)));
  }
}
```

---

## 6. Permission Handling - مثال على Runtime Permissions

```dart
class PermissionHelper {
  // ============================================
  // Check Permission Status
  // ============================================
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }
  
  // ============================================
  // Request Permission
  // ============================================
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }
  
  // ============================================
  // Location Permission
  // ============================================
  static Future<bool> requestLocationPermission() async {
    // Check if already granted
    if (await Permission.location.isGranted) {
      return true;
    }
    
    // Request permission
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  // ============================================
  // Background Location Permission
  // ============================================
  static Future<bool> requestBackgroundLocationPermission() async {
    // First, ensure foreground location is granted
    if (!await Permission.location.isGranted) {
      final granted = await requestLocationPermission();
      if (!granted) return false;
    }
    
    // Then request background location
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }
  
  // ============================================
  // Notification Permission (Android 13+)
  // ============================================
  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }
    return true; // Not needed for older Android or iOS
  }
  
  // ============================================
  // Photos Permission
  // ============================================
  static Future<bool> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses READ_MEDIA_IMAGES
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // Older Android uses READ_EXTERNAL_STORAGE
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
  }
  
  // ============================================
  // Check All Required Permissions
  // ============================================
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'backgroundLocation': await Permission.locationAlways.isGranted,
      'notification': await Permission.notification.isGranted,
      'photos': await Permission.photos.isGranted,
    };
  }
}
```

---

## 7. Image Upload - مثال على Supabase Storage

```dart
class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'profile-images';
  
  // ============================================
  // Upload Image
  // ============================================
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // 1. Compress image first
      final compressedFile = await _compressImage(imageFile);
      
      // 2. Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '$userId\_$timestamp$extension';
      
      // 3. Upload to Supabase
      final uploadPath = 'users/$userId/$fileName';
      
      await _supabase.storage
          .from(_bucketName)
          .upload(uploadPath, compressedFile);
      
      // 4. Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(uploadPath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // ============================================
  // Delete Image
  // ============================================
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.skip(4).join('/');
      
      await _supabase.storage
          .from(_bucketName)
          .remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
  
  // ============================================
  // Compress Image
  // ============================================
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${path.basename(file.path)}';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );
    
    return File(result!.path);
  }
}
```

---

## 8. Responsive Design - مثال على Adaptive UI

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        }
        // Tablet
        else if (constraints.maxWidth >= 800) {
          return tablet ?? mobile;
        }
        // Mobile
        else {
          return mobile;
        }
      },
    );
  }
}

// Usage:
ResponsiveLayout(
  mobile: MobileHomeScreen(),
  tablet: TabletHomeScreen(),
  desktop: DesktopHomeScreen(),
)
```

---

## 9. Error Handling - مثال على Centralized Error Handling

```dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error.code);
    } else if (error is TimeoutException) {
      return 'Connection timeout. Please try again.';
    } else {
      return 'An unexpected error occurred.';
    }
  }
  
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication error: $code';
    }
  }
  
  static String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data.';
      case 'not-found':
        return 'Requested data not found.';
      case 'already-exists':
        return 'This data already exists.';
      default:
        return 'Database error: $code';
    }
  }
}
```

---

## 10. Navigation - مثال على Screen Transitions

```dart
// Smooth page transition
void _navigateWithTransition(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

// Replace screen (no back button)
void _navigateAndReplace(BuildContext context, Widget screen) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}

// Clear stack and navigate
void _navigateAndClearStack(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}
```

---

هذه الأمثلة تغطي أهم الأنماط البرمجية المستخدمة في المشروع. استخدمها للإجابة على الأسئلة التقنية! 🚀
