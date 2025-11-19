import 'package:flutter/material.dart';
import 'package:pbl_mid/screen/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

// <최종 실행 파일 실행>

void main() async{
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['PROJECT_URL']!,
    anonKey: dotenv.env['PROJECT_API_KEY']!,
  );

  KakaoSdk.init(
    nativeAppKey: dotenv.env['NATIVE_APP_KEY']!,
  );

  WidgetsFlutterBinding.ensureInitialized();  //플러터 프레임워크 준비 대기
  await initializeDateFormatting();           //다국적화
  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false, //debug 표시 제거
        home:MainScreen(),  //최종 실행 파일
      )
  );
}
