import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';

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
    );

    if (response.user != null) {
      await supabase.from('users').insert({
        'uuid': response.user!.id,   // Auth에서 받은 UUID
        'id': userid,                    // 사용자 입력 id
        'email': email,
        'nickname': nickname,
        'exp': 0,
        'tier': 'Bronze',
        'created_at': DateTime.now(),
      });
    }

    return response;
  }

  // 일반 로그인
  Future<AuthResponse> loginUser({
    required String userid,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: userid,
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

  // 중복확인
  Future<bool> isIdTaken(String id) async {
    final response =
    await supabase.from('users').select('id').eq('id', id);
    return response.isNotEmpty;
  }

  Future<bool> isEmailTaken(String email) async {
    final response =
    await supabase.from('users').select('email').eq('email', email);
    return response.isNotEmpty;
  }

  // 카카오 로그인
  Future<AuthResponse?> signInWithKakao() async {
    try {
      kakao.OAuthToken token = await kakao.UserApi.instance.loginWithKakaoTalk();
      final providerToken = token.accessToken;

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: providerToken,
      );
      return response;
    } catch (e) {
      debugPrint('카카오 로그인 실패: $e');
      return null;
    }
  }

  // 구글 로그인
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // 취소한 경우

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      return response;
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      return null;
    }
  }
}
