import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/services/auth_service.dart';
import 'package:pbl/screen/home_screen.dart';
import 'package:pbl/const/colors.dart';
import 'sign_up_page.dart';
import 'package:pbl/login/PWsearch_page.dart';

// 앱의 최상위 위젯, 앱 전체의 기본 설정을 담당
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로그인 데모',
      theme: ThemeData( // 앱의 전체적인 테마 설정
        primaryColor: const Color(0xFF192C4E), // 앱의 기본 색상 팔레트 파란색
        visualDensity: VisualDensity.adaptivePlatformDensity, // 플랫폼에 따라 UI 밀도 조절
      ),
      debugShowCheckedModeBanner: false, //debug 표시 제거
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
          await prefs.setString('email', email);
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

  // '회원가입 버튼을 눌렀을 때 실행되는 함수
  void _onSignUpPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  // 'PW 찾기' 버튼을 눌렀을 때 실행되는 함수
  void _onFindPwPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PasswordResetAndChangePage()),
    );
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),  // 모든 방향에 25의 여백
          child: Form(                        // 폼을 생성하여 유효성 검사를 쉽게 만듦
            key: _formKey,                    // 폼의 상태를 관리하기 위해 key를 연결
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 자식들을 세로 방향 중앙에 정렬
              crossAxisAlignment: CrossAxisAlignment.start, // 자식들을 가로 방향 왼쪽으로 정렬
              children: [
                const Text(
                  '이메일 주소',  //ID > 이메일 주소
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),    // 위젯 사이에 8만큼의 세로 간격
                TextFormField(                // 텍스트 입력 필드
                  controller: _emailController,  // _idController > _emailController와 연결
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(     // 입력 필드의 디자인 설정
                    labelText: '이메일',                  // 필드가 비어있을 때 표시될 힌트 텍스트 > 이메일
                    labelStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: DARK_GREY_COLOR
                    ),
                    border: OutlineInputBorder(),        // 테두리
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: PRIMARY_COLOR),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, size: 20,),      // 필드 왼쪽에 사람 아이콘
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
                    fontFamily: 'Pretendard',
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
                    labelStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: DARK_GREY_COLOR
                    ),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: PRIMARY_COLOR),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                        size: 20,
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
                      activeColor: DARK_BLUE,
                      side: const BorderSide(
                        color: Color(0xFF5B6161),
                        width: 1.0,
                      ),
                      onChanged: (bool? value) { // 체크박스가 눌렸을 때 실행
                        setState(() { // 위젯의 상태가 변경되었음을 알리고 화면을 다시 그림
                          _rememberMe = value ?? false; // _rememberMe 변수 값을 업데이트
                        });
                      },
                    ),
                    const Text(
                      '로그인 정보 기억하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF5B6161),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(                 // 튀어나와 보이는 버튼
                  onPressed: _isLoading ? null : _validateAndLogin, // 버튼을 누르면 _validateAndLogin 함수를 호출
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DARK_BLUE,
                    minimumSize: const Size(double.infinity, 50), // 가로 전체, 세로 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 버튼 모서리를 둥글게
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    '로그인',
                    style: TextStyle(
                        fontFamily: 'Prentendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _onSignUpPressed, // 버튼을 누르면 _onSignUpPressed 함수를 호출
                      child: const Text('회원가입', style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, color: PRIMARY_COLOR)),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: _onFindPwPressed,
                      child: const Text('PW 찾기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, color: PRIMARY_COLOR)),
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