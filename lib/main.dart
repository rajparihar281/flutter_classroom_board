// ignore: avoid_web_libraries_in_flutter
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/split_screen_manager.dart';

void main() {
  if (kIsWeb) {
    ui_web.platformViewRegistry.registerViewFactory(
      'iframe-view',
      (int viewId) => html.IFrameElement()
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%',
    );
  }
  runApp(const ClassroomBoardApp());
}

class ClassroomBoardApp extends StatelessWidget {
  const ClassroomBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 500),
          showDuration: const Duration(milliseconds: 200),
          textStyle: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const SplitScreenManager(),
      debugShowCheckedModeBanner: false,
    );
  }
}
