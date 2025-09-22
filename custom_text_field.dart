import 'package:calendar_scheduler/const/colors.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget{
  final String label;
  final bool isTime;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;

  //매개변수
  const CustomTextField({
    Key? key,
    required this.label,
    required this.isTime,
    this.controller,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Text의 속성을 지정
        Text(
          label,
          style: TextStyle(
            color:PRIMARY_COLOR,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          //TextField의 속성을 지정
            child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
            border: const OutlineInputBorder(),
            ),),
        ),

      ],
    );
  }
}