import 'package:flutter/material.dart';
import 'package:calendar_scheduler/const/colors.dart';

//<선택한 날짜를 보여주는 배너>

class SelectdayBanner extends StatelessWidget{
  final DateTime selectedDate;  //선택된 날짜

  //매개변수
  const SelectdayBanner({
    required this.selectedDate,
    Key? key,
  }):super(key: key);

  @override
  Widget build(BuildContext context) {

    //선택된 날짜를 넣은 컨테이너
    return Container(

      //컨테이너 디자인의 속성
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: PRIMARY_COLOR, width: 1), //컨테이너의 테두리의 색상과 두께
      ),

      margin: EdgeInsets.symmetric(horizontal: 5.0,),       //컨테이너 테두리와 배경의 공간

      child:Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0,vertical: 8.0),  //컨테이너 테두리와 컨테이너안의 내용의 공간(수평, 수직)

        //가로로 배치
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //년 월 일
            Text(
              '${selectedDate.year}. ${selectedDate.month}. ${selectedDate.day}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}