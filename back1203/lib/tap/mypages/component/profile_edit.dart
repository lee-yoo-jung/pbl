import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 뱃지 데이터 모델
class UserBadge {
  final String id;
  final String name;
  final String assetPath; // 뱃지 이미지 파일 경로
  final String description;

  UserBadge({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.description,
  });
}

// 편집된 데이터 반환 모델
class ProfileEditData {
  final String nickname;
  final String? profileImagePath;
  final UserBadge? selectedBadge;

  ProfileEditData({
    required this.nickname,
    this.profileImagePath,
    this.selectedBadge,
  });
}

class ProfileEditUI extends StatefulWidget {
  final Function(ProfileEditData data)? onSave;

  final String initialNickname;
  final String initialImagePath;
  final UserBadge? initialSelectedBadge;

  const ProfileEditUI({
    super.key,
    this.onSave,
    this.initialNickname = '', // 기본값 비워둠
    this.initialImagePath = 'assets/images/profile.jpg', // 기본 이미지 경로 수정 권장
    this.initialSelectedBadge,
  });

  @override
  State<ProfileEditUI> createState() => _ProfileEditUIState();
}

class _ProfileEditUIState extends State<ProfileEditUI> {
  final supabase = Supabase.instance.client; // Supabase 클라이언트
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nicknameController;

  // 상태 변수
  bool _isLoading = false; // 로딩 상태
  String? _serverProfileImageUrl; // 서버에 저장된 이미지 URL
  String? _newProfileImagePath; // 새로 선택한 로컬 이미지 경로
  UserBadge? _selectedBadge;

// 테스트용 뱃지 목록 (assetPath를 assets 폴더의 실제 파일 경로로 지정)
  final List<UserBadge> _availableBadges = [
    UserBadge(id: '1', name: '응원왕', assetPath: 'assets/badge1.png', description: '50번 응원하기'),
    UserBadge(id: '2', name: '성실이', assetPath: 'assets/badge2.png', description: '연속 100% 달성'),
    UserBadge(id: '3', name: '인기스타', assetPath: 'assets/badge3.png', description: '20번 응원받기'),
    UserBadge(id: '4', name: '꾸준이', assetPath: 'assets/badge4.png', description: '한 목표에서 체크된 계획 20개'),
    UserBadge(id: '1', name: '응원왕', assetPath: 'assets/images/badge1.png', description: '50번 응원하기'),
    UserBadge(id: '2', name: '성실이', assetPath: 'assets/images/badge2.png', description: '연속 100% 달성'),
    UserBadge(id: '3', name: '인기스타', assetPath: 'assets/images/badge3.png', description: '20번 응원받기'),
    UserBadge(id: '4', name: '꾸준이', assetPath: 'assets/images/badge4.png', description: '한 목표에서 체크된 계획 20개'),
  ];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _loadUserProfile(); // 초기 데이터 로드
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('users')
          .select('nickname, avatar_url, badge_id')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _serverProfileImageUrl = data['avatar_url'];

          // DB에 저장된 badge_id로 뱃지 객체 찾기
          if (data['badge_id'] != null) {
            try {
              _selectedBadge = _availableBadges.firstWhere(
                    (b) => b.id == data['badge_id'].toString(),
              );
            } catch (e) {
              _selectedBadge = null;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(String filePath) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('profiles').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = supabase.storage.from('profiles').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      throw Exception('이미지 업로드 중 오류가 발생했습니다.');
    }
  }

  Future<void> _handleSave() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      String? finalImageUrl = _serverProfileImageUrl;

      // 새 이미지가 있다면 업로드
      if (_newProfileImagePath != null) {
        final uploadedUrl = await _uploadImage(_newProfileImagePath!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      // DB 업데이트
      await supabase.from('users').update({
        'nickname': newNickname,
        'avatar_url': finalImageUrl,
        'badge_id': _selectedBadge?.id,
      }).eq('id', userId);

      // 완료
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );

        // 상위 위젯에 데이터 전달
        final data = ProfileEditData(
          nickname: _nicknameController.text,
          profileImagePath: finalImageUrl,
          selectedBadge: _selectedBadge,
        );
        widget.onSave?.call(data);

        Navigator.pop(context); // 화면 닫기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _newProfileImagePath = pickedFile.path;
      });
    }

    if (mounted) Navigator.pop(context);
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 사진 찍기'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

// 뱃지 선택 다이얼로그
  void _showBadgeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('뱃지 선택'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
// 뱃지 없음 옵션
                RadioListTile<UserBadge?>(
                  title: const Text('뱃지 없음'),
                  value: null,
                  groupValue: _selectedBadge,
                  onChanged: (value) {
                    setState(() => _selectedBadge = value);
                    Navigator.pop(context);
                  },
                ),
// 뱃지 목록
                ..._availableBadges.map((badge) {
                  return RadioListTile<UserBadge>(
                    title: Text(badge.name),
                    subtitle: Text(badge.description),
                    value: badge,
                    groupValue: _selectedBadge,
                    onChanged: (value) {
                      setState(() => _selectedBadge = value);
                      Navigator.pop(context);
                    },
// Image.asset을 사용하여 그림 표시
                    secondary: Image.asset(
                      badge.assetPath,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error_outline, size: 32),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('닫기'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
            ),
          )
          : TextButton(
            onPressed: _handleSave,
            child: const Text('저장', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildProfileImageSection(),
            const SizedBox(height: 32),
            _buildNicknameSection(),
            const SizedBox(height: 32),
            _buildBadgeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    ImageProvider? imageProvider;

    // 새로 선택한 이미지가 있으면 최우선
    if (_newProfileImagePath != null) {
      imageProvider = FileImage(File(_newProfileImagePath!));
    }
    // 서버에 저장된 이미지가 있으면 표시
    else if (_serverProfileImageUrl != null && _serverProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_serverProfileImageUrl!);
    }
    // 둘 다 없으면 기본 이미지
    else {
      imageProvider = const AssetImage('assets/images/profile.jpg');
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageProvider,
          child: imageProvider == null // 이미지 로드 실패 시 아이콘 표시
              ? const Icon(Icons.person, size: 70)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.blue),
            onPressed: _showImageSourceActionSheet,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('닉네임',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: '새 닉네임 입력',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _nicknameController.clear(),
            ),
          ),
        ),
      ],
    );
  }

// 뱃지 표시 섹션 수정
  Widget _buildBadgeSection() {
    final badge = _selectedBadge;

// 리딩 위젯: 뱃지가 선택되었으면 Image.asset, 아니면 기본 아이콘
    final leadingWidget = badge != null
        ? Image.asset(
      badge.assetPath,
      width: 30, // 크기 조정
      height: 30, // 크기 조정
      errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.image_not_supported, size: 30),
    )
        : const Icon(Icons.clear, size: 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('전시할 뱃지',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          title: Text(badge?.name ?? '선택된 뱃지 없음'),
          subtitle: Text(
            badge?.description ?? '프로필에 전시할 뱃지를 선택하세요.',
          ),
          leading: leadingWidget,
          trailing: const Icon(Icons.edit),
          onTap: _showBadgeSelectionDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }
}