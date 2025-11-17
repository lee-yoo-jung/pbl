import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/services/auth_service.dart';
import 'package:pbl/screen/home_screen.dart';
import 'sign_up_page.dart';

// 앱의 최상위 위젯, 앱 전체의 기본 설정을 담당
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로그인 데모',
      theme: ThemeData( // 앱의 전체적인 테마 설정
        primarySwatch: Colors.blue, // 앱의 기본 색상 팔레트 파란색
        visualDensity: VisualDensity.adaptivePlatformDensity, // 플랫폼에 따라 UI 밀도 조절
      ),
      home: const LoginPage(), // 앱이 시작될 때 보여줄 첫 화면을 지정
    );
  }
}

// 상태를 가질 수 있는 위젯. 사용자 입력에 따라 UI가 변해야 하므로 사용
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState(); // 이 위젯의 상태를 관리할 객체를 생성
}

// LoginPage의 상태를 관리하는 클래스
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberMe();
    });
  }

  @override
  void dispose() {
    _emailController.dispose(); // 컨트롤러 이름 변경
    _passwordController.dispose();
    super.dispose();
  }

  void _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = (prefs.getBool('rememberMe') ?? false);
      if (_rememberMe) {
        _emailController.text = (prefs.getString('email') ?? '');
        _passwordController.text = (prefs.getString('password') ?? '');
      }
    });
  }

  // 로그인 시 '로그인 정보 기억하기' 상태를 저장
// --- 2. 로그인 함수 Supabase 연동 ---
  void _validateAndLogin() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final prefs = await SharedPreferences.getInstance();

    try {
      // AuthService의 loginUser 함수 호출
      final response = await _authService.loginUser(
        email: email,
        password: password,
      );

      // 로그인 성공
      if (response.user != null) {
        // '로그인 정보 기억하기' 로직
        if (_rememberMe) {
          await prefs.setString('email', email); // 'id' 대신 'email' 저장
          await prefs.setString('password', password);
          await prefs.setBool('rememberMe', true);
        } else {
          await prefs.remove('email');
          await prefs.remove('password');
          await prefs.remove('rememberMe');
        }

        // 로그인 성공 시 HomeScreen으로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _showError('로그인에 실패했습니다.');
      }
    } on AuthException catch (e) {
      // Supabase 인증 오류
      _showError('로그인 실패: ${e.message}');
    } catch (e) {
      // 기타 알 수 없는 오류
      _showError('알 수 없는 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }

  // '회원가입' 버튼을 눌렀을 때 실행되는 함수
  void _onSignUpPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  // 'ID 찾기' 버튼을 눌렀을 때 실행되는 함수
  void _onFindIdPressed() {
    print('ID 찾기 버튼 클릭');
  }

  // 'PW 찾기' 버튼을 눌렀을 때 실행되는 함수
  void _onFindPwPressed() {
    print('PW 찾기 버튼 클릭');
  }

  // 소셜 로그인 버튼을 눌렀을 때 실행될 함수. 어떤 버튼인지 인자로 받음
  // 백엔드 연결
  void _onSocialLoginPressed(String platform) async {
    try {
      var response;
      if (platform == 'Google') {
        response = await _authService.signInWithGoogle();
      } else if (platform == 'KakaoTalk') {
        response = await _authService.signInWithKakao();
      } // else if (platform == 'Apple') {
      //   response = await _authService.signInWithApple();
      // }

      if (response != null && response.user != null) {
        // 소셜 로그인 성공 시 HomeScreen으로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _showError('$platform 로그인 실패');
      }
    } catch (e) {
      _showError('$platform 로그인 중 오류 발생: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('에러'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // 기본적인 Material 디자인 레이아웃 구조를 제공
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),  // 모든 방향에 25의 여백
          child: Form(                        // 폼을 생성하여 유효성 검사를 쉽게 만듦
            key: _formKey,                    // 폼의 상태를 관리하기 위해 key를 연결
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 자식들을 세로 방향 중앙에 정렬
              crossAxisAlignment: CrossAxisAlignment.start, // 자식들을 가로 방향 왼쪽으로 정렬
              children: [
                const Text(
                  '이메일 주소',  //ID > 이메일 주소
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),    // 위젯 사이에 8만큼의 세로 간격
                TextFormField(                // 텍스트 입력 필드
                  controller: _emailController,  // _idController > _emailController와 연결
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(     // 입력 필드의 디자인 설정
                    labelText: '이메일',                  // 필드가 비어있을 때 표시될 힌트 텍스트 > 이메일
                    border: OutlineInputBorder(),        // 테두리
                    prefixIcon: Icon(Icons.email_outlined),      // 필드 왼쪽에 사람 아이콘
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요.';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return '올바른 이메일 형식이 아닙니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // 입력된 글자를 숨겨줌 (비밀번호용)
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe, // 체크박스의 현재 상태(_rememberMe)를 표시
                      onChanged: (bool? value) { // 체크박스가 눌렸을 때 실행
                        setState(() { // 위젯의 상태가 변경되었음을 알리고 화면을 다시 그림
                          _rememberMe = value ?? false; // _rememberMe 변수 값을 업데이트
                        });
                      },
                    ),
                    const Text('로그인 정보 기억하기'),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(                 // 튀어나와 보이는 버튼
                  onPressed: _isLoading ? null : _validateAndLogin, // 버튼을 누르면 _validateAndLogin 함수를 호출
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50), // 가로 전체, 세로 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 버튼 모서리를 둥글게
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _onSignUpPressed, // 버튼을 누르면 _onSignUpPressed 함수를 호출
                      child: const Text('회원가입', style: TextStyle(color: Colors.blue)),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: _onFindIdPressed,
                      child: const Text('ID 찾기', style: TextStyle(color: Colors.blue)),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: _onFindPwPressed,
                      child: const Text('PW 찾기', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(height: 1, thickness: 1, color: Colors.grey), // 가로 구분선
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    '소셜로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton( // 아이콘 형태 버튼
                      iconSize: 48,
                      onPressed: () => _onSocialLoginPressed('Google'),
                      icon: Image.asset(
                        'assets/images/google.jpg',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 48,
                      onPressed: () => _onSocialLoginPressed('KakaoTalk'),
                      icon: Image.asset(
                        'assets/images/kakao.jpg',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 20),

                    IconButton(
                      iconSize: 48,
                      onPressed: () => _onSocialLoginPressed('Apple'),
                      icon: Image.asset(
                        'assets/images/apple.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}