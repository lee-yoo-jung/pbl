import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// 목표 추가 시 색상을 선택하는 코드

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({required this.initialColor, super.key});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color selectedTempColor;

  @override
  void initState() {
    super.initState();
    selectedTempColor = widget.initialColor;
  }

  void changeColor(Color color) {
    setState(() => selectedTempColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Dialog 디자인
      contentPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MaterialPicker(
              pickerColor: selectedTempColor,
              onColorChanged: changeColor,
              enableLabel: false, // 색 위에 정보 표시 여부 true: 표시 false: 비표시
            ),
          ],
        ),
      ),

      actions: <Widget>[
        TextButton(
          child: const Text('취소'),
          onPressed: () {
            Navigator.pop(context); // null을 반환하며 닫기
          },
        ),
        TextButton(
          child: const Text('확인'),
          onPressed: () {
            Navigator.pop(context, selectedTempColor);
          },
        ),
      ],
    );
  }
}