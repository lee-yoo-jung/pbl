import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 모바일 환경에서는 아래와 같이 image_picker 패키지를 추가
// import 'package:image_picker/image_picker.dart';  (모바일에서 실행할 때 주석 제거)

// 현재 사용자의 더미 정보 (게시물 작성 시 사용)
const String _currentUserName = '나';
const String _currentGoalName = '홈트레이닝';

// Data Model (데이터 모델)

// 게시물 데이터를 위한 모델
class Post {
  final String userName; // 작성자 이름 (내부 로직용)
  final String goalName; // 목표 이름
  final String date; // 작성 날짜
  final String? imageUrl; // 이미지 URL (사진이 없으면 null)
  int supportCount; // 통합 응원 횟수
  final Set<String> supportedUsers; // 응원한 사용자 목록 (중복 방지)

  Post({
    required this.userName,
    required this.goalName,
    required this.date,
    this.imageUrl,
    this.supportCount = 0,
    Set<String>? supportedUsers, // 생성자에서 옵션으로 받음
  }) : supportedUsers = supportedUsers ?? {}; // null이면 빈 Set으로 초기화

  // 게시판에 표시될 고정된 형태의 텍스트
  String get displayMessage {
    return '$goalName 목표를 완료했습니다.';
  }
}



class GoalBoardApp extends StatefulWidget {
  const GoalBoardApp({super.key});

  @override
  State<GoalBoardApp> createState() => _GoalBoardAppState();
}

class _GoalBoardAppState extends State<GoalBoardApp> {
  // 앱 전체의 게시물 리스트 (더미 데이터 포함)
  List<Post> posts = [
    // 내가 올린 게시물 (오른쪽 정렬 테스트용)
    Post(
      userName: _currentUserName,
      goalName: _currentGoalName,
      date: '2025.11.06 5:00 PM',
      imageUrl: 'https://placehold.co/600x400/808080/FFFFFF?text=나의+운동+인증',
      supportCount: 5,
      supportedUsers: {'친구1', '친구2'}, // 내가 응원하지 않은 상태
    ),
    // 다른 친구가 올린 게시물 (왼쪽 정렬 테스트용)
    Post(
      userName: '지우개',
      goalName: '운영체제 공부',
      date: '2025.11.06 7:00 PM',
      imageUrl: 'https://placehold.co/600x400/e0e0e0/000000?text=친구+공부+인증',
      supportCount: 3,
      supportedUsers: {_currentUserName, '친구1'}, // 내가 이미 응원한 상태
    ),
    // 내가 올린 텍스트 전용 게시물 (오른쪽 정렬 테스트용)
    Post(
      userName: _currentUserName,
      goalName: '알고리즘 공부',
      date: '2025.11.06 5:00 PM',
      imageUrl: null,
      supportCount: 1,
      supportedUsers: {}, // 응원 없음
    ),
  ];

  void _addPost(Post newPost) {
    setState(() {
      // 새로운 게시물을 리스트 가장 앞에 추가
      posts.insert(0, newPost);
    });
  }

  // 게시물 응원 카운트를 업데이트하는 함수
  void _updateSupportCount(Post post) {
    // 이미 현재 사용자가 응원했는지 확인
    if (post.supportedUsers.contains(_currentUserName)) {
      // 이미 응원했으면 아무것도 하지 않고 종료
      return;
    }

    setState(() {
      post.supportCount++;
      // 현재 사용자를 응원 목록에 추가하여 중복 응원 방지
      post.supportedUsers.add(_currentUserName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공동 목표 게시판',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // 시작 경로를 게시물 작성 화면으로 변경
      initialRoute: '/create',
      routes: {
        '/board': (context) => BoardScreen(posts: posts, updateSupportCount: _updateSupportCount),
        '/create': (context) => PostCreationScreen(
          addPost: _addPost,
          userName: _currentUserName,
          goalName: _currentGoalName,
        ),
      },
    );
  }
}





// Post Creation Screen

class PostCreationScreen extends StatefulWidget {
  final Function(Post) addPost;
  final String userName;
  final String goalName;

  const PostCreationScreen({
    super.key,
    required this.addPost,
    required this.userName,
    required this.goalName,
  });

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

// 이 함수를 별도의 서비스 파일로 분리하고 백엔드와 연동
// 현재는 서버 연동이 불가능하므로, 더미 URL을 반환하는 함수로 대체
Future<String> _uploadImageToServer(String filePath) async {
  // 백엔드 연동을 위한 더미 지연 시간
  await Future.delayed(const Duration(seconds: 1));

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  // 실제 서버에 업로드 후, 서버가 반환하는 실제 이미지 URL을 시뮬레이션
  return 'https://actual-server.com/images/uploaded_photo_$timestamp.jpg';
}


class _PostCreationScreenState extends State<PostCreationScreen> {
  // 실제 파일 경로 대신, 게시판에 표시할 URL을 저장
  String? _selectedImageUrl;
  bool _onlyCheckMode = false; // Only Check 모드 여부

  // 모바일 환경에서 image_picker를 사용하여 실제 이미지를 선택하는 로직
  void _selectImage(String type) async {



    // ********* [모바일 (Android/iOS) 환경 실제 로직] *********
    // ----------------------------------------------------
    // 이 코드는 모바일 환경에서만 작동하며, image_picker 패키지가 필요
    // ----------------------------------------------------

    // final ImagePicker picker = ImagePicker();
    // XFile? file = await picker.pickImage(
    //   source: type == 'camera' ? ImageSource.camera : ImageSource.gallery,
    // );

    // if (file != null) {
    //   // 여기서 file.path 또는 file.bytes를 사용하여 이미지를 서버에 업로드
    //   final actualImageUrl = await _uploadImageToServer(file.path);
    //   setState(() {
    //     _selectedImageUrl = actualImageUrl;
    //     _onlyCheckMode = false;
    //   });
    //   return;
    // }



    // ********* [현재 웹 환경 시뮬레이션 로직 - 모바일 테스트 전까지 사용] *********

    // 실제 모바일 환경 테스트 시에는 아래 로직은 제거하거나 주석 처리
    setState(() {
      // 새로운 게시물마다 다른 URL을 생성하여 캐시를 방지하고 고유한 사진처럼 보이게 함
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backgroundColor = type == 'camera' ? 'FF5733' : '33FF5E'; // 카메라: 오렌지, 갤러리: 연두
      final text = type == 'camera' ? '카메라 인증' : '갤러리 첨부';

      final dummyUrl = 'https://placehold.co/600x400/$backgroundColor/ffffff?text=$text ($timestamp)';

      _selectedImageUrl = dummyUrl;
      _onlyCheckMode = false; // 이미지를 선택하면 Only check 모드 해제
    });
  }

  // Only Check 모드 설정
  void _toggleOnlyCheck() {
    setState(() {
      _onlyCheckMode = !_onlyCheckMode;
      if (_onlyCheckMode) {
        _selectedImageUrl = null; // Only check 모드 시 이미지 해제
      }
    });
  }

  // 게시물 확인 및 추가
  void _confirmPost() {
    final now = DateTime.now();
    final newPost = Post(
      userName: widget.userName,
      goalName: widget.goalName,
      date: '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      // _selectedImageUrl에는 이제 URL 또는 null이 저장
      imageUrl: _onlyCheckMode ? null : _selectedImageUrl,
      // 새 게시물이므로 supportedUsers는 빈 Set으로 시작
      supportedUsers: {},
    );

    widget.addPost(newPost);
    // 게시물 추가 후 게시판 화면으로 이동하고, 현재 작성 화면을 스택에서 제거
    Navigator.pushNamedAndRemoveUntil(context, '/board', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // 닉네임과 목표 이름은 여기서 보여주기만 함
    final displayMessage = '${widget.goalName} 목표를 완료했습니다.';
    final isImageAttached = _selectedImageUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물 작성'),
        // 작성 화면에서는 취소 버튼만 남김 (이전 목표 체크 화면이 없으므로 앱을 닫는 역할)
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. 고정된 게시글 텍스트 표시
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Text(
                displayMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 2. 사진 첨부 영역
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: _onlyCheckMode
                    ? Colors.grey[200]
                    : (isImageAttached ? Colors.blue.shade50 : Colors.grey[300]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(
                child: _onlyCheckMode
                    ? const Text('텍스트 전용 게시물',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isImageAttached ? Icons.check_circle_outline : Icons.add_a_photo,
                      color: isImageAttached ? Colors.blue.shade400 : Colors.grey,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isImageAttached ? '사진 첨부 완료 (모바일에서는 image_picker 연동)' : '사진 첨부',
                      style: TextStyle(
                          color: isImageAttached ? Colors.blue.shade600 : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // 3. Only Check 버튼
            ElevatedButton(
              onPressed: _toggleOnlyCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: _onlyCheckMode ? Colors.blue.shade100 : Colors.grey.shade200,
                foregroundColor: _onlyCheckMode ? Colors.blue.shade700 : Colors.grey.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Only check ${_onlyCheckMode ? '' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30.0),

            // 4. 확인 및 취소 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 확인 버튼 (게시판으로 이동)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 2,
                    ),
                    child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                // 취소 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 2,
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // 5. 사진 촬영/선택 옵션
            const Divider(),
            _PhotoOptionTile(
              icon: Icons.camera_alt,
              title: '사진 촬영하기',
              onTap: () => _selectImage('camera'),
            ),
            _PhotoOptionTile(
              icon: Icons.photo_library,
              title: '내 사진첩에서 선택하기',
              onTap: () => _selectImage('gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

// 사진 옵션 타일 위젯 (PostCreationScreen에서 사용)
class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PhotoOptionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 28),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

// 4. Board Screen (게시판 화면)

class BoardScreen extends StatelessWidget {
  final List<Post> posts;
  final Function(Post) updateSupportCount;

  const BoardScreen({super.key, required this.posts, required this.updateSupportCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'), // 제목 변경
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // 화살표 아이콘
          onPressed: () {
            // 게시물 작성 화면으로 이동 (임시)
            // 실제로는 캘린더 탭으로 가야함
            Navigator.pushNamed(context, '/create');
          },
        ),
        actions: const [
          SizedBox(width: 10), // AppBar의 오른쪽 여백을 맞추기 위해 추가
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostItem(
            post: post,
            onSupport: () => updateSupportCount(post),
          );
        },
      ),
    );
  }
}

// 개별 게시물 위젯 (정렬 로직 유지)
class PostItem extends StatelessWidget {
  final Post post;
  final VoidCallback onSupport;

  const PostItem({super.key, required this.post, required this.onSupport});

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null;
    final isTextOnly = !hasImage;

    // 1. 게시물 정렬 방향 결정
    final isMyPost = post.userName == _currentUserName;
    final alignment = isMyPost ? Alignment.centerRight : Alignment.centerLeft;
    final crossAxisAlignment = isMyPost ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // 응원 상태 확인 및 버튼 액션 결정
    final bool hasSupported = post.supportedUsers.contains(_currentUserName);
    final VoidCallback? supportAction = hasSupported ? null : onSupport; // 응원했으면 null (비활성화)

    // 2. 말풍선 모양을 위한 BorderRadius 설정 (정렬 방향에 따라 뾰족한 부분 위치 변경)
    final bubbleDecoration = BoxDecoration(
      color: isTextOnly ? Colors.grey[100] : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: isMyPost ? const Radius.circular(20) : const Radius.circular(5),
        bottomRight: isMyPost ? const Radius.circular(5) : const Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    );

    return Align(
      alignment: alignment, // 정렬 적용
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75, // 최대 너비 제한
          ),
          child: Column(
            crossAxisAlignment: crossAxisAlignment, // 응원 버튼과 텍스트 정렬 적용
            children: [
              // 친구 이름 (내가 올린 게시물이 아닐 때만 표시)
              if (!isMyPost)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                  child: Text(
                    post.userName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ),

              Container(
                decoration: bubbleDecoration,
                child: Padding(
                  padding: isTextOnly ? const EdgeInsets.all(15.0) : EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 이미지 영역
                      if (hasImage)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            height: 150,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey,
                              child: const Center(child: Text('이미지 로드 실패 또는 더미 이미지')),
                            ),
                          ),
                        ),
                      // 2. 텍스트 및 날짜 영역
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.displayMessage,
                              style: TextStyle(
                                fontSize: 15,
                                color: isTextOnly ? Colors.black : Colors.black87,
                                fontWeight: isTextOnly ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              post.date,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 3. 응원하기 버튼
              InkWell(
                onTap: supportAction, // 한 번만 응원 가능 (supportAction이 null이면 비활성화)
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    // 응원 상태에 따라 배경색 변경
                    color: hasSupported ? Colors.blue.shade100 : Colors.white, // 변경된 부분
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      // 응원 상태에 따라 테두리 색상 변경
                        color: hasSupported ? Colors.blue.shade300 : Colors.grey.shade300
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👍', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text('${post.supportCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      // 응원 상태에 따라 텍스트 변경
                      Text(
                          hasSupported ? '응원 완료' : '응원하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            // 비활성화 시 색상 어둡게 처리
                            color: hasSupported ? Colors.blue.shade700 : Colors.black,
                          )
                      ),
                    ],
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