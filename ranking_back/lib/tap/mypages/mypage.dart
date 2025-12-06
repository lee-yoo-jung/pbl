import 'package:flutter/material.dart';
import 'package:pbl/tap/mypages/component/GoalTypeSetting.dart';
import 'package:pbl/tap/mypages/component/PwChange.dart';
import 'package:pbl/tap/mypages/component/chart/showchart.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/mypages/component/goal_all.dart';
import 'package:pbl/tap/mypages/component/notification_service.dart';
import 'package:pbl/tap/mypages/component/profile_edit.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/login/login_app.dart';

final supabase = Supabase.instance.client;

class MyPage extends StatefulWidget {
  final bool isRankingPublic;
  final ValueChanged<bool> onRankingChanged;

  const MyPage({
    super.key,
    required this.isRankingPublic,
    required this.onRankingChanged,
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin {
//현재 보여줄 화면을 관리하는 상태 변수. null이면 기본 프로필 화면.
  Widget? _currentDetailView;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  // 백엔드 데이터
  String _nickname = '사용자';
  String _email = '';
  int _level = 1;
  int _exp = 0;
  List<String> _goalTypes = [];
  String? _avatarUrl;

  bool _isProfilePublic = true;
  bool _isRankingPublic = true;

  // 목표 리스트
  List<Map<String, dynamic>> _ongoingGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];

  // 알림 스위치 상태 변수
  bool _isNotificationEnabled = false;

  //상세 페이지로 "내부 화면 전환"을 하는 함수
  // void _pushDetailView(Widget view) {
  //   setState(() {
  //     _currentDetailView = view;
  //   });
  // }

  // 데이터 로드 함수
  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // USERS 테이블 조회
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // GOALS 테이블 조회
      final goalsData = await supabase
          .from('goals')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _email = user.email ?? '';
        _nickname = userData['nickname'] ?? '사용자';
        _level = userData['level'] ?? 1; // null이면 1
        _exp = userData['exp'] ?? 0;
        _avatarUrl = userData['avatar_url'];
        _isProfilePublic = userData['is_profile_public'] ?? true;
        _isRankingPublic = userData['is_ranking_public'] ?? true;

        if (userData['goal_types'] != null) {
          _goalTypes = List<String>.from(userData['goal_types']);
        }

        // 목표 분류 로직
        // completed_at이 null이면 진행중, 값이 있으면 완료됨
        _ongoingGoals = List<Map<String, dynamic>>.from(
            goalsData.where((g) => g['completed_at'] == null));

        _completedGoals = List<Map<String, dynamic>>.from(
            goalsData.where((g) => g['completed_at'] != null));
      });
    } catch (e) {
      debugPrint('마이페이지 데이터 로드 에러: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 프로필 공개 설정 업데이트
  Future<void> _updateProfilePrivacy(bool value) async {
    setState(() {
      _isProfilePublic = value;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({'is_profile_public': value})
            .eq('id', user.id);

        debugPrint('프로필 공개 설정 저장 완료: $value');
      }
    } catch (e) {
      debugPrint('설정 저장 실패: $e');
      setState(() {
        _isProfilePublic = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 저장에 실패했습니다.')),
      );
    }
  }

  // 랭킹 보기 설정 업데이트
  Future<void> _updateRankingPrivacy(bool value) async {
    setState(() {
      _isRankingPublic = value;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({'is_ranking_public': value})
            .eq('id', user.id);

        debugPrint('랭킹 보기 설정 저장 완료: $value');
        widget.onRankingChanged(value);
      }
    } catch (e) {
      debugPrint('설정 저장 실패: $e');
      setState(() {
        _isProfilePublic = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 저장에 실패했습니다.')),
      );
    }
  }

  // 로그아웃 함수
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      // 로그아웃 후 로그인 화면(MainScreen)으로 이동하고 스택 비우기
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginApp()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  // 실제 탈퇴는 DB에서 users 테이블 삭제 로직 등이 필요
  Future<void> _deleteAccount() async {
    // 여기에 탈퇴 API 호출 (Supabase Edge Function 등)
    // 지금은 로그아웃과 동일하게 처리
    await _signOut();
  }


  // 로그아웃 또는 탈퇴 시 팝업을 표시하는 함수
  void _showConfirmationDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(title),
              onPressed: () {
                print('$title 실행');
                Navigator.of(context).pop(); // 팝업 닫기
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentDetailView != null) {
          setState(() {
            _currentDetailView = null;
          });
          return false; // 앱 종료 방지
        }
        return true; // 기본 프로필 화면에서는 앱 종료 허용 (또는 이전 화면으로 이동)
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.person, size: 30),
          title: const Text("마이페이지",
            style: TextStyle(
              color: PRIMARY_COLOR,
              fontSize: 20,
              fontFamily: 'Pretendard-Regular',
              fontWeight: FontWeight.w700,
            ),
          ),
          toolbarHeight: 50.0,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(), // Body를 별도 함수로 분리
        backgroundColor: Colors.grey[100],
      ),
    );
  }

  // 현재 상태에 맞는 Body를 반환하는 함수
  Widget _buildBody() {
  // _currentDetailView가 null이 아니면 상세 페이지 위젯을, null이면 기본 프로필 화면을 보여줌
    return _currentDetailView ?? ListView(
      padding: const EdgeInsets.all(0.0),
      children: <Widget>[
        _buildProfileSection(),
        const SizedBox(height: 8),
        _buildCompletedGoalsSection(),
        const SizedBox(height: 10),
        _buildSettingsSection(),
      ],
    );
  }

  // 뱃지 적용 했는지
  bool hasBadge = false;

  // 프로필 정보 위젯
  Widget _buildProfileSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름, 목표 유형, 편집 버튼
          Row(
            children: [
              // 프로필 이미지 (avatar_url)
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),

              // 닉네임
              Text(_nickname,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),

              // 목표 유형 칩 (최대 2개 표시)
              ..._goalTypes.take(2).map((type) => Row(
                children: [
                  _buildGoalTypeChip(type),
                  const SizedBox(width: 4),
                ],
              )),

              const Spacer(),

              // 편집 창으로 이동
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileEditUI()),
                  ).then((_) => _fetchUserData());
                },
                child: const Text('편집', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 등급, 경험치, 진행중인 목표
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 등급 이미지
              Image.asset('assets/images/badge3.png', width: 80, height: 80),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('레벨: $_level', style: TextStyle(
                      fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('인기스타', style: TextStyle(
                      fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('EXP: $_exp/500',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_exp % 500) / 500,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('진행중인 목표',
                        style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
                    // 진행 중인 목표 리스트 (DB 연동)
                    if (_ongoingGoals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("진행 중인 목표가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    else
                      ..._ongoingGoals.take(3).map((g) => _buildGoalItem(g['title'] ?? '')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 완료한 목표 위젯
  Widget _buildCompletedGoalsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('완료한 목표',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',)),

              // 더보기 창으로 이동
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GoalAll()),
                  ).then((_) => _fetchUserData());
                },
                child: const Text('더보기', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          if (_completedGoals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("완료된 목표가 없습니다.", style: TextStyle(color: Colors.grey)),
            )
          else
            ..._completedGoals.take(3).map((g) => _buildGoalItem(g['title'] ?? '')),

          const Divider(height: 20),
          // 목표 데이터 분석
          InkWell(
            onTap: () {
              /* 목표 데이터 분석 화면으로 이동 */
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => chart()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('목표 데이터 분석', style: TextStyle(fontSize: 15)),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. 설정 및 기타 위젯
  Widget _buildSettingsSection() {

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아이디', style: TextStyle(fontSize: 16, color: Colors.grey)),
          // 수정 불가능한 아이디
          const SizedBox(height: 10),
          _buildSettingsItem(
            text: '비밀번호 변경',
            onTap: () {
              /* 비밀번호 변경 화면으로 이동 */
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordChangePage()),
              );
            },
          ),
          _buildSettingsItem(
            text: '프로필 공개',
            trailing: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _isProfilePublic,
                onChanged: (value) {
                  setState(() {
                    _updateProfilePrivacy(value);
                  });
                },
                activeColor: Colors.black,
                activeTrackColor: Colors.black54.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ),
            onTap: null, // Switch가 있으므로 Row 전체의 onTap은 비활성화
          ),
          _buildSettingsItem(
            text: '목표 유형 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalTypeSelectorPage()),
              );
            },
          ),

          //알림 스위치로 변경
          _buildSettingsItem(
            text: '알림', // 텍스트 변경
            trailing: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _isNotificationEnabled,
                onChanged: (value) async {
                  setState(() {
                    _isNotificationEnabled = value;
                  });

                  await NotificationService().setNotificationEnabled(value);

// 안내 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? '알림이 설정되었습니다.' : '알림이 해제되었습니다.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                activeColor: Colors.black,
                activeTrackColor: Colors.black54.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ),
            onTap: null, // 스위치로 직접 동작하므로 탭 이벤트는 비활성화
          ),

          // '랭킹' 스위치 항목 추가
          _buildSettingsItem(
            text: '랭킹 보기', // 항목 이름
            trailing: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _isRankingPublic,
                onChanged: (value) {
                  _updateRankingPrivacy(value);
                },
                activeColor: Colors.black,
                activeTrackColor: Colors.black54.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ),
            onTap: null, // 스위치 자체가 상호작용하므로 Row 전체의 탭은 비활성화
          ),

          const Divider(height: 20),
          _buildSettingsItem(
            text: '로그아웃',
            textColor: Colors.red,
            onTap: () => _showConfirmationDialog('로그아웃', '로그아웃 하시겠습니까?', _signOut),
          ),
          _buildSettingsItem(
            text: '탈퇴',
            textColor: Colors.red,
            onTap: () => _showConfirmationDialog('탈퇴', '탈퇴 하시겠습니까?', _deleteAccount),
          ),
          SizedBox(height: 80,),
        ],
      ),
    );
  }

// ---

// 각 섹션의 기본 컨테이너 스타일
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
      ),
      child: child,
    );
  }

// 목표 유형 칩 스타일
  Widget _buildGoalTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
          label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

// 목표 리스트 아이템 스타일
  Widget _buildGoalItem(String goal) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Text('•', style: TextStyle(
            color: Colors.grey, fontFamily: 'Pretendard-Medium',
            fontWeight: FontWeight.w700,)),
          const SizedBox(width: 8),
          Text(goal, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

// 설정 메뉴 아이템 스타일
  Widget _buildSettingsItem({
    required String text,
    required VoidCallback? onTap,
    Widget? trailing,
    Color textColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(fontSize: 16, color: textColor)),
            trailing ?? Container(), // trailing 위젯이 없으면 빈 컨테이너
          ],
        ),
      ),
    );
  }
}