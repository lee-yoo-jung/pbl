import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LoginApp()); // LoginApp 위젯을 실행
}

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
  final _formKey = GlobalKey<FormState>(); // Form 위젯의 상태를 관리하기 위한 전역 키

  final TextEditingController _idController = TextEditingController(); // 아이디 입력 필드의 텍스트를 제어
  final TextEditingController _passwordController = TextEditingController(); // 비밀번호 입력 필드의 텍스트를 제어

  bool _rememberMe = false; // '로그인 정보 기억하기' 체크박스의 상태를 저장하는 변수
  bool _isPasswordVisible = false;

  // 로그인 정보 기억
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberMe();
    });
  }

  @override
  void dispose() {
    _idController.dispose(); // 위젯이 사라질 때 컨트롤러 정리하여 메모리 누수 방지
    _passwordController.dispose(); // 비밀번호 컨트롤러 정리
    super.dispose();
  }

  void _loadRememberMe() async {   //_loadRememberMe()처럼 await를 사용하는 비동기 함수는 별도로 호출
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = (prefs.getBool('rememberMe') ?? false);
      if (_rememberMe) {
        _idController.text = (prefs.getString('id') ?? '');
        _passwordController.text = (prefs.getString('password') ?? '');
      }
    });
  }

  // 로그인 시 '로그인 정보 기억하기' 상태를 저장
  void _validateAndLogin() async {
    if (_formKey.currentState!.validate()) {
      String id = _idController.text;
      String password = _passwordController.text;

      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        // 체크박스가 선택된 경우, 아이디, 비밀번호, 상태를 저장
        await prefs.setString('id', id);
        await prefs.setString('password', password);
        await prefs.setBool('rememberMe', true);
        print('아이디와 비밀번호가 기기에 저장되었습니다.');
      } else {
        // 체크박스가 해제된 경우, 저장된 정보를 삭제
        await prefs.remove('id');
        await prefs.remove('password');
        await prefs.remove('rememberMe');
        print('아이디와 비밀번호가 기기에서 삭제되었습니다.');
      }

      // 로그인 성공 시 팝업(AlertDialog)을 띄움
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 성공'), // 팝업의 제목
          content: Text('아이디: $id\n비밀번호: $password\n로그인 정보 기억하기: $_rememberMe'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 버튼을 누르면 팝업이 닫힘
              child: const Text('확인'), // 버튼에 표시될 텍스트
            ),
          ],
        ),
      );
    }
  }

  // '회원가입' 버튼을 눌렀을 때 실행되는 함수
  void _onSignUpPressed() {
    print('회원가입 버튼 클릭');
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
  void _onSocialLoginPressed(String platform) {
    print('$platform로 소셜 로그인 시도');
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
                  'ID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),    // 위젯 사이에 8만큼의 세로 간격
                TextFormField(                // 텍스트 입력 필드
                  controller: _idController,  // _idController와 연결
                  decoration: const InputDecoration(     // 입력 필드의 디자인 설정
                    labelText: '아이디',                  // 필드가 비어있을 때 표시될 힌트 텍스트
                    border: OutlineInputBorder(),        // 테두리
                    prefixIcon: Icon(Icons.person_outline),      // 필드 왼쪽에 사람 아이콘
                  ),
                  validator: (value) {                   // 입력값이 유효한지 검사
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력해주세요.';
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
                  onPressed: _validateAndLogin, // 버튼을 누르면 _validateAndLogin 함수를 호출
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50), // 가로 전체, 세로 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 버튼 모서리를 둥글게
                    ),
                  ),
                  child: const Text(
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