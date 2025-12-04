import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

class AlarmList extends StatefulWidget {
  const AlarmList({super.key});

  @override
  State<AlarmList> createState() => _AlarmList();
}


class _AlarmList extends State<AlarmList> {
  List<Widget> alerts = [];

  ///DB 릴타임
  @override
  void initState() {
    super.initState();

    alerts.add(TextAlert(text: "사용자 B님이 당신의 목표에 거절했습니다."));
    alerts.add(TextAlert(text: "사용자 A님이 당신의 목표의 어떤 계획 완료를 기대하고 있습니다!"));
    alerts.add(ButtonAlert(
      text: "사용자 A님이 사용자A의 목표에 동참하길 원합니다. \n 동참하시겠습니까?",
      buttonTextYes: "예",
      buttonTextNo: "아니오",
    ));
  }

  void addButtonAlert(
      {required String text,
        required String buttonYes,
        required String buttonNo}) {
    setState(() {
      alerts.add(ButtonAlert(
        text: text,
        buttonTextYes: buttonYes,
        buttonTextNo: buttonNo,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("알림",
        style: TextStyle(
          color: PRIMARY_COLOR,
          fontSize: 20,
          fontFamily: 'Pretendard-Regular',
          fontWeight: FontWeight.w700,
        ),
      ),
        toolbarHeight: 40.0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: alerts,
      ),
    );
  }
}

class TextAlert extends StatelessWidget {
  final String text;
  const TextAlert({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}


class ButtonAlert extends StatefulWidget {
  final String text;
  final String buttonTextYes;
  final String buttonTextNo;

  const ButtonAlert({
    super.key,
    required this.text,
    required this.buttonTextYes,
    required this.buttonTextNo,
  });

  @override
  State<ButtonAlert> createState() => ButtonAlertState();
}

class ButtonAlertState extends State<ButtonAlert> {
  String? result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text,
            style: const TextStyle(fontSize: 12),),
          const SizedBox(height: 8),
          if (result == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      result = "승인함";
                      ///DB에 추가
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(widget.buttonTextYes),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      result = "거절함";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(widget.buttonTextNo,
                    style: const TextStyle(fontSize: 12),),
                ),
              ],
            )
          else
            Center(
              child: Text(
                result!,
                style:  TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result=="승인함"? Colors.green:Colors.red,
                  fontSize: 12,
                ),
              ),
            )
        ],
      ),
    );
  }
}