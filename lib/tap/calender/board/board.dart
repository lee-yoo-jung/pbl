import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pbl/tap/calender/board/ml.dart';
import 'package:pbl/tap/calender/board/board_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/services/level_service.dart';

final supabase = Supabase.instance.client;

// 사진 인식 + 체크박스
class CheckingPhoto extends StatefulWidget {
  final Plan todo;
  final bool isShared;

  const CheckingPhoto({
    required this.todo,
    required this.isShared,
    super.key,
  });
  @override
  State<CheckingPhoto> createState() => _CheckingPhoto();
}

class _CheckingPhoto extends State<CheckingPhoto> {
  String? selectedImageUrl;
  File? selectedImage;
  bool onlyCheckMode = false; // Only Check 모드 여부
  String? analysisResult; // 사진 분석 결과

  // 계획 완료 상태 DB 업데이트 로직 (개인/공유 구분 처리)
  Future<void> _updatePlanStatus(String planId) async {
    try {
      // 개인 계획(todos) 테이블 업데이트 시도
      final List<dynamic> response = await supabase
          .from('todos')
          .update({'is_completed': true})
          .eq('id', planId)
          .select();

      // todos 테이블에서 업데이트된 게 없다면(빈 리스트), 공유 계획(todos_shares)
      if (response.isEmpty) {
        await supabase
            .from('todos_shares')
            .update({'is_completed': true})
            .eq('id', planId);
        debugPrint("공유 계획(todos_shares) 완료 처리됨");
      } else {
        debugPrint("개인 계획(todos) 완료 처리됨");
      }
    } catch (e) {
      debugPrint("계획 업데이트 실패: $e");
    }
  }

  // 사진 파일 DB 버킷에 업로드
  Future<String?> uploadImageToSupabase(String filePath) async {
    try {
      final file = File(filePath);
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final fileExt = filePath.split('.').last;
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      return null;
    }
  }

  // 이미지 선택 로직
  Future<void> pickImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: imageSource);

    if (pickedFile == null) return;

    // 이미지 분석
    String resultCategory = await ImageAnalyzer.analyzeCategory(pickedFile.path);

    // 업로드 시도
    final uploadedUrl = await uploadImageToSupabase(pickedFile.path);

    if (uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 실패, 다시 시도해주세요')),
      );
      return;
    }

    setState(() {
      selectedImageUrl = uploadedUrl;
      selectedImage = File(pickedFile.path);
      analysisResult = resultCategory;
      onlyCheckMode = false;
    });
  }

  // Only Check 모드 설정
  void _toggleOnlyCheck() {
    setState(() {
      onlyCheckMode = true;
      selectedImageUrl = null;
      selectedImage = null;
      analysisResult = null;
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
            // 분석 결과 텍스트
            Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: analysisResult == null
                    ? const SizedBox(height: 10)
                    : Column(
                  children: [
                    Text("분석 결과: $analysisResult 사진"),
                  ],
                )),

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
                  child: Text(
                    '텍스트 전용 게시물',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                )
                    : selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.scaleDown,
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImageAttached ? Icons.check_circle_outline : Icons.add_a_photo,
                        color: isImageAttached ? Colors.blue.shade400 : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      if (isImageAttached && selectedImage == null)
                        const Icon(Icons.photo, color: Colors.grey),
                      const SizedBox(width: 8),
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
                'Only check',
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

                      String currentNickname = '알 수 없음';
                      try {
                        final user = supabase.auth.currentUser;
                        if (user != null) {
                          final data = await supabase
                              .from('users')
                              .select('nickname')
                              .eq('id', user.id)
                              .single();
                          currentNickname = data['nickname'] ?? '알 수 없음';
                        }
                      } catch(e) {
                        debugPrint("닉네임 로드 실패: $e");
                      }

                      String content = '';

                      // Only Check 모드
                      if (onlyCheckMode) {
                        content = '$currentNickname님이 ${widget.todo.text} 계획을 완료했습니다.';

                        // 메시지 삽입
                        await supabase.from('messages').insert({
                          'user_id': supabase.auth.currentUser?.id,
                          'content': content,
                          'image_url': null,
                        });

                        // 개인/공유 구분하여 업데이트
                        await _updatePlanStatus(widget.todo.id!);

                        if (mounted) {
                          await LevelService().grantExpForPlanCompletion(
                            context,
                            goalId: widget.todo.goalId ?? "",
                            isPhotoVerified: false,
                            isSharedGoal: widget.isShared,
                          );
                        }

                        setState(() {
                          widget.todo.isDone = true;
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BoardPage()));
                        }
                        return;
                      }

                      // 사진 인증 실패 시 처리
                      if (!onlyCheckMode && analysisResult?.trim() != widget.todo.hashtag) {
                        if (mounted) {
                          final navigatorContext = context;
                          await showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                content: const Text('인증되지 않았습니다.\n계속하시겠습니까?\n"아니요" 클릭 시, Only Check로 진행됩니다.',
                                  style: TextStyle(
                                    fontFamily: "Pretendard",
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  )
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('아니요'),
                                    onPressed: () async {
                                      // 개인/공유 구분하여 업데이트
                                      await _updatePlanStatus(widget.todo.id!);

                                      if (navigatorContext.mounted) {
                                        await LevelService().grantExpForPlanCompletion(
                                          navigatorContext,
                                          goalId: widget.todo.goalId ?? "",
                                          isPhotoVerified: false,
                                          isSharedGoal: false,
                                        );
                                      }

                                      setState(() {
                                        widget.todo.isDone = true;
                                      });

                                      // 실패 기록 메시지 저장
                                      await supabase.from('messages').insert({
                                        'user_id': supabase.auth.currentUser?.id,
                                        'content': "$currentNickname님이 ${widget.todo.text} 계획을 완료했습니다.",
                                        'image_url': null,
                                      });

                                      debugPrint('인증 실패 -> Only Check 전환 저장');

                                      if (mounted) {
                                        Navigator.pop(dialogContext);
                                        Navigator.of(navigatorContext).pushReplacement(
                                          MaterialPageRoute(builder: (_) => BoardPage()),
                                        );
                                      }
                                    },
                                  ),
                                  TextButton(
                                      child: const Text('예'),
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      })
                                ],
                              );
                            },
                          );
                        }
                        return;
                      }
                      // 인증 성공
                      else {
                        content = "$currentNickname님이 ${widget.todo.text} 계획을 완료했습니다.";

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
                        'user_id': supabase.auth.currentUser?.id,
                        'content': content,
                        'image_url': selectedImageUrl,
                      });

                      // 인증 성공 시에도 계획 완료 처리 필요
                      await _updatePlanStatus(widget.todo.id!);
                      setState(() {
                        widget.todo.isDone = true;
                      });

                      debugPrint("DB에 사진 및 인증 정보 저장됨");

                      if (mounted) {
                        await LevelService().grantExpForPlanCompletion(
                          context,
                          goalId: widget.todo.goalId ?? "",
                          isPhotoVerified: true,
                          isSharedGoal: widget.isShared,
                        );
                      }

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
}

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