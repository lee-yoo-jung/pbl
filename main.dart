import 'package:flutter/material.dart';
import 'package:pbl/screen/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pbl/tap/mypages/component/notification_service.dart'; //알림 설정 파일

// <최종 실행 파일 실행>

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  //플러터 프레임워크 준비 대기
  await initializeDateFormatting();           //다국적화
  await NotificationService().init();         // 알림 서비스 초기화
  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false, //debug 표시 제거
        home:MainScreen(),  //최종 실행 파일
      )
  );
}