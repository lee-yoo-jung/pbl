import 'package:flutter/material.dart';
import 'package:pbl/screen/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// <최종 실행 파일 실행>

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  //플러터 프레임워크 준비 대기
  await initializeDateFormatting();           //다국적화
  runApp(
    MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko','KR'),
      ],
      debugShowCheckedModeBanner: false, //debug 표시 제거
      home:MainScreen(),  //최종 실행 파일
    )
  );
}