import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:pbl/board/ml.dart';
import 'package:pbl/board/board_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// 사진 인식 + 체크박스

class CheckingPhoto extends StatefulWidget {
  const CheckingPhoto({
    super.key,
  });
  @override
  State<CheckingPhoto> createState() => _CheckingPhoto();
}


class _CheckingPhoto extends State<CheckingPhoto> {
  String? selectedImageUrl;
  File? selectedImage;
  bool onlyCheckMode = false; // Only Check 모드 여부
  String? analysisResult; //사진 분석 결과

  ///사진 파일 DB 버킷에 업로드
  Future<String?> uploadImageToSupabase(String filePath) async {
    try {
      final file = File(filePath);  //업로드할 파일을 읽도록
      final fileName =  DateTime.now().millisecondsSinceEpoch.toString(); //업로드할 파일 이름을 생성

      // Supabase Storage images 버킷에 업로드
      final response = await supabase.storage.from('images').upload(fileName, file);

      // Public URL: 업로드한 파일의 공개 URL 생성
      final publicUrl = Supabase.instance.client.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  // 모바일 환경에서 image_picker를 사용하여 실제 이미지를 선택하는 로직
  Future<void> pickImage(ImageSource imageSource) async {

    final ImagePicker picker = ImagePicker();  //이미지 선택 도구
    final pickedFile = await picker.pickImage(source: imageSource);  //선택된 이미지

    if (pickedFile == null) return;

    //이미지 분석
    String resultCategory = await ImageAnalyzer.analyzeCategory(pickedFile.path);

    //업로드 시도
    final uploadedUrl = await uploadImageToSupabase(pickedFile.path);

    if (uploadedUrl == null) {
      // 업로드 실패 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 실패, 다시 시도해주세요')),
      );
      return;
    }

    setState(() {
      selectedImageUrl = uploadedUrl;       // 업로드한 이미지 경로
      selectedImage = File(pickedFile.path); // 이미지 저장
      analysisResult = resultCategory;  //분석한 카테고리 저장
      onlyCheckMode = false; //사진 업로드-> onlycheck는 거짓으로
    });
  }

  // Only Check 모드 설정
  void _toggleOnlyCheck() {
    setState(() {
      // 이미지 해제, onlycheck를 참으로, 전에 분석한 결과를 null로
      onlyCheckMode=true;
      selectedImageUrl = null;
      selectedImage=null;
      analysisResult=null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isImageAttached = selectedImageUrl != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 고정된 게시글 텍스트 표시
            Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: analysisResult == null?
                SizedBox(height: 10)
                    : Column(
                  children: [
                    Text("분석 결과: $analysisResult 사진" ),
                  ],
                )
            ),

            // 2. 사진 첨부 영역
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: onlyCheckMode
                    ? Colors.grey[200]
                    : (isImageAttached ? Colors.blue.shade50 : Colors.grey[300]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(
                child: onlyCheckMode
                    ? const Center(
                  child: Text('텍스트 전용 게시물',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                )
                    : selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15), // 모서리 둥글게
                  child: Image.file(
                    selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.scaleDown,
                  ),
                ) : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImageAttached ? Icons.check_circle_outline : Icons.add_a_photo,
                        color: isImageAttached ? Colors.blue.shade400 : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      if(isImageAttached && selectedImage == null)Icon(Icons.photo, color: Colors.grey), // 이미지 없을 때 아이콘
                      SizedBox(width: 8),
                      Text(
                        '사진 첨부',
                        style: TextStyle(
                          color: isImageAttached ? Colors.blue.shade600 : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // 3. Only Check 버튼
            ElevatedButton(
              onPressed: _toggleOnlyCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: onlyCheckMode ? Colors.blue.shade100 : Colors.grey.shade200,
                foregroundColor: onlyCheckMode ? Colors.blue.shade700 : Colors.grey.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Only check ${onlyCheckMode ? '' : ''}',
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
                    onPressed:() async{
                      debugPrint("버튼 눌림");


                      ///수파베이스 사용자 정보 및 저장 <테스트용>
                      var user = supabase.auth.currentUser; //현재 앱에 로그인 된 사용자의 정보
                      //없다면, 익명로그인
                      if (user == null) {
                        final res = await supabase.auth.signInAnonymously();
                        user = res.user;
                      }
                      // 프로필 확인
                      final profile = await supabase
                          .from('profiles')
                          .select()
                          .eq('id', user!.id)
                          .maybeSingle();
                      //프로필이 없다면, 새 프로필 생성
                      if (profile == null) {
                        await supabase.from('profiles').insert({
                          'id': user.id,
                          'username': 'anon_${user.id.substring(0, 6)}',
                        });
                      }


                      ///DB 저장
                      String content = '';

                      ///체크 모드이면 바로 저장 (이미지 없이)  content: 사용자의 계획으로
                      if (onlyCheckMode) {
                        //메시지 삽입
                        await supabase.from('messages').insert({
                          'user_id': user?.id,
                          'content': '내용',
                          'image_url': selectedImageUrl,
                          'category': analysisResult,
                          'is_verified': !onlyCheckMode,
                        });

                        debugPrint("사진 저장 안함");

                        // SnackBar로 띄우기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "체크되었습니다.",
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        // 수파베이스 게시판으로 이동
                        Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => BoardPage()),
                        );
                        return;
                      }

                      ///사진 인증 실패  <'공부'에 사용자의 계획의 카테고리를 넣기>
                      if (!onlyCheckMode && analysisResult?.trim()!= '공부') {

                        await showDialog(
                          context: context,
                          builder:  (BuildContext context) {
                            return AlertDialog(
                              content: Text('인증되지 않았습니다. \n 계속하실가요? \n "아니요" 클릭 시, Only Check로 진행됩니다.'),
                              actions: [
                                TextButton(
                                  child: Text('아니요'),
                                  onPressed: () async {
                                    // OnlyCheck로 전환 + 사진 제거
                                    setState(() {
                                      onlyCheckMode = true;
                                      selectedImageUrl = null;
                                      selectedImage = null;
                                    });
                                    ///content: 사용자의 계획으로
                                    await supabase.from('messages').insert({
                                      'profile_id': user?.id,
                                      'content': "계획=운동 (임시-인증실패)",
                                      'image_url': null,
                                    });

                                    debugPrint('인증 실패하였습니다.');

                                    Navigator.pop(context); // 다이얼로그 닫기
                                    // 수파베이스 게시판으로 이동
                                    Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (_) => BoardPage()),
                                    );
                                  },
                                ),

                                //페이지에 남도록 다이얼로그만 닫기
                                TextButton(
                                    child: Text('예'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }
                                )
                              ],
                            );
                          },
                        );
                        return;
                      }

                      ///인식된 사진이 옳을 경우 = 정상 저장 <content: 사용자의 계획으로>
                      else{
                        // SnackBar로 띄우기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "인증되었습니다.",
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        ///이미지를 성공적으로 인식할 때 <content: 사용자의 계획으로>
                        content = "계획=공부 (임시메시지-인증완료)";
                      }
                      //메시지 삽입
                      await supabase.from('messages').insert({
                        'profile_id': user?.id,
                        'content': content,
                        'image_url': selectedImageUrl,
                      });

                      debugPrint("DB에 사진 저장됨");

                      // 수파베이스 게시판으로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => BoardPage()),
                      );
                    },

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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
              onTap: () => pickImage(ImageSource.camera),
            ),
            _PhotoOptionTile(
              icon: Icons.photo_library,
              title: '내 사진첩에서 선택하기',
              onTap: () => pickImage(ImageSource.gallery),
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

