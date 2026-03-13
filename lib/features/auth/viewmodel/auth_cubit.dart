import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanadi/features/auth/model/user_model.dart';
import 'package:sanadi/features/auth/viewmodel/auth_state.dart';
import 'package:sanadi/services/auth/auth_service.dart';
import 'package:sanadi/services/firestore/user_service.dart';
import 'package:sanadi/services/firestore/persistent_alarm_service.dart';
import 'package:sanadi/core/config/remote_config_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthState() async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        try {
          final userModel = await _getUserFromFirestore(user.uid);
          if (userModel != null) {
            emit(AuthSuccess(user: userModel));
          } else {
            print(' User found in Auth but not in Firestore');
            await _authService.signOut();
            emit(AuthInitial());
          }
        } catch (e) {
          print(' Error fetching user data in checkAuthState: $e');
          emit(AuthInitial());
        }
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      print(' Critical Error in checkAuthState: $e');
      emit(AuthInitial());
    }
  }

  // ============================================
  //  LOGIN - تحديث كامل مع معالجة الأخطاء
  // ============================================
  Future<void> loginWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      print('🔵 Starting login for: $email');

      // 1️⃣ تسجيل الدخول أولاً
      final credential = await _authService.signInWithEmail(
        email.trim().toLowerCase(),
        password,
      );

      if (credential.user == null) {
        print(' No user returned from Firebase Auth');
        emit(const AuthError(message: 'errors.invalid_credentials'));
        return;
      }

      final firebaseUser = credential.user!;
      print(' Firebase Auth successful for UID: ${firebaseUser.uid}');

      //  الحصول على بيانات المستخدم من Firestore
      UserModel? userModel = await _getUserFromFirestore(firebaseUser.uid);

      //  إذا لم يكن موجوداً في Firestore، أنشئه
      if (userModel == null) {
        print(' User not found in Firestore, creating new document');
        userModel = await _createUserInFirestore(firebaseUser);
      } else {
        print(' User found in Firestore with role: ${userModel.role.value}');

        // تحديث آخر تسجيل دخول
        await _updateLastLogin(firebaseUser.uid);
      }

      // 4️⃣ التحقق من حالة المستخدم
      if (!userModel.isActive) {
        print(' User account is inactive');
        await _authService.signOut();
        emit(const AuthError(message: 'errors.account_disabled'));
        return;
      }

      print(' Login successful! Emitting AuthSuccess');
      emit(AuthSuccess(user: userModel));

      // 5️⃣ إعادة جدولة المنبهات بعد تسجيل الدخول
      _rescheduleAlarmsAfterLogin(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      print(' FirebaseAuthException: ${e.code} - ${e.message}');
      await _authService.signOut();
      emit(AuthError(message: _getFirebaseAuthError(e.code)));
    } catch (e) {
      print(' General Error in loginWithEmail: $e');
      await _authService.signOut();
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  //  إنشاء مستخدم في Firestore
  // ============================================
  Future<UserModel> _createUserInFirestore(User firebaseUser) async {
    try {
      final email = firebaseUser.email?.trim().toLowerCase() ?? '';
      final isSuperAdmin =
          RemoteConfigService.instance.isSuperAdminEmail(email);

      final userModel = UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'User',
        email: email,
        phone: firebaseUser.phoneNumber ?? '',
        profileImage: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: isSuperAdmin ? UserRole.superAdmin : UserRole.user,
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toMap());

      print(' User document created in Firestore');
      return userModel;
    } catch (e) {
      print(' Error creating user in Firestore: $e');
      rethrow;
    }
  }

  // ============================================
  //  تحديث آخر تسجيل دخول
  // ============================================
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(' Error updating last login: $e');
      // لا نريد إيقاف تسجيل الدخول بسبب هذا الخطأ
    }
  }

  // ============================================
  //  REGISTER - تحديث كامل
  // ============================================
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    // UserRole? role, // تم الحذف - الدور الافتراضي user
  }) async {
    await signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      // role: role ?? UserRole.user, // تم الحذف
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    // UserRole? role, // تم الحذف - الدور الافتراضي user
  }) async {
    emit(AuthLoading());
    try {
      print('🔵 Starting sign up for: $email');

      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPhone = phone.trim();

      //  1️⃣ التحقق من رقم الهاتف أولاً
      final isPhoneRegistered =
          await _userService.isPhoneNumberRegistered(normalizedPhone);
      if (isPhoneRegistered) {
        print(' Phone number already registered: $normalizedPhone');
        emit(const AuthError(message: 'errors.phone_already_exists'));
        return;
      }

      //  التحقق من Super Admin
      if (RemoteConfigService.instance.isSuperAdminEmail(normalizedEmail)) {
        print(' Cannot register with Super Admin email');
        emit(const AuthError(message: 'errors.email_already_exists'));
        return;
      }

      // 1️⃣ إنشاء حساب في Firebase Auth
      final credential = await _authService.signUpWithEmail(
        normalizedEmail,
        password,
      );

      if (credential.user == null) {
        emit(const AuthError(message: 'errors.something_went_wrong'));
        return;
      }

      print(' Firebase Auth account created: ${credential.user!.uid}');

      //  إنشاء مستند المستخدم في Firestore
      print('🔵 Creating UserModel...');
      final userModel = UserModel(
        uid: credential.user!.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        phone: normalizedPhone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // role: role ?? UserRole.user, // تم الحذف - الدور الافتراضي user
        isActive: true,
      );

      print(
          '🔵 UserModel created successfully with role: ${userModel.role.value}');
      print('🔵 Saving to Firestore...');

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      print(' User document created with role: ${userModel.role.value}');

      // تسجيل الخروج بعد التسجيل الناجح
      await _authService.signOut();

      emit(AuthSuccess(user: userModel));
    } on FirebaseAuthException catch (e) {
      print(' FirebaseAuthException in signUp: ${e.code} - ${e.message}');
      emit(AuthError(message: _getFirebaseAuthError(e.code)));
    } catch (e) {
      print(' General Error in signUpWithEmail: $e');
      print(' Error type: ${e.runtimeType}');
      print(' Stack trace: ${StackTrace.current}');
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  //  GOOGLE SIGN IN - تحديث
  // ============================================
  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      print('🔵 Starting Google Sign In');

      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null || userCredential.user == null) {
        print(' Google Sign In cancelled');
        emit(AuthInitial());
        return;
      }

      final firebaseUser = userCredential.user!;
      print(' Google Sign In successful: ${firebaseUser.uid}');

      UserModel? userModel = await _getUserFromFirestore(firebaseUser.uid);

      if (userModel == null) {
        userModel = await _createUserInFirestore(firebaseUser);
      } else {
        await _updateLastLogin(firebaseUser.uid);
      }

      if (!userModel.isActive) {
        await _authService.signOut();
        emit(const AuthError(message: 'errors.account_disabled'));
        return;
      }

      emit(AuthSuccess(user: userModel));
    } catch (e) {
      print(' Google Sign-In Error: $e');
      await _authService.signOut();
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  //  FACEBOOK SIGN IN - تحديث
  // ============================================
  Future<void> loginWithFacebook() async {
    emit(AuthLoading());
    try {
      print('🔵 Starting Facebook Sign In');

      final userCredential = await _authService.signInWithFacebook();

      if (userCredential == null || userCredential.user == null) {
        print(' Facebook Sign In cancelled');
        emit(AuthInitial());
        return;
      }

      final firebaseUser = userCredential.user!;
      print(' Facebook Sign In successful: ${firebaseUser.uid}');

      UserModel? userModel = await _getUserFromFirestore(firebaseUser.uid);

      if (userModel == null) {
        userModel = await _createUserInFirestore(firebaseUser);
      } else {
        await _updateLastLogin(firebaseUser.uid);
      }

      if (!userModel.isActive) {
        await _authService.signOut();
        emit(const AuthError(message: 'errors.account_disabled'));
        return;
      }

      emit(AuthSuccess(user: userModel));
    } catch (e) {
      print(' Facebook Sign-In Error: $e');
      await _authService.signOut();
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  // OTP Methods
  // ============================================
  Future<void> sendOtp(String phoneNumber) async {
    emit(AuthLoading());
    try {
      await _authService.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          emit(OtpSent(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
          ));
        },
        onError: (error) {
          emit(AuthError(message: error));
        },
      );
    } catch (e) {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  Future<void> verifyOtp({required String otp}) async {
    final currentState = state;
    if (currentState is OtpSent) {
      await _verifyOtpWithId(
        verificationId: currentState.verificationId,
        otp: otp,
      );
    } else {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  Future<void> _verifyOtpWithId({
    required String verificationId,
    required String otp,
  }) async {
    emit(AuthLoading());
    try {
      final credential = await _authService.verifyOtp(
        verificationId: verificationId,
        otp: otp,
      );

      if (credential.user != null) {
        emit(OtpVerified(verificationId: verificationId));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getFirebaseAuthError(e.code)));
    } catch (e) {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  // Password Methods
  // ============================================
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(email.trim().toLowerCase());
      emit(PasswordResetDone());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getFirebaseAuthError(e.code)));
    } catch (e) {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  Future<void> changePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await _authService.updatePassword(newPassword);
      emit(PasswordResetDone());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getFirebaseAuthError(e.code)));
    } catch (e) {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  // Logout
  // ============================================
  Future<void> logout() async {
    try {
      // إلغاء جميع المنبهات عند تسجيل الخروج
      print('🚪 Logging out - cancelling all alarms');
      await PersistentAlarmService.cancelAlarmsOnLogout();

      // تسجيل الخروج من Firebase
      await _authService.signOut();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(const AuthError(message: 'errors.something_went_wrong'));
    }
  }

  // ============================================
  // إعادة جدولة المنبهات بعد تسجيل الدخول
  // ============================================
  Future<void> _rescheduleAlarmsAfterLogin(String userId) async {
    try {
      print('🔔 Rescheduling alarms after login...');
      await PersistentAlarmService.scheduleAllAlarmsForUser(userId);
      print(' Alarms rescheduled successfully');
    } catch (e) {
      print(' Error rescheduling alarms: $e');
      // لا نريد إيقاف تسجيل الدخول بسبب هذا الخطأ
    }
  }

  // ============================================
  // Refresh User Data
  // ============================================
  Future<void> refreshUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _getUserFromFirestore(user.uid);
        if (userModel != null) {
          emit(AuthSuccess(user: userModel));
        } else {
          await logout();
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      print('🔍 Fetching user from Firestore: $uid');

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print(' User document not found');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print(' User document has no data');
        return null;
      }

      print(' User document found');
      return UserModel.fromMap(data);
    } catch (e) {
      print(' Error getting user from Firestore: $e');
      return null;
    }
  }

  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'errors.user_not_found';
      case 'wrong-password':
        return 'errors.invalid_credentials';
      case 'email-already-in-use':
        return 'errors.email_already_exists';
      case 'weak-password':
        return 'errors.weak_password';
      case 'invalid-email':
        return 'validation.invalid_email';
      case 'invalid-credential':
        return 'errors.invalid_credentials';
      case 'too-many-requests':
        return 'errors.too_many_requests';
      case 'network-request-failed':
        return 'errors.network_error';
      case 'invalid-verification-code':
        return 'validation.invalid_otp';
      case 'user-disabled':
        return 'errors.account_disabled';
      default:
        print(' Unhandled error code: $code');
        return 'errors.something_went_wrong';
    }
  }
}
