import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
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
          backgroundColor: Colors.white,
          title: const Text(
              '알림',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
              '이메일 인증을 완료해주세요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: PRIMARY_COLOR,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              child: const Text(
                  '확인',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      backgroundColor: PRIMARY_COLOR, // 배경색을 파란색으로 명시
      foregroundColor: Colors.white, // 텍스트 색상을 흰색으로
    );

    TextStyle labelTextStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: DARK_GREY_COLOR,
    );

    // 폼 필드 테두리 스타일 (UnderlineInputBorder 사용)
    final InputDecoration standardInputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0), // 내부 세로 패딩 조정

      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: PRIMARY_COLOR, width: 2),
      ),
      // 기본 아이콘 색상
      prefixIconColor: DARK_GREY_COLOR,

      errorStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 13, color: Colors.red),
      labelStyle: labelTextStyle, // 라벨 스타일 적용
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 40.0,  //앱바의 높이 지정
        title: const Text(
            '회원가입',
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              SizedBox(height: 20,),
              // 이름 입력 필드
              TextFormField(
                controller: _nameController,
                decoration: standardInputDecoration.copyWith(
                  labelText: '이름 (Name)',
                  prefixIcon: const Icon(Icons.person_outline, size: 24),
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
              const SizedBox(height: 10),

              // 아이디 입력 필드
              TextFormField(
                controller: _idController,
                decoration: standardInputDecoration.copyWith(
                  labelText: '아이디 (ID)',
                  prefixIcon: const Icon(Icons.account_circle, size: 24),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '아이디를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // 비밀번호 입력 필드
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: standardInputDecoration.copyWith(
                  labelText: '비밀번호 (Password)',
                  prefixIcon: const Icon(Icons.lock_outline, size: 24),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: DARK_GREY_COLOR,
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
                  if (!_passwordRegex.hasMatch(value)) {
                    return '비밀번호 조건을 만족하지 못합니다.';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_passwordConfirmController.text.isNotEmpty) {
                    setState(() {});
                  }
                },
              ),
              // 조건 안내 텍스트
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 35, left: 40),
                child: Text(
                  '※ 영문, 숫자, 특수문자 각각 2개 이상 포함된 6자 이상',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

              // 비밀번호 확인 입력 필드
              TextFormField(
                controller: _passwordConfirmController,
                obscureText: _obscurePasswordConfirm,
                decoration: standardInputDecoration.copyWith(
                  labelText: '비밀번호 확인',
                  prefixIcon: const Icon(Icons.lock_outline, size: 24),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 일치 시 체크 아이콘
                      if (_passwordController.text.isNotEmpty &&
                          _passwordConfirmController.text.isNotEmpty &&
                          _passwordController.text == _passwordConfirmController.text)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                      // 비밀번호 보기/숨기기 아이콘
                      IconButton(
                        icon: Icon(
                            _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: DARK_GREY_COLOR
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirm = !_obscurePasswordConfirm;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),

              // 이메일 입력 필드 및 인증 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isEmailVerified,
                      decoration: standardInputDecoration.copyWith(
                        labelText: '이메일 (Email)',
                        prefixIcon: const Icon(Icons.email_outlined, size: 24),
                        suffixIcon: _isEmailVerified
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 20,)
                            : null,
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
                  const SizedBox(width: 12),
                  // 인증/재전송 버튼
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0), // UnderlineInputBorder와 높이 맞추기 위해 패딩 조정
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isEmailVerified
                            ? null
                            : _sendVerificationCode,
                        style: blueButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade400;
                              }
                              return blueButtonStyle.backgroundColor?.resolve({});
                            },
                          ),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        child: Text(
                          _verificationCodeSent ? '재전송' : '인증하기',
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w700
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 인증 코드 입력 필드 (코드가 전송된 후에만 표시)
              if (_verificationCodeSent && !_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _verificationCodeController,
                          keyboardType: TextInputType.number,
                          decoration: standardInputDecoration.copyWith(
                            labelText: '인증 코드를 입력해주세요 (6자리)',
                            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 24),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0), // 높이 맞추기 위해 패딩 조정
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _verifyCode,
                            style: blueButtonStyle.copyWith(
                              minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            ),
                            child: const Text(
                                '확인',
                                style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700
                                )
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 50),

              // 가입하기 버튼
              ElevatedButton(
                onPressed: _submitSignUpForm,
                style: blueButtonStyle.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 55)), // 버튼 높이 증가
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  '가입하기',
                  style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w800 // 버튼 텍스트 더욱 굵게
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}