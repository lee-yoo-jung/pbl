import 'package:flutter/material.dart';
import 'dart:math';

const Color primaryDeepPurple = Color(0xFF192C4E);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '비밀번호 재설정 및 변경',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryDeepPurple),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const PasswordResetAndChangePage(),
    );
  }
}

class PasswordResetAndChangePage extends StatefulWidget {
  const PasswordResetAndChangePage({super.key});

  @override
  State<PasswordResetAndChangePage> createState() =>
      _PasswordResetAndChangePageState();
}

class _PasswordResetAndChangePageState
    extends State<PasswordResetAndChangePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();

  bool _verificationSent = false; // 인증코드 발송됨 상태
  bool _verified = false; // 이메일 인증 성공 상태
  String? _generatedCode;

  bool _obscurePw1 = true; // 비밀번호 숨김 상태
  bool _obscurePw2 = true; // 비밀번호 확인 숨김 상태

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  // 이메일 형식 체크
  bool _validateEmailFormat(String email) {
    // 이메일 형식 검사 정규식
    return RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  // 인증번호 발송
  void _sendCode() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack("이메일을 입력해주세요.", success: false);
      return;
    }

    if (!_validateEmailFormat(email)) {
      _showSnack("올바른 이메일 형식이 아닙니다.", success: false);
      return;
    }

    // 6자리 난수 생성
    _generatedCode = (Random().nextInt(900000) + 100000).toString();

    setState(() {
      _verificationSent = true;
      _verified = false;
      _codeController.clear();
    });

    _showSnack("인증번호가 전송되었습니다. (더미 코드: $_generatedCode)", success: true);
  }

  // 인증번호 확인
  void _verifyCode() {
    if (_generatedCode == null) {
      _showSnack("먼저 인증번호를 요청해주세요.", success: false);
      return;
    }

    if (_codeController.text.trim() == _generatedCode) {
      setState(() => _verified = true);
      _showSnack("이메일 인증이 완료되었습니다! 이제 비밀번호를 변경할 수 있습니다.", success: true);
    } else {
      _showSnack("인증번호가 일치하지 않습니다.", success: false);
    }
  }

  // 비밀번호 정규식 (영어 2 + 숫자 2 + 특수문자 2 이상)
  final _pwRegex = RegExp(
      r'^(?=.*[a-zA-Z].*[a-zA-Z])' // 영문 2자 이상
      r'(?=.*[0-9].*[0-9])' // 숫자 2자 이상
      r'(?=.*[!@#\$%^&*].*[!@#\$%^&*])' // 특수문자 2자 이상
      r'.{6,}$'); // 총 6자 이상

  // 비밀번호 변경 처리
  void _changePassword() {
    final pw = _pwController.text.trim();
    final pw2 = _pwConfirmController.text.trim();

    if (!_verified) {
      _showSnack("비밀번호를 변경하려면 먼저 이메일 인증을 완료해야 합니다.", success: false);
      return;
    }

    if (pw.isEmpty || pw2.isEmpty) {
      _showSnack("새 비밀번호와 비밀번호 확인을 모두 입력해주세요.", success: false);
      return;
    }

    if (!_pwRegex.hasMatch(pw)) {
      _showSnack("비밀번호 조건을 만족하지 않습니다. (영문/숫자/특수문자 각각 2자 이상, 총 6자 이상)", success: false);
      return;
    }

    if (pw != pw2) {
      _showSnack("새 비밀번호와 확인 비밀번호가 서로 일치하지 않습니다.", success: false);
      return;
    }

    _showSnack("비밀번호가 성공적으로 변경되었습니다!", success: true);

    _emailController.clear();
    _codeController.clear();
    _pwController.clear();
    _pwConfirmController.clear();
    setState(() {
      _verificationSent = false;
      _verified = false;
      _generatedCode = null;
    });
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: primaryDeepPurple, width: 2),
      ),
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: primaryDeepPurple),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: primaryDeepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      minimumSize: const Size(double.infinity, 50),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("비밀번호 찾기", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryDeepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("이메일 인증",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepPurple)),

            const SizedBox(height: 10),

            Text("가입한 이메일",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    enabled: !_verified,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      labelText: "이메일 주소",
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _verified ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verified ? Colors.green.shade400 : primaryDeepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(100, 56),
                  ),
                  child: Text(_verified ? "인증됨" : (_verificationSent ? "재전송" : "인증")),
                )
              ],
            ),

            if (_verificationSent && !_verified)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          labelText: "인증번호 6자리",
                          prefixIcon: Icons.vpn_key_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryDeepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(100, 56),
                      ),
                      child: const Text("확인"),
                    )
                  ],
                ),
              ),

            const SizedBox(height: 40),

            const Text("비밀번호 변경",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepPurple)),

            IgnorePointer(
              ignoring: !_verified,
              child: Opacity(
                opacity: _verified ? 1.0 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("새 비밀번호",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _pwController,
                      obscureText: _obscurePw1,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: _buildInputDecoration(
                        labelText: "새 비밀번호 입력",
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePw1
                              ? Icons.visibility_off
                              : Icons.visibility, color: Colors.grey),
                          onPressed: () {
                            setState(() => _obscurePw1 = !_obscurePw1);
                          },
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 20, left: 5),
                      child: Text(
                        "※ 영문, 숫자, 특수문자 각각 2자 이상 포함 (총 6자 이상)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                    Text("비밀번호 확인",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _pwConfirmController,
                      obscureText: _obscurePw2,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: _buildInputDecoration(
                        labelText: "새 비밀번호 다시 입력",
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePw2
                              ? Icons.visibility_off
                              : Icons.visibility, color: Colors.grey),
                          onPressed: () {
                            setState(() => _obscurePw2 = !_obscurePw2);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _verified ? _changePassword : null,
                      style: buttonStyle,
                      child: const Text("비밀번호 변경"),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
