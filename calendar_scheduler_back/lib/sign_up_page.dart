//회원가입 화면
// lib/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

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
  final TextEditingController _usernameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Supabase 회원가입 로직을 처리하는 함수
  Future<void> _signUp() async {
    // 폼 유효성 검사를 통과하지 못하면 함수 종료
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // Supabase Auth로 회원가입을 진행합니다.
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        // 'data' 필드를 통해 이름, 아이디 등 추가 정보를 저장합니다.
        data: {
          'name': _nameController.text,
          'username': _usernameController.text,
        },
      );

      // 회원가입 성공 시
      if (res.user != null) {
        if (mounted) { // 위젯이 여전히 화면에 있는지 확인
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 이메일을 확인하여 계정을 활성화해주세요.')),
          );
          // 성공 후 이전 화면으로 돌아가기
          Navigator.pop(context);
        }
      }
    } on AuthException catch (error) {
      // Supabase 인증 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 오류: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      // 기타 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알 수 없는 오류가 발생했습니다: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 로딩 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                onPressed: _isLoading ? null : _signUp,
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
