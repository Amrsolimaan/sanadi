import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/services/firestore/image_compressor_service.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import 'package:sanadi/services/firestore/user_service.dart';
import '../../auth/model/user_model.dart';
import '../../auth/viewmodel/auth_cubit.dart';

// ============================================
// Profile States
// ============================================

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final DateTime timestamp;

  ProfileLoaded(this.user) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) => false;

  @override
  int get hashCode => timestamp.hashCode;
}

class ProfileImageUploading extends ProfileState {}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  final DateTime timestamp;

  ProfileImageUploaded(this.imageUrl) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) => false;

  @override
  int get hashCode => timestamp.hashCode;
}

// ✅ State جديد لحذف الصورة - يحمل URL الصورة المحذوفة لمسح الـ cache
class ProfileImageDeleted extends ProfileState {
  final String? deletedImageUrl;
  final String message;
  final DateTime timestamp;

  ProfileImageDeleted({this.deletedImageUrl, required this.message})
      : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) => false;

  @override
  int get hashCode => timestamp.hashCode;
}

class ProfileUpdated extends ProfileState {
  final String message;
  final DateTime timestamp;

  ProfileUpdated(this.message) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) => false;

  @override
  int get hashCode => timestamp.hashCode;
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class PasswordChanging extends ProfileState {}

class PasswordChanged extends ProfileState {}

// ============================================
// Profile Cubit
// ============================================

class ProfileCubit extends Cubit<ProfileState> {
  final UserService _userService;
  final FirebaseAuth _auth;
  final ImagePicker _imagePicker;
  final AuthCubit? _authCubit;

  ProfileCubit({
    required UserService userService,
    required FirebaseAuth auth,
    AuthCubit? authCubit,
  })  : _userService = userService,
        _auth = auth,
        _authCubit = authCubit,
        _imagePicker = ImagePicker(),
        super(ProfileInitial());

  /// تحميل بيانات المستخدم الحالي
  Future<void> loadUserProfile() async {
    try {
      emit(ProfileLoading());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      final user = await _userService.getUser(currentUser.uid);
      if (user == null) {
        emit(ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError('خطأ في تحميل البيانات: ${e.toString()}'));
    }
  }

  /// ✅ تحديث اسم المستخدم
  Future<void> updateUserName(String newName) async {
    try {
      emit(ProfileLoading());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      final user = await _userService.getUser(currentUser.uid);
      if (user == null) {
        emit(ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      final updatedUser = user.copyWith(
        fullName: newName,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUser(updatedUser);
      await _authCubit?.refreshUserData();

      emit(ProfileUpdated('تم تحديث الاسم بنجاح'));
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError('فشل تحديث الاسم: ${e.toString()}'));
      await loadUserProfile();
    }
  }

  /// ✅ تحديث رقم الهاتف
  Future<void> updateUserPhone(String newPhone) async {
    try {
      emit(ProfileLoading());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      final user = await _userService.getUser(currentUser.uid);
      if (user == null) {
        emit(ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      final updatedUser = user.copyWith(
        phone: newPhone,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUser(updatedUser);
      await _authCubit?.refreshUserData();

      emit(ProfileUpdated('تم تحديث رقم الهاتف بنجاح'));
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError('فشل تحديث رقم الهاتف: ${e.toString()}'));
      await loadUserProfile();
    }
  }

  /// اختيار وتحميل صورة البروفايل من المعرض
  Future<void> pickAndUploadImage(ImageSource source) async {
    try {
      emit(ProfileImageUploading());

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        await loadUserProfile();
        return;
      }

      final imageFile = File(pickedFile.path);

      // Check file size
      if (ImageCompressorService.isFileSizeExceeded(imageFile,
          maxSizeMB: 5.0)) {
        emit(ProfileError('حجم الصورة كبير جداً (الحد الأقصى 5 ميجابايت)'));
        await loadUserProfile();
        return;
      }

      // Compress image
      final compressedImage = await ImageCompressorService.compressImage(
        imageFile: imageFile,
        quality: 85,
      );

      if (compressedImage == null) {
        emit(ProfileError('فشل ضغط الصورة'));
        await loadUserProfile();
        return;
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      // Upload to Supabase
      final imageUrl = await SupabaseStorageService.uploadProfileImage(
        userId: currentUser.uid,
        imageFile: compressedImage,
      );

      // Get current user data
      final user = await _userService.getUser(currentUser.uid);
      if (user == null) {
        emit(ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      // ✅ حفظ URL الصورة القديمة لمسح الـ cache
      final oldImageUrl = user.profileImage;

      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          // ✅ مسح cache الصورة القديمة
          await CachedNetworkImage.evictFromCache(oldImageUrl);
          final baseUrl = oldImageUrl.split('?').first;
          await CachedNetworkImage.evictFromCache(baseUrl);

          await SupabaseStorageService.deleteProfileImage(oldImageUrl);
        } catch (e) {
          print('تحذير: فشل حذف الصورة القديمة');
        }
      }

      // Update user data in Firebase - ✅ تحديث الصورة فقط لتجنب مشاكل الـ Role
      await _userService.updateSpecificFields(user.uid, {
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث AuthCubit لتحديث الصورة في كل التطبيق
      await _authCubit?.refreshUserData();

      // إرسال الـ state الجديد
      emit(ProfileImageUploaded(imageUrl));

      // انتظار قصير ثم تحميل البروفايل
      await Future.delayed(const Duration(milliseconds: 100));
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError('فشل رفع الصورة: ${e.toString()}'));
      await loadUserProfile();
    }
  }

  /// حذف صورة البروفايل
  Future<void> removeProfileImage() async {
    try {
      emit(ProfileImageUploading());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      final user = await _userService.getUser(currentUser.uid);
      if (user == null) {
        emit(ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      // ✅ حفظ URL الصورة قبل الحذف لمسح الـ cache
      final deletedImageUrl = user.profileImage;

      // ✅ مسح cache الصورة أولاً
      if (deletedImageUrl != null && deletedImageUrl.isNotEmpty) {
        try {
          await CachedNetworkImage.evictFromCache(deletedImageUrl);
          final baseUrl = deletedImageUrl.split('?').first;
          await CachedNetworkImage.evictFromCache(baseUrl);
        } catch (e) {
          print('تحذير: فشل مسح cache الصورة');
        }

        // Delete from Supabase
        try {
          await SupabaseStorageService.deleteProfileImage(deletedImageUrl);
        } catch (e) {
          print('تحذير: فشل حذف الصورة من Supabase');
        }
      }

      // Update Firebase - set profileImage to null
      // Update Firebase - set profileImage to null
      await _userService.updateSpecificFields(user.uid, {
        'profileImage': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث AuthCubit
      await _authCubit?.refreshUserData();

      // ✅ إرسال state جديد يحمل URL الصورة المحذوفة
      emit(ProfileImageDeleted(
        deletedImageUrl: deletedImageUrl,
        message: 'تم حذف الصورة بنجاح',
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError('فشل حذف الصورة: ${e.toString()}'));
      await loadUserProfile();
    }
  }

  /// تغيير كلمة المرور (للمستخدمين المسجلين بالإيميل فقط)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      emit(PasswordChanging());

      final user = _auth.currentUser;
      if (user == null) {
        emit(ProfileError('لم يتم تسجيل الدخول'));
        return;
      }

      // Check if user is signed in with email/password
      final isEmailProvider = user.providerData.any(
        (info) => info.providerId == 'password',
      );

      if (!isEmailProvider) {
        emit(ProfileError(
          'تغيير كلمة المرور غير متاح لحسابات التسجيل الاجتماعي',
        ));
        await loadUserProfile();
        return;
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      emit(PasswordChanged());
      await loadUserProfile();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'فشل تغيير كلمة المرور';

      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'كلمة المرور الحالية غير صحيحة';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور الجديدة ضعيفة جداً';
          break;
        case 'requires-recent-login':
          errorMessage = 'يرجى تسجيل الدخول مرة أخرى';
          break;
        default:
          errorMessage = 'خطأ: ${e.message}';
      }

      emit(ProfileError(errorMessage));
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError('خطأ: ${e.toString()}'));
      await loadUserProfile();
    }
  }

  /// التحقق من نوع التسجيل (إيميل أم Social)
  bool isEmailPasswordUser() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// الحصول على صورة المستخدم (من Firebase أو من Google/Facebook)
  String? getUserPhotoUrl() {
    final user = _auth.currentUser;
    if (user == null) return null;

    // أولاً: تحقق من الصورة المخزنة في Firebase
    if (state is ProfileLoaded) {
      final loadedUser = (state as ProfileLoaded).user;
      if (loadedUser.profileImage != null &&
          loadedUser.profileImage!.isNotEmpty) {
        return loadedUser.profileImage;
      }
    }

    // ثانياً: إذا لم توجد، استخدم صورة Google/Facebook
    return user.photoURL;
  }

  /// ✅ إعادة تعيين الـ Cubit للحالة الأولية
  /// يُستخدم عند تسجيل الخروج لتنظيف البيانات القديمة
  void reset() {
    emit(ProfileInitial());
  }
}
