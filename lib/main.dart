import 'dart:convert';
import 'dart:developer';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

extension on Color {
  String toHex() => '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

Future<http.Response> updateLEDRequest(
    String? color, int brightness, String? animation) {
  return http.post(
    Uri.parse('http://192.168.1.15:8888/set'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      'color': color,
      'brightness': brightness,
      'animation': animation,
    }),
  );
}

void updateLED(Color? color, double brightness, String? animation) {
  EasyDebounce.debounce('update-led-debouncer', const Duration(milliseconds: 5),
      () => updateLEDRequest(color?.toHex(), brightness.round(), animation));
}

class _MyAppState extends State<MyApp> {
  Color _currentColor = Colors.white;
  double _currentBrightness = 100;
  String? _currentAnimation;
  Map<String, dynamic> _animations = {};
  bool _currentOn = true;

  void loadAnimations() async {
    final response = await http.get(
        Uri.parse('http://192.168.1.15:8888/animations'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        });

    if (response.statusCode == 200) {
      log(response.body);
      setState(() => _animations = jsonDecode(response.body));
    }
  }

  void turnOnOff(on) {
    setState(() => _currentOn = on);

    if (on) {
      updateLED(_currentColor, _currentBrightness, _currentAnimation);
    } else {
      updateLED(Colors.black, 0, null);
    }
  }

  void changeColor(Color color) {
    setState(() {
      _currentColor = color;
      _currentAnimation = null;
    });

    if (_currentOn) {
      updateLED(color, _currentBrightness, _currentAnimation);
    }
  }

  void changeBrightness(double brightness) {
    setState(() {
      _currentBrightness = brightness;
    });

    if (_currentOn) {
      updateLED(_currentAnimation == null ? _currentColor : null, brightness,
          _currentAnimation);
    }
  }

  void changeAnimation(String? animation) {
    setState(() => _currentAnimation = animation);

    if (_currentOn) {
      updateLED(_currentColor, _currentBrightness, _currentAnimation);
    }
  }

  @override
  void initState() {
    loadAnimations();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      title: 'LED Strip Remote',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('LED Strip Remote'),
          ),
          body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorPicker(
                        pickerColor: _currentColor,
                        onColorChanged: changeColor,
                        colorPickerWidth: 330.0,
                        pickerAreaHeightPercent: 0.8,
                        enableAlpha: false,
                        showLabel: false,
                        displayThumbColor: true,
                        pickerAreaBorderRadius:
                            const BorderRadius.all(Radius.circular(8))),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Luminosité',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Slider(
                      value: _currentBrightness,
                      onChanged: changeBrightness,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: _currentBrightness.round().toString(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    DropdownButtonFormField(
                      value: _currentAnimation,
                      icon: _animations.isEmpty
                          ? const SizedBox(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                              height: 20,
                              width: 20)
                          : const Icon(Icons.arrow_downward),
                      // iconSize: 30,
                      hint: Text(_animations.isEmpty
                          ? 'Chargement des animations…'
                          : 'Animations'),
                      onChanged: _animations.isEmpty ? null : changeAnimation,
                      items: _animations.entries
                          .map<DropdownMenuItem<String>>(
                              (MapEntry<String, dynamic> e) =>
                                  DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                          .toList(),
                    ),
                    const Spacer(),
                    SwitchListTile(
                      title: const Text('Allumer / Éteindre',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(_currentOn
                          ? 'Le ruban LED est allumé'
                          : 'Le ruban LED est éteint'),
                      value: _currentOn,
                      onChanged: turnOnOff,
                    )
                  ]))),
    );
  }
}
