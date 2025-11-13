import 'package:flutter/material.dart';
import 'package:calendar_scheduler/services/friend_service.dart';
import 'package:calendar_scheduler/models/app_user.dart';

// 친구 검색 화면 위젯
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  String _searchQuery = '';
  final FriendService _friendService = FriendService();
  List<AppUser> _searchResults = [];
  bool _isLoading = false;

  // 검색 로직
  void _performSearch(String query) async {
    setState(() {
      _searchQuery = query.toLowerCase();
      _isLoading = true;
    });

    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await _friendService.searchUsers(_searchQuery);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류 발생: $e')),
        );
      }
    }
  }

  // 검색 입력 위젯
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: _performSearch,
          decoration: const InputDecoration(
            hintText: '친구 이름이나 아이디 또는 목표 유형으로 검색',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.search, size: 30),
        title: const Text('친구 검색'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          _buildSearchBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('검색어를 입력해주세요.'));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return FriendListItem(user: _searchResults[index]);
      },
    );
  }
}

// 친구 목록 항목 위젯
class FriendListItem extends StatefulWidget {
  final AppUser user;

  const FriendListItem({required this.user, super.key});

  @override
  State<FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends State<FriendListItem> {
  bool _isLoading = false;
  bool _requestSent = false;
  final FriendService _friendService = FriendService();

  // 목표 유형 칩
  Widget _buildGoalTypeChip(String type) {
    return Container(
      margin: const EdgeInsets.only(right: 6.0, bottom: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        '#$type',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 친구 요청 보내기 함수
  void _sendFriendRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _friendService.sendFriendRequest(widget.user.id);
      setState(() {
        _requestSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.user.nickname}님에게 친구 요청을 보냈습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('요청 실패: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeBackgroundColor = Colors.grey[200];
    const gradeTextColor = Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.nickname,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                //변경(아이디 항상 표시)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                  child: Text(
                    '@${widget.user.userId}', // @를 붙여서 아이디임을 강조
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),


                if (widget.user.goalTypes.isNotEmpty)
                  Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: widget.user.goalTypes
                        .take(3)
                        .map((type) => _buildGoalTypeChip(type))
                        .toList(),
                  )
                else
                  //변경
                  const SizedBox(height: 10), // 목표 유형이 없을 경우 빈 공간으로 대체
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 등급 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: gradeBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv. ${widget.user.level}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: gradeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 친구 추가 버튼
          SizedBox(
            width: 85,
            child: ElevatedButton(
              onPressed: _isLoading || _requestSent ? null : _sendFriendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _requestSent ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                _requestSent ? '요청됨' : '친구 추가',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}