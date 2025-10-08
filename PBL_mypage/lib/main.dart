import 'package:flutter/material.dart';
import 'conponent/mypage.dart';

void main() async{
  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false, //debug 표시 제거
        home:MyPage(),  //최종 실행 파일
      )
  );
}
