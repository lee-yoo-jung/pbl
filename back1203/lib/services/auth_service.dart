import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      data: {
        'user_id': userid,   // DB 트리거가 사용할 'user_id'
        'nickname': nickname, // DB 트리거가 사용할 'nickname'
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
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // 구글 로그인이 아닌 경우 무시
    }

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

  // 카카오 로그인
  Future<AuthResponse?> signInWithKakao() async {
    try {
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      kakao.OAuthToken token;

      if (isInstalled) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          if (e is PlatformException && e.code == 'CANCELED') {
            return null;
          }
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final providerToken = token.idToken ?? token.accessToken;

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

      const webClientId = '186928372389-femvfkn38c48r2gi6o963tn8c3ee6aak.apps.googleusercontent.com'; // [필수] 본인의 웹 클라이언트 ID로 교체하세요!

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // 사용자가 취소한 경우

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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