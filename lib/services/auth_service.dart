import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // 일반 회원가입
  Future<AuthResponse> signUpUser({
    required String userid,
    required String password,
    required String nickname,
    required String email,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'user_id': userid,
        'nickname': nickname,
      },
    );

    return response;
  }

  // 일반 로그인
  Future<AuthResponse> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // 로그아웃
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // 현재 로그인된 사용자
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // ID 중복확인
  Future<bool> isIdTaken(String userid) async {
    final response = await supabase
        .from('users')
        .select('user_id')
        .eq('user_id', userid);

    return response.isNotEmpty;
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://reset-callback/',
      );
    } catch (e) {
      debugPrint('비밀번호 재설정 이메일 전송 실패: $e');
      rethrow;
    }
  }

  // 새 비밀번호로 업데이트
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return response;
    } catch (e) {
      debugPrint('비밀번호 업데이트 실패: $e');
      rethrow;
    }
  }
}