import 'package:flutter/material.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage ({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final _formKey = GlobalKey<FormState>();

  // 각 입력 필드의 텍스트를 제어하는 컨트롤러
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isNewPasswordValid = false;
  bool _isPasswordMatch = false;

  // 비번 조건: 영문, 숫자, 특수문자가 각각 2종류 이상 조합된 6자 이상
  static final RegExp _passwordRegex = RegExp(
      r'^(?=.*[a-zA-Z].*[a-zA-Z])'
      r'(?=.*[0-9].*[0-9])'
      r'(?=.*[!@#\$%^&*].*[!@#\$%^&*])'
      r'.{6,}$'
  );


  @override
  void initState() {
    super.initState();
    // 새 비밀번호와 확인 비밀번호가 변경될 때마다 유효성 검사를 수행하도록 리스너 추가
    _newPasswordController.addListener(_validateFields);
    _confirmPasswordController.addListener(_validateFields);
  }

  @override
  void dispose() {    // 리스너를 제거하고 컨트롤러를 해제하여 메모리 누수를 방지
    _newPasswordController.removeListener(_validateFields);
    _confirmPasswordController.removeListener(_validateFields);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  // 모든 유효성 검사 및 버튼 활성화 상태를 업데이트
  void _validateFields() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // 새 비밀번호 조건 검사
    final newPasswordValid = _passwordRegex.hasMatch(newPass);

    // 새 비밀번호와 확인 비밀번호 일치 검사
    final passwordMatch = newPass.isNotEmpty && newPass == confirmPass;

    // 상태가 변경되었을 때만 UI 업데이트
    if (_isNewPasswordValid != newPasswordValid || _isPasswordMatch != passwordMatch) {
      setState(() {
        _isNewPasswordValid = newPasswordValid;
        _isPasswordMatch = passwordMatch;
      });
    }
  }


  // '비밀번호 변경' 버튼 활성화 여부를 결정하는 함수
  bool _isButtonEnabled() {
    return _currentPasswordController.text.isNotEmpty && _isNewPasswordValid && _isPasswordMatch;
    // 현재 비밀번호가 비어있지 않고, 새 비밀번호가 유효하며, 두개의 새 비밀번호가 일치해야 함
  }

  // '비밀번호 변경' 버튼 클릭 시 실행될 함수
  void _changePassword() {
    // 폼 유효성 검사 및 버튼 활성화 상태 확인
    if (_formKey.currentState!.validate() && _isButtonEnabled()) {

      // 실제 서버 API 호출을 통해 비밀번호를 변경하는 로직 구현


      // 변경 성공 팝업
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('변경 성공'),
          content: const Text('비밀번호가 성공적으로 변경되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else if (!_currentPasswordController.text.isNotEmpty) {   // 현재 비밀번호를 입력하지 않았다면
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: const Text('현재 비밀번호를 입력해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  // 비밀번호 입력 필드를 위한 공통 위젯 생성 함수
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    bool isNewPassword = false,
    bool isConfirmPassword = false,
  }) {

    // 유효성 검사 상태에 따라 아이콘 결정
    Widget? getSuffixIcon() {
      if (isNewPassword) {
        if (controller.text.isEmpty) return null; // 텍스트가 없으면 아이콘 표시 안 함
        return Icon(
          _isNewPasswordValid ? Icons.check_circle : Icons.cancel,
          color: _isNewPasswordValid ? Colors.green : Colors.red,
        );
      }
      if (isConfirmPassword) {
        if (controller.text.isEmpty) return null;
        return Icon(
          _isPasswordMatch ? Icons.check_circle : Icons.cancel,
          color: _isPasswordMatch ? Colors.green : Colors.red,
        );
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 필드 제목
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),

        // 실제 비밀번호 입력 필드
        TextFormField(
          controller: controller,
          obscureText: true,     // 입력 텍스트 가리기
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: getSuffixIcon(),
          ),
          validator: (value) {
            // 폼 제출 시 실행되는 최종 유효성 검사
            if (value == null || value.isEmpty) {
              return '비밀번호를 입력해주세요.';
            }
            if (isNewPassword && !_isNewPasswordValid && value.isNotEmpty) {
              return '비밀번호 조건을 만족하지 못합니다.';
            }
            if (isConfirmPassword && !_isPasswordMatch && value.isNotEmpty) {
              return '새 비밀번호와 일치하지 않습니다.';
            }
            return null; // 유효성 통과
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: SingleChildScrollView(    // 내용이 넘칠 경우 스크롤 가능하게 해줌
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey, // 폼 상태 관리를 위한 키
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 현재 비밀번호 입력 필드
              _buildPasswordField(
                label: '현재 비밀번호',
                controller: _currentPasswordController,
              ),

              // 새 비밀번호 입력 필드
              _buildPasswordField(
                label: '새 비밀번호',
                controller: _newPasswordController,
                isNewPassword: true,
              ),

              // 새 비밀번호 확인 입력 필드
              _buildPasswordField(
                label: '새 비밀번호 확인',
                controller: _confirmPasswordController,
                isConfirmPassword: true,
              ),

              // 비밀번호 조건 안내 텍스트
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Text(
                  '※ 영문, 숫자, 특수문자가 각각 2개 이상 포함된 6자 이상',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

              // 비밀번호 변경 버튼
              ElevatedButton(
                // _isButtonEnabled() 결과에 따라 버튼 활성화/비활성화 결정
                onPressed: _isButtonEnabled() ? _changePassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  '비밀번호 변경',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 실행
void main() {
  runApp(const MaterialApp(
    home: PasswordChangePage(),
  ));
}