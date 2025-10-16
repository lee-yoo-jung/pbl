import 'package:flutter/material.dart';
import 'dart:math';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController(); // 인증 코드 입력 컨트롤러

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  // 이메일 인증 관련 상태 변수
  bool _isEmailVerified = false; // 이메일 인증이 완료되었는지 여부
  bool _verificationCodeSent = false; // 인증 코드가 전송되었는지 여부
  String? _verificationCode; // 실제 전송된 인증 코드를 저장

  // 비번 조건: 영문, 숫자, 특수문자가 각각 2종류 이상 조합된 6자 이상
  static final RegExp _passwordRegex = RegExp(
      r'^(?=.*[a-zA-Z].*[a-zA-Z])'
      r'(?=.*[0-9].*[0-9])'
      r'(?=.*[!@#\$%^&*].*[!@#\$%^&*])'
      r'.{6,}$'
  );

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  // 더미 인증 코드 전송 로직
  void _sendVerificationCode() async {
    // 이메일 입력 필드 유효성만 확인
    if (!_validateEmailField()) {
      return;
    }

    // 백엔드 API 호출 로직
    setState(() {
      _verificationCodeSent = true;
      _isEmailVerified = false;
      // 6자리 랜덤 숫자 코드 생성 (더미)
      _verificationCode = (Random().nextInt(900000) + 100000).toString();
      _verificationCodeController.clear(); // 코드 재전송 시 입력 필드 초기화
    });

    // 사용자에게 전송 알림 (실제로는 이메일로 전송됨)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('인증 코드가 전송되었습니다. (더미 코드: $_verificationCode)'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // 이메일 입력 필드의 유효성을 개별적으로 검증하는 함수
  bool _validateEmailField() {
    // FormFieldState를 얻기 위한 GlobalKey가 필요하거나,
    // 이메일 TextFormField의 validator 로직을 복사하여 사용
    final emailValue = _emailController.text;
    if (emailValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.')),
      );
      return false;
    }
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(emailValue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식이 아닙니다.')),
      );
      return false;
    }
    return true;
  }

  // 인증 코드 확인 로직
  void _verifyCode() {
    final enteredCode = _verificationCodeController.text.trim();

    if (_verificationCode == null) {
      // 코드가 전송되지 않은 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 이메일 인증을 요청해주세요.')),
      );
      return;
    }

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 입력해주세요.')),
      );
      return;
    }

    if (enteredCode == _verificationCode) {
      setState(() {
        _isEmailVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증이 완료되었습니다.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _isEmailVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드가 일치하지 않습니다.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  void _submitSignUpForm() {
    if (!_isEmailVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('알림'),
          content: const Text('이메일 인증을 완료해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String id = _idController.text;
      String password = _passwordController.text;
      String email = _emailController.text;

      print('회원가입 정보:');
      print('이름: $name');
      print('아이디: $id');
      print('비밀번호: $password');
      print('이메일: $email');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 성공'),
          content: Text('이름: $name\n아이디: $id\n이메일: $email\n\n회원가입이 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // 회원가입 페이지 닫기 (이전 화면으로 돌아감)
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 모든 ElevatedButton에 적용할 파란색 스타일
    final ButtonStyle blueButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue, // 배경색을 파란색으로 명시
      foregroundColor: Colors.white, // 텍스트 색상을 흰색으로
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // 이름 입력 필드
              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름을 입력해주세요 (영어 또는 한글)',
                  hintText: '영어 또는 한글로 입력',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  final nameRegExp = RegExp(r"^[a-zA-Z가-힣\s]+$");
                  if (!nameRegExp.hasMatch(value)) {
                    return '이름은 영어 또는 한글로만 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 아이디 입력 필드
              const Text(
                '아이디',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '사용하실 아이디를 입력해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '아이디를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 비밀번호 입력 필드
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호를 입력해주세요',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  // 비밀번호 조건 유효성 검사
                  if (!_passwordRegex.hasMatch(value)) {
                    return '비밀번호 조건을 만족하지 못합니다.';
                  }
                  return null;
                },
                onChanged: (value) {
                  // 비밀번호 확인 필드 UI 갱신을 위해
                  if (_passwordConfirmController.text.isNotEmpty) {
                    setState(() {});
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 20),
                child: Text(
                  '※ 영문, 숫자, 특수문자가 각각 2개 이상 포함된 6자 이상',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

              // 비밀번호 확인 입력 필드
              const Text(
                '비밀번호 확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordConfirmController,
                obscureText: _obscurePasswordConfirm,
                decoration: InputDecoration(
                    labelText: '비밀번호를 다시 입력해주세요',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_passwordController.text.isNotEmpty &&
                            _passwordConfirmController.text.isNotEmpty &&
                            _passwordController.text == _passwordConfirmController.text)
                          const Icon(Icons.check, color: Colors.green),
                        IconButton(
                          icon: Icon(
                            _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePasswordConfirm = !_obscurePasswordConfirm;
                            });
                          },
                        ),
                      ],
                    )),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  if (!_passwordRegex.hasMatch(_passwordController.text)) {
                    return '새 비밀번호가 조건을 만족하지 못합니다.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // 비밀번호 일치 여부에 따라 suffixIcon (체크 표시)을 업데이트
                },
              ),
              const SizedBox(height: 20),

              // 이메일 입력 필드 및 인증 버튼
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // 오류 메시지를 고려
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isEmailVerified, // 인증 완료 후에는 수정 불가
                      decoration: InputDecoration(
                        labelText: '이메일 주소를 입력해주세요',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: _isEmailVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null, // 인증 완료 시 체크 표시
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요.';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // 이메일 내용 변경 시 인증 상태 초기화
                        if (_isEmailVerified) {
                          setState(() {
                            _isEmailVerified = false;
                            _verificationCodeSent = false;
                            _verificationCode = null;
                            _verificationCodeController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isEmailVerified
                        ? null // 인증 완료 시 버튼 비활성화
                        : _sendVerificationCode,
                    style: blueButtonStyle.copyWith(
                      // 비활성화 상태일 때는 회색을 유지
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey;
                          }
                          return blueButtonStyle.backgroundColor?.resolve({});
                        },
                      ),
                      minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                    ),
                    child: Text(
                      _verificationCodeSent ? '재전송' : '인증하기',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              // 인증 코드 입력 필드 (코드가 전송된 후에만 표시)
              if (_verificationCodeSent && !_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _verificationCodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '인증 코드를 입력해주세요 (6자리)',
                            hintText: '인증 코드',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '인증 코드를 입력해주세요.';
                            }
                            if (value.length != 6 || int.tryParse(value) == null) {
                              return '6자리 숫자를 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _verifyCode,
                        style: blueButtonStyle.copyWith(
                          minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                        ),
                        child: const Text('확인', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              // 가입하기 버튼
              ElevatedButton(
                onPressed: _submitSignUpForm,
                style: blueButtonStyle.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  '가입하기',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}