import 'package:calendar_scheduler/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

// <최종 실행 파일 실행>

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  //플러터 프레임워크 준비 대기
  await initializeDateFormatting();           //다국적화
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false, //debug 표시 제거
      home:HomeScreen(),  //최종 실행 파일
    )
  );
}