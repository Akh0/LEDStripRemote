import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

extension on Color {
  String toHex() => '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

Future<http.Response> updateLEDRequest(String color, int brightness) {
  return http.post(
    Uri.parse('http://192.168.1.15:8888/set'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      'color': color,
      'brightness': brightness,
    }),
  );
}

void updateLED(Color color, double brightness) {
  EasyDebounce.debounce('update-led-debouncer', const Duration(milliseconds: 5),
      () => updateLEDRequest(color.toHex(), brightness.round()));
}

class _MyAppState extends State<MyApp> {
  Color _currentColor = Colors.white;
  double _currentBrightness = 100;
  bool _currentOn = true;

  void turnOnOff(on) {
    setState(() => _currentOn = on);

    if (on) {
      updateLED(_currentColor, _currentBrightness);
    } else {
      updateLED(Colors.black, 0);
    }
  }

  void changeColor(Color color) {
    setState(() => _currentColor = color);

    if (_currentOn) {
      updateLED(color, _currentBrightness);
    }
  }

  void changeBrightness(double brightness) {
    setState(() => _currentBrightness = brightness);

    if (_currentOn) {
      updateLED(_currentColor, brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _currentBrightness,
                      onChanged: changeBrightness,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: _currentBrightness.round().toString(),
                    ),
                    const Spacer(),
                    SwitchListTile(
                      title: const Text('Allumer / Éteindre',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
