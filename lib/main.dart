import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:untitled/board/board.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fjswddefchdhivkvpffh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqc3dkZGVmY2hkaGl2a3ZwZmZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODUwNDEsImV4cCI6MjA3Mzg2MTA0MX0.tQZfbh8PhcmnhWwtTQCSDiu_W9Au4pZA-lGDNz5wddE',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CheckingPhoto(),
    );
  }
}

