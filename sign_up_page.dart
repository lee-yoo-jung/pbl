//회원가입 화면
// lib/sign_up_page.dart
import 'package:flutter/material.dart';

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

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitSignUpForm() {
    if (_formKey.currentState!.validate()) { // 이 시점에 모든 validator가 호출됨
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
                Navigator.pop(context);
                Navigator.pop(context);
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
              // 이름 입력 필드 (이전과 동일)
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

              // 아이디 입력 필드 (이전과 동일)
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
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다.';
                  }
                  // **StackOverflow 원인 제거:** 아래 라인 제거 또는 주석 처리
                  // if (_passwordConfirmController.text.isNotEmpty) {
                  //   _formKey.currentState?.validate(); // <--- 이 부분 제거!
                  // }
                  return null;
                },
                // 비밀번호가 변경될 때 비밀번호 확인 필드의 UI를 업데이트하기 위해 setState 호출
                onChanged: (value) {
                  // 비밀번호 확인 필드의 체크 아이콘 등을 즉시 업데이트하고 싶다면
                  // 그리고 비밀번호 확인 필드가 이미 내용을 가지고 있다면 해당 필드의 유효성만 다시 체크할 수 있도록
                  // _formKey.currentState?.validate() 대신 다른 방법을 사용하거나,
                  // 혹은 비밀번호 확인 필드의 onChanged 에서 setState만 호출하도록 한다.
                  // 여기서는 비밀번호 확인 필드의 onChanged 에서 이미 setState를 호출하고 있으므로 추가 작업이 필요 없을 수 있음.
                  // 또는 명시적으로 비밀번호 확인 필드만 재검증하고 싶다면 해당 필드의 FormFieldState를 직접 다뤄야 함 (더 복잡)
                  // 가장 간단한 것은 비밀번호 확인 필드의 onChanged에서 setState({})를 호출하는 것입니다.
                  if (_passwordConfirmController.text.isNotEmpty) {
                    setState(() {}); // 비밀번호 확인 필드의 suffixIcon UI 갱신을 위해
                  }
                },
              ),
              const SizedBox(height: 20),

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
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // 비밀번호 일치 여부에 따라 suffixIcon (체크 표시)을 업데이트
                },
              ),
              const SizedBox(height: 20),

              // 이메일 입력 필드 (이전과 동일)
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일 주소를 입력해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
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
              ),
              const SizedBox(height: 30),

              // 가입하기 버튼 (이전과 동일)
              ElevatedButton(
                onPressed: _submitSignUpForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

