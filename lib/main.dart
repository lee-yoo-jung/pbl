import 'package:flutter/material.dart';
import 'package:pbl/screen/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pbl/tap/mypages/component/notification_service.dart'; //알림 설정 파일
import 'package:supabase_flutter/supabase_flutter.dart';

// <최종 실행 파일 실행>

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Supabase.initialize(
    url: 'https://fjswddefchdhivkvpffh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqc3dkZGVmY2hkaGl2a3ZwZmZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODUwNDEsImV4cCI6MjA3Mzg2MTA0MX0.tQZfbh8PhcmnhWwtTQCSDiu_W9Au4pZA-lGDNz5wddE',
  );
  await initializeDateFormatting();           //다국적화
  await NotificationService().init();         // 알림 서비스 초기화

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