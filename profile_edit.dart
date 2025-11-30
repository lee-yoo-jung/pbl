import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  // 초기값
  final String initialNickname;
  final String initialImagePath;
  final UserBadge? initialSelectedBadge;

  const ProfileEditUI({
    super.key,
    this.onSave,
    this.initialNickname = '사용자 닉네임',
    this.initialImagePath = 'assets/profile.jpg',
    this.initialSelectedBadge,
  });

  @override
  State<ProfileEditUI> createState() => _ProfileEditUIState();
}

class _ProfileEditUIState extends State<ProfileEditUI> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nicknameController;

  String? _newProfileImagePath;
  UserBadge? _selectedBadge;

  // 테스트용 뱃지 목록 (assetPath를 assets 폴더의 실제 파일 경로로 지정)
  final List<UserBadge> _availableBadges = [
    UserBadge(id: '1', name: '응원왕', assetPath: 'assets/badge1.jpg', description: '50번 응원하기'),
    UserBadge(id: '2', name: '성실이', assetPath: 'assets/badge2.jpg', description: '연속 100% 달성'),
    UserBadge(id: '3', name: '인기스타', assetPath: 'assets/badge3.jpg', description: '20번 응원받기'),
    UserBadge(id: '4', name: '꾸준이', assetPath: 'assets/badge4.jpg', description: '한 목표에서 체크된 계획 20개'),
  ];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);

    // 초기값이 없으면 null로 설정하여 "뱃지 없음" 상태 유지
    _selectedBadge = widget.initialSelectedBadge;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
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

  void _handleSave() {
    final data = ProfileEditData(
      nickname: _nicknameController.text,
      profileImagePath: _newProfileImagePath,
      selectedBadge: _selectedBadge,
    );

    widget.onSave?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
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
    final String currentImagePath =
        _newProfileImagePath ?? widget.initialImagePath;
    final bool isLocal = currentImagePath.startsWith('/');
    final bool exists = isLocal && File(currentImagePath).existsSync();

    Widget img;
    if (exists) {
      img = Image.file(File(currentImagePath), fit: BoxFit.cover);
    } else if (currentImagePath.startsWith('http')) {
      img = Image.network(currentImagePath, fit: BoxFit.cover);
    } else {
      img = Image.asset(
        widget.initialImagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.person, size: 70),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          child: ClipOval(
            child: SizedBox(width: 120, height: 120, child: img),
          ),
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