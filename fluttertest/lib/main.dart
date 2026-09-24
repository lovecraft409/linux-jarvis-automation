import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../screens/animated_emblem.dart';

Process? jarvisProcess;

Future<void> startJarvisBackend() async {
  const pythonPath = '/home/a_c/Downloads/Linux Jarvis/venv/bin/python';

  //const assistantPath = '/home/a_c/Downloads/Linux Jarvis/voice_assistant.py';
  const assistantPath = '/home/a_c/Downloads/Linux Jarvis/main.py';

  try {
    jarvisProcess = await Process.start(pythonPath, ['-u', assistantPath]);
    print('Jarvis backend started.');
    print('PID: ${jarvisProcess!.pid}');

    jarvisProcess!.stdout.transform(utf8.decoder).listen((data) {
      print('[JARVIS] $data');
    });

    jarvisProcess!.stderr.transform(utf8.decoder).listen((data) {
      print('[JARVIS ERROR] $data');
    });

    jarvisProcess!.exitCode.then((code) {
      print('Jarvis backend exited with code $code');
      jarvisProcess = null;
    });
  } catch (e) {
    print('Failed to start Jarvis backend: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await startJarvisBackend();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: EmblemWithMatrixRain(
            assetPath: 'assets/emblem.png',
            size: 250,
            rainWidth: 2000,
            rainHeight: 1600,
            easterEggText: 'a_c_lovecraft',
            wsUrl: 'ws://localhost:8765',
            glowColor: Colors.green,   // <-- ADD THIS
          ),
        ),
      ),
    );
  }
}
