import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 뱃지
class UserBadge {
  final String id;
  final String name;
  final String assetPath;
  final String description;
  final bool isAcquired;

  UserBadge({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.description,
    this.isAcquired = false,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json, {bool isAcquired = false}) {
    return UserBadge(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      assetPath: json['image_path'] ?? '',
      description: json['description'] ?? '',
      isAcquired: isAcquired,
    );
  }
}

// 편집 완료 후 반환 데이터
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
    this.initialNickname = '',
    this.initialImagePath = 'assets/images/profile.jpg',
    this.initialSelectedBadge,
  });

  @override
  State<ProfileEditUI> createState() => _ProfileEditUIState();
}

class _ProfileEditUIState extends State<ProfileEditUI> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nicknameController;

  bool _isLoading = true;
  String? _serverProfileImageUrl;
  String? _newProfileImagePath;
  UserBadge? _selectedBadge;

  List<UserBadge> _myBadges = [];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _initializeData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 데이터 로드 통합 함수
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _loadUserBadges();
    await _loadUserProfile();
    if (mounted) setState(() => _isLoading = false);
  }

  // 내가 획득한 뱃지 목록 가져오기
  Future<void> _loadUserBadges() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('user_badges')
          .select('badges(id, name, image_path, description)')
          .eq('user_id', userId);

      final List<UserBadge> loadedBadges = [];
      for (var item in response) {
        final badgeData = item['badges'];
        if (badgeData != null) {
          loadedBadges.add(UserBadge.fromJson(badgeData, isAcquired: true));
        }
      }

      if (mounted) {
        setState(() {
          _myBadges = loadedBadges;
        });
      }
    } catch (e) {
      debugPrint('뱃지 목록 로드 실패: $e');
    }
  }

  // 내 프로필 정보 로드
  Future<void> _loadUserProfile() async {
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

          // 장착 중인 뱃지 찾기
          if (data['badge_id'] != null) {
            final currentBadgeId = data['badge_id'].toString();
            try {
              // _myBadges 리스트에서 찾아서 설정
              _selectedBadge = _myBadges.firstWhere(
                    (b) => b.id == currentBadgeId,
              );
            } catch (e) {
              _selectedBadge = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
    }
  }

  // 이미지 업로드 함수
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

  // 저장 버튼 핸들러
  Future<void> _handleSave() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임을 입력해주세요.')),
        );
      }
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
        'badge_id': _selectedBadge?.id != null ? int.parse(_selectedBadge!.id) : null, // String ID -> Int 변환 주의
      }).eq('id', userId);

      // 완료 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );

        final data = ProfileEditData(
          nickname: _nicknameController.text,
          profileImagePath: finalImageUrl,
          selectedBadge: _selectedBadge,
        );
        widget.onSave?.call(data);

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('저장 실패 상세: $e');
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

  // 뱃지 선택 다이얼로그 (획득한 뱃지만 표시)
  void _showBadgeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('보유 뱃지 목록'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 뱃지 해제 옵션
                RadioListTile<UserBadge?>(
                  title: const Text('장착 해제'),
                  value: null,
                  groupValue: _selectedBadge,
                  onChanged: (value) {
                    setState(() => _selectedBadge = value);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),

                // 획득한 뱃지 목록 표시
                if (_myBadges.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("획득한 뱃지가 없습니다.\n열심히 활동해서 뱃지를 모아보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._myBadges.map((badge) {
                    return RadioListTile<UserBadge>(
                      title: Text(badge.name),
                      subtitle: Text(badge.description, style: const TextStyle(fontSize: 12)),
                      value: badge,
                      groupValue: _selectedBadge,
                      onChanged: (value) {
                        setState(() => _selectedBadge = value);
                        Navigator.pop(context);
                      },
                      secondary: Image.asset(
                        badge.assetPath,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.stars, size: 40, color: Colors.amber),
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
      backgroundColor: Colors.white,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때 표시
          : SingleChildScrollView(
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
    if (_newProfileImagePath != null) {
      imageProvider = FileImage(File(_newProfileImagePath!));
    } else if (_serverProfileImageUrl != null && _serverProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_serverProfileImageUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/profile.jpg');
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageProvider,
          child: imageProvider == null ? const Icon(Icons.person, size: 70) : null,
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
        const Text('닉네임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildBadgeSection() {
    final badge = _selectedBadge;

    final leadingWidget = badge != null
        ? Image.asset(
      badge.assetPath,
      width: 40,
      height: 40,
      errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.stars, size: 40, color: Colors.amber),
    )
        : const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('대표 뱃지 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          title: Text(badge?.name ?? '선택된 뱃지 없음'),
          subtitle: Text(
            badge?.description ?? '보유한 뱃지 중 하나를 선택해 프로필에 뽐내보세요!',
            style: TextStyle(color: badge == null ? Colors.grey : Colors.black87),
          ),
          leading: leadingWidget,
          trailing: const Icon(Icons.edit),
          onTap: _showBadgeSelectionDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          tileColor: Colors.white,
        ),
      ],
    );
  }
}