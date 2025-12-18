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

  // 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController(); // 인증 코드 컨트롤러

  // 상태 변수
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  bool _isSendingCode = false;  // '인증하기' 버튼 로딩
  bool _isVerifyingCode = false; // '확인' 버튼 로딩

  // 이메일 인증 관련 상태 변수
  bool _isEmailVerified = false; // 이메일 인증이 완료되었는지 여부
  bool _verificationCodeSent = false; // 인증 코드가 전송되었는지 여부

  // 비번 조건
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

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 정보를 올바르게 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'user_id': _idController.text.trim(),
          'nickname': _nameController.text.trim(),
        },
      );

      if (mounted) {
        setState(() {
          _verificationCodeSent = true;
          _isEmailVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_emailController.text}로 인증 코드가 전송되었습니다. 이메일을 확인해주세요.'),
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: ${error.message}'), // 예: "User already registered"
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알 수 없는 오류가 발생했습니다: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final enteredCode = _verificationCodeController.text.trim();
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isVerifyingCode = true);

    try {
      final AuthResponse res = await supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: enteredCode,
        email: _emailController.text.trim(),
      );

      if (res.user != null) {
        setState(() {
          _isEmailVerified = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이메일 인증이 완료되었습니다.'), backgroundColor: Colors.green),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: ${error.message}'), // "Invalid OTP" 등
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력 내용을 다시 확인해주세요.')),
      );
      return;
    }

    // 이메일 인증 완료 여부 확인
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

    showDialog(
      context: context,
      barrierDismissible: false, // 밖을 눌러도 안 닫히게
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원가입 성공'),
        content: Text('닉네임: ${_nameController.text}\n아이디: ${_idController.text}\n\n회원가입이 완료되었습니다. 로그인해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle blueButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // 닉네임 입력 필드
              const Text('닉네임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController, // '닉네임' 컨트롤러
                enabled: !_verificationCodeSent, // 인증 코드 전송 후 수정 불가
                decoration: const InputDecoration(
                  labelText: '표시될 닉네임을 입력해주세요',
                  hintText: '영어 또는 한글로 입력',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '닉네임을 입력해주세요.';
                  final nameRegExp = RegExp(r"^[a-zA-Z가-힣\s]+$");
                  if (!nameRegExp.hasMatch(value)) return '닉네임은 영어 또는 한글로만 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 아이디 입력 필드
              const Text('아이디', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController, // '아이디' 컨트롤러
                enabled: !_verificationCodeSent, // 인증 코드 전송 후 수정 불가
                decoration: const InputDecoration(
                  labelText: '로그인에 사용할 아이디를 입력해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '아이디를 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 비밀번호 입력 필드
              const Text('비밀번호', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                enabled: !_verificationCodeSent, // 인증 코드 전송 후 수정 불가
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호를 입력해주세요',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                  if (value.length < 6) return '비밀번호는 6자 이상이어야 합니다.';
                  if (!_passwordRegex.hasMatch(value)) return '비밀번호 조건을 만족하지 못합니다.';
                  return null;
                },
                onChanged: (value) {
                  if (_passwordConfirmController.text.isNotEmpty) setState(() {});
                },
              ),

              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 20),
                child: Text(
                  '※ 영문, 숫자, 특수문자가 각각 2개 이상 포함된 6자 이상',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              // 비밀번호 확인 입력 필드
              const Text('비밀번호 확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordConfirmController,
                enabled: !_verificationCodeSent, // 인증 코드 전송 후 수정 불가
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
                          icon: Icon(_obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                        ),
                      ],
                    )
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '비밀번호를 다시 입력해주세요.';
                  if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                  if (!_passwordRegex.hasMatch(_passwordController.text)) return '새 비밀번호가 조건을 만족하지 못합니다.';
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              const Text('이메일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isEmailVerified && !_verificationCodeSent, // 코드 전송 후, 그리고 인증 완료 후 수정 불가
                      decoration: InputDecoration(
                        labelText: '이메일 주소를 입력해주세요',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: _isEmailVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_isEmailVerified || _verificationCodeSent) {
                          setState(() {
                            _isEmailVerified = false;
                            _verificationCodeSent = false;
                            _verificationCodeController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isEmailVerified || _isSendingCode || _isVerifyingCode
                        ? null
                        : _sendVerificationCode,
                    style: blueButtonStyle.copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) return Colors.grey;
                          return blueButtonStyle.backgroundColor?.resolve({});
                        },
                      ),
                      minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                    ),
                    child: _isSendingCode // '인증하기' 버튼 로딩
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                      _verificationCodeSent ? '재전송' : '인증하기',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              // 인증 코드 입력 필드
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
                            if (value == null || value.isEmpty) return '인증 코드를 입력해주세요.';
                            if (value.length != 6 || int.tryParse(value) == null) return '6자리 숫자를 입력해주세요.';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isVerifyingCode || _isSendingCode ? null : _verifyCode,
                        style: blueButtonStyle.copyWith(
                          minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                        ),
                        child: _isVerifyingCode
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('확인', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSendingCode || _isVerifyingCode || !_isEmailVerified
                    ? null
                    : _signUp,
                style: blueButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) return Colors.grey;
                      return blueButtonStyle.backgroundColor?.resolve({});
                    },
                  ),
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