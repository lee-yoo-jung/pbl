import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbl/board/models/message.dart';
import 'package:pbl/board/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

const preloader = Center(child: CircularProgressIndicator(color: Colors.orange));

class BoardPage extends StatefulWidget {
  const BoardPage({Key? key}) : super(key: key);

  //페이지 전환
  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const BoardPage(),
    );
  }

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {

  final Map<String, List<Map<String, dynamic>>> reactionsMap = {}; // 해당 메시지에 달린 리액션들의 리스트
  final Map<String, Profile> profiles = {};  //프로필 ID = DB에서 가져오는 대신에 캐시해서 성능최적화

  //메시지 실시간 변경 구독, 리액션 실시간 변경 구독
  late final StreamSubscription<List<Map<String, dynamic>>> messagesSub;
  late final StreamSubscription<List<Map<String, dynamic>>> reactionsSub;

  //메시지 리스트
  List<Message> messages = [];

  Future<void> initBoard() async {
    final myUserId = supabase.auth.currentUser!.id; //현재 로그인한 사용자 ID 가져오기

    // 초기 메시지 불러와서 messages에 저장(수파베이스의 messages 테이블의 메시지를 최신순으로)
    final msgRes = await supabase.from('messages').select().order('created_at', ascending: false);
    messages = (msgRes as List).map((m) => Message.fromMap(map: m, myUserId: myUserId)).toList();

    for (var msg in messages) {
      loadProfile(msg.userId);
    }


    //초기 리액션 불러와서 reactionsMap에 메시지별로 사용자, 이모지 저장
    final reactRes = await supabase.from('message_reactions').select();
    for (var r in reactRes) {
      final msgId = r['message_id'] as String;
      final userId = r['user_id'] as String;
      final emoji = r['emoji'] as String;

      //기존에 사용자의 리액션이 있다면, 제거 후에 새 이모지 추가
      final list = reactionsMap[msgId] ?? [];
      reactionsMap[msgId] = [
        ...list.where((e) => e['user_id'] != userId),
        {'user_id': userId, 'emoji': emoji},
      ];
    }

    setState(() {}); // 화면 렌더링

    // 실시간 메시지: 새 메시지가 들어오면 messages 리스트 갱신
    messagesSub = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((newData) async{
      setState(() {
        messages = newData
            .map((m) => Message.fromMap(map: m, myUserId: myUserId))
            .toList();

        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

      for (var m in newData) {
        loadProfile(m['profile_id']);
      }
    });

    //실시간 리액션: 새 리액션이 들어오면 reationsMap 갱신
    reactionsSub = supabase
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .listen((data) {
      setState(() {
        reactionsMap.clear();

        for (var r in data) {
          final msgId = r["message_id"];
          final list = reactionsMap[msgId] ?? [];

          reactionsMap[msgId] = [
            ...list.where((x) => x['user_id'] != r['user_id']),
            r,
          ];
        }
      });
    });
  }

  //초기 메시지, 실시간 리액션/메시지 시작
  @override
  void initState() {
    super.initState();
    initBoard();
  }


  //이모지 집계
  Widget Reactions(String messageId) {
    final reactions = reactionsMap[messageId] ?? [];  //메시지에 해당되는 리액션 리스트
    if (reactions.isEmpty) return const SizedBox.shrink();  //비어있으면 빈 공간 반환

    //리스트 순회하면서 같은 이모지 개수 계산
    final Map<String, int> emojiCount = {};
    for (var reat in reactions) {
      final emoji = reat['emoji']!;
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }

    //이모지들과 해당 개수를 가로로 나열
    return Padding(
      padding: const EdgeInsets.only(left: 50.0, right: 20.0),
      child: Wrap(
        spacing: 4,
        //각 이모지를 감싸서 화면에 표현하기
        children:  emojiCount.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.all(5),
            child: Text(
              '${entry.key} ${entry.value}',  // 이모지, 이모지의 숫자
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

  //이모지 선택화면
  void EmojiTap(BuildContext context, String messageId) {
    const List<String> emojis = ['❤️', '🔥','😁','😍','👏','👍','💪'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          width: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () async {
                  final userId = supabase.auth.currentUser?.id; //현재 사용자
                  if (userId == null) return;

                  // 이미 이모지가 있는지
                  final existing = await supabase
                      .from('message_reactions')
                      .select()
                      .eq('message_id', messageId)
                      .eq('user_id', userId)
                      .maybeSingle();

                  if (existing == null) {
                    // 없으면 새로 추가
                    await supabase.from('message_reactions').insert({
                      'message_id': messageId,
                      'user_id': userId,
                      'emoji': emoji,
                    });
                  } else {
                    // 있으면 업데이트
                    await supabase.from('message_reactions')
                        .update({'emoji': emoji})
                        .eq('message_id', messageId)
                        .eq('user_id', userId);
                  }

                  // 화면 즉시 반영
                  final list = reactionsMap[messageId] ?? [];
                  setState(() {
                    reactionsMap[messageId] = [
                      // 기존 사용자 리액션 제거
                      ...list.where((e) => e['user_id'] != userId),
                      // 변경한 리액션 추가
                      {'user_id': userId, 'emoji': emoji},
                    ];
                  });

                  Navigator.pop(context);
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

  //정보를 수파베이스에서 가져오기
  Future<void> loadProfile(String profileId) async {
    if (profiles[profileId] != null) return;  //중복 방지

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', profileId)
        .single();

    final profile = Profile.fromMap(data);
    setState(() {
      profiles[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: messages.isEmpty
          ? const Center(child: Text('Achieve Your Goal! :)'))
          : ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          loadProfile(message.userId);

          //채팅 버블 클릭 시, 이모지 탭 불러오기
          return GestureDetector(
            onTap: () => EmojiTap(context, message.id),
            child: Column(
              //본인은 왼쪽에, 상대방은 오른쪽에 채팅 버블 위치
              crossAxisAlignment: message.isMine?CrossAxisAlignment.end:CrossAxisAlignment.start,
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
      ),
    );
  }
}

//채팅 버블
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
      //내 메시지가 아닌 경우
      if (!message.isMine)
      //상대 프로필
        CircleAvatar(
          child: profile == null
              ? preloader //로딩 중 표시
              : Text(profile!.username.substring(0, 2)),  //사용자 이름 앞 2글자
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
                //이미지 있을 경우, 출력
                MessageImage(context,message.imageUrl),

                //포맷 메시지
                Text('${profile?.id}님이 \n${message.content}을 수행하셨습니다!',
                    style: TextStyle(fontSize: 15,
                        color: message.isMine ? Colors.black:Colors.white)
                ),
                SizedBox(height: 10),

                //게시한 날짜, 시간
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

  //이미지가 있는 경우
  Widget MessageImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.only(bottom: 8.0),
          //이미지 클릭 시, 볼 수 있게
          child: InkWell(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context)=>AlertDialog(
                    content: Image.network(message.imageUrl!),
                  )
              );
            },
            //글과 함께 이미지 보도록(미리보기)
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Image.network(
                  imageUrl,
                  width: 270,
                  height: 150, // 높이 지정
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    //로딩 완료 = 이미지 반환
                    if (progress == null) return child;
                    //로딩 중 = 회색 배경, 로딩 표시
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
                  //이미지 로딩 중, 에러 발생
                  errorBuilder: (context, error, stackTrace) {
                    //깨진 이미지 표시
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
    //이미지가 null이거나 empty인 경우/
    return const SizedBox.shrink();
  }
}