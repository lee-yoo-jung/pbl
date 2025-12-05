import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:pbl/tap/calender/board/ml.dart';
import 'package:pbl/tap/calender/board/board_page.dart';
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
      final file = File(filePath);
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // 파일명 충돌 방지를 위해 타임스탬프 사용
      final fileExt = filePath.split('.').last;
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Supabase Storage 'images' 버킷에 업로드
      await supabase.storage.from('images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Public URL 생성
      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
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
            // 고정된 게시글 텍스트 표시
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

            // 사진 첨부 영역
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

            // Only Check 버튼
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

            // 확인 및 취소 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 확인 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint("버튼 눌림");

                      // 로그인된 사용자 정보 확인
                      final user = supabase.auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그인이 필요합니다.')),
                        );
                        return;
                      }

                      // DB에 저장할 변수들
                      String content = '';
                      String category = '기타';
                      bool isVerified = false;

                      // Only Check
                      if (onlyCheckMode) {
                        content = '오늘의 계획을 완료했습니다.';
                        category = '기타';
                        isVerified = false;

                        // 메시지 삽입
                        await supabase.from('messages').insert({
                          'user_id': user.id,
                          'content': content,
                          'image_url': null,
                          'category': category,
                          'is_verified': isVerified,
                        });

                        debugPrint("사진 저장 안함 (Only Check)");

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("체크되었습니다."),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          // 게시판으로 이동
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BoardPage()));
                        }
                        return;
                      }

                      // 사진 인증 실패
                      // 이후 수정
                      if (!onlyCheckMode && analysisResult?.trim() != '공부') {
                        if (mounted) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: const Text('인증되지 않았습니다.\n계속하시겠습니까?\n"아니요" 클릭 시, Only Check로 진행됩니다.'),
                                actions: [
                                  TextButton(
                                    child: const Text('아니요'),
                                    onPressed: () async {
                                      Navigator.pop(context); // 다이얼로그 닫기

                                      // OnlyCheck로 전환 및 실패 기록 저장
                                      await supabase.from('messages').insert({
                                        'user_id': user.id,
                                        'content': "계획=운동 (임시-인증실패)",
                                        'image_url': null,
                                        'category': '기타',
                                        'is_verified': false,
                                      });

                                      debugPrint('인증 실패 -> Only Check 전환 저장');

                                      if (mounted) {
                                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BoardPage()));
                                      }
                                    },
                                  ),
                                  TextButton(
                                      child: const Text('예'),
                                      onPressed: () {
                                        Navigator.pop(context); // 그냥 닫기 (화면 유지)
                                      }
                                  )
                                ],
                              );
                            },
                          );
                        }
                        return;
                      }

                      // 인증 성공
                      else {
                        content = "계획=공부";
                        category = analysisResult ?? '기타';
                        isVerified = true;

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("인증되었습니다."),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }

                      // 최종 메시지 삽입
                      await supabase.from('messages').insert({
                        'user_id': user.id,
                        'content': content,
                        'image_url': selectedImageUrl,
                        'category': category,
                        'is_verified': isVerified,
                      });

                      debugPrint("DB에 사진 및 인증 정보 저장됨");

                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => BoardPage()),
                        );
                      }
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

            // 사진 촬영/선택 옵션
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

  // messages 테이블에 insert
  Future<void> _saveMessageToDB(String userId, String content, String? imageUrl, String category, bool isVerified) async {
    try {
      await supabase.from('messages').insert({
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'category': category,
        'is_verified': isVerified,
      });
      debugPrint("DB 저장 성공");
    } catch (e) {
      debugPrint("DB 저장 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("저장 실패: $e")),
        );
      }
    }
  }

// 성공 메시지 및 화면 이동
  void _showSuccessAndNavigate(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BoardPage()),
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
