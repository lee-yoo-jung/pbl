import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/board/models/message.dart';
import 'package:pbl/tap/calender/board/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/services/badge_service.dart';

final supabase = Supabase.instance.client;

const preloader = Center(child: CircularProgressIndicator(color: Colors.orange));

class BoardPage extends StatefulWidget {
  const BoardPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const BoardPage(),
    );
  }

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {

  final Map<String, List<Map<String, dynamic>>> reactionsMap = {};
  final Map<String, Profile> profiles = {};

  List<String> allowedUserIds = [];

  late final StreamSubscription<List<Map<String, dynamic>>> messagesSub;
  late final StreamSubscription<List<Map<String, dynamic>>> reactionsSub;

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    initBoard();
  }

  @override
  void dispose() {
    messagesSub.cancel();
    reactionsSub.cancel();
    super.dispose();
  }

  // 나와 친구들의 ID 리스트를 가져오는 함수
  Future<void> _fetchMyAndFriendIds(String myId) async {
    try {
      // 친구 목록 조회
      final response = await supabase
          .from('friends')
          .select('requester_id, receiver_id')
          .eq('status', 'accepted')            // 친구 수락된 상태만
          .or('requester_id.eq.$myId,receiver_id.eq.$myId');

      final List<String> friendIds = [];

      for (var row in response) {
        final reqId = row['requester_id'].toString();
        final recId = row['receiver_id'].toString();

        if (reqId == myId) {
          friendIds.add(recId);
        } else {
          friendIds.add(reqId);
        }
      }

      final uniqueIds = {myId, ...friendIds}.toList();

      if (mounted) {
        setState(() {
          allowedUserIds = uniqueIds;
        });
      }

      debugPrint("허용된 ID 목록(나+친구): $allowedUserIds");

    } catch (e) {
      debugPrint('친구 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          allowedUserIds = [myId];
        });
      }
    }
  }

  Future<void> initBoard() async {
    final myUserId = supabase.auth.currentUser!.id;

    // 친구 ID 목록 먼저 가져오기
    await _fetchMyAndFriendIds(myUserId);

    // 초기 메시지 불러오기
    final msgRes = await supabase
        .from('messages')
        .select('id, user_id, content, image_url, created_at')
        .inFilter('user_id', allowedUserIds)
        .order('created_at', ascending: false);

    setState(() {
      messages = (msgRes as List)
          .map((m) => Message.fromMap(map: m, myUserId: myUserId))
          .toList();
    });

    for (var msg in messages) {
      loadProfile(msg.userId);
    }

    // 초기 리액션 불러오기
    try {
      final reactRes = await supabase.from('message_reactions').select();
      for (var r in reactRes) {
        final msgId = r['message_id'].toString();
        final userId = r['user_id'] as String;
        final emoji = r['emoji'] as String;

        final list = reactionsMap[msgId] ?? [];
        reactionsMap[msgId] = [
          ...list.where((e) => e['user_id'] != userId),
          {'user_id': userId, 'emoji': emoji},
        ];
      }
    } catch (e) {
      debugPrint('리액션 로드 에러: $e');
    }

    setState(() {});

    // 실시간 메시지 구독
    messagesSub = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .inFilter('user_id', allowedUserIds)
        .listen((newData) async{
      setState(() {
        messages = newData
            .map((m) => Message.fromMap(map: m, myUserId: myUserId))
            .toList();

        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

      for (var m in newData) {
        loadProfile(m['user_id']);
      }
    });

    // 실시간 리액션 구독
    try {
      reactionsSub = supabase
          .from('message_reactions')
          .stream(primaryKey: ['id'])
          .listen((data) {
        setState(() {
          reactionsMap.clear();
          for (var r in data) {
            final msgId = r["message_id"].toString();
            final list = reactionsMap[msgId] ?? [];
            reactionsMap[msgId] = [
              ...list.where((x) => x['user_id'] != r['user_id']),
              r,
            ];
          }
        });
      });
    } catch(e){
      debugPrint("리액션 구독 실패: $e");
    }
  }

  // 프로필 로드
  Future<void> loadProfile(String userId) async {
    if (profiles[userId] != null) return;

    try {
      final data = await supabase
          .from('users')
          .select('id, nickname, avatar_url')
          .eq('id', userId)
          .single();

      final profile = Profile.fromMap(data);
      if (mounted) {
        setState(() {
          profiles[userId] = profile;
        });
      }
    } catch (e) {
      profiles[userId] = Profile(id: userId, nickname: '알 수 없음');
    }
  }


  // 이모지 집계 위젯
  Widget Reactions(String messageId) {
    final reactions = reactionsMap[messageId] ?? [];
    if (reactions.isEmpty) return const SizedBox.shrink();

    final Map<String, int> emojiCount = {};
    for (var reat in reactions) {
      final emoji = reat['emoji']!;
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 50.0, right: 20.0),
      child: Wrap(
        spacing: 4,
        children:  emojiCount.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.all(5),
            child: Text(
              '${entry.key} ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
            decoration: BoxDecoration(
              border: Border.all(color:Colors.grey, width: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 이모지 선택 함수
  void EmojiTap(BuildContext parentContext, String messageId) {
    const List<String> emojis = ['❤️', '🔥', '😁', '😍', '👏', '👍', '💪'];

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        content: Container(
          width: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () async {
                  Navigator.of(dialogContext).pop();

                  final userId = supabase.auth.currentUser?.id;
                  if (userId == null) return;

                  String? receiverId;
                  try {
                    final targetMessage = messages.firstWhere((m) => m.id == messageId);
                    receiverId = targetMessage.userId;
                  } catch (e) {}

                  try {
                    final existing = await supabase
                        .from('message_reactions')
                        .select()
                        .eq('message_id', messageId)
                        .eq('user_id', userId)
                        .maybeSingle();

                    if (existing == null) {
                      await supabase.from('message_reactions').insert({
                        'message_id': messageId,
                        'user_id': userId,
                        'emoji': emoji,
                      });

                      if (parentContext.mounted && receiverId != null && receiverId != userId) {
                        await BadgeService().checkCheerBadges(parentContext, userId, receiverId);
                      }

                    } else {
                      await supabase.from('message_reactions')
                          .update({'emoji': emoji})
                          .eq('message_id', messageId)
                          .eq('user_id', userId);
                    }

                    if (mounted) {
                      final list = reactionsMap[messageId] ?? [];
                      setState(() {
                        reactionsMap[messageId] = [
                          ...list.where((e) => e['user_id'] != userId),
                          {'user_id': userId, 'emoji': emoji},
                        ];
                      });
                    }

                  } catch (e) {
                    debugPrint("리액션 저장 실패: $e");
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: Colors.white,

      body: Builder(
        builder: (innerContext) {
          return messages.isEmpty
              ? const Center(child: Text('친구들과 목표를 공유해보세요! :)'))
              : ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              loadProfile(message.userId);

              return GestureDetector(
                onTap: () => EmojiTap(innerContext, message.id),

                child: Column(
                  crossAxisAlignment: message.isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _ChatBubble(
                      message: message,
                      profile: profiles[message.userId],
                    ),
                    Reactions(message.id),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            profile?.nickname ?? '알 수 없음',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),

      const SizedBox(width: 12),
      Expanded(
        child: Align(
          alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: message.isMine? EdgeInsets.only(left: 80,top: 10):EdgeInsets.only(right: 50,top: 10),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: message.isMine
                  ? Colors.grey[200]
                  : Colors.grey[500],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                MessageImage(context,message.imageUrl),

                Text(message.content,
                    style: TextStyle(fontSize: 15,
                        color: message.isMine ? Colors.black:Colors.white)
                ),
                SizedBox(height: 10),

                Text('${message.createdAt.toLocal().toString().substring(0,16)}',
                    style: TextStyle(fontSize: 12,
                        color: message.isMine ? Colors.black:Colors.white)
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),

    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment:
        message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }

  Widget MessageImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context)=>AlertDialog(
                    content: Image.network(message.imageUrl!),
                  )
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Image.network(
                  imageUrl,
                  width: 270,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 50,
                      color: Colors.grey[300],
                      child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          )
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      height: 100,
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
            ),
          )
      );
    }
    return const SizedBox.shrink();
  }
}