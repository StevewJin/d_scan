import 'package:flutter/services.dart';

class DScanChannel {
  static const MethodChannel _channel = MethodChannel('fun.jinwei.dscan/scan');

  static Future<void> sendScanResult(List<String> scanList) async {
    try {
      await _channel.invokeMethod('sendScanResult', {'result': scanList});
    } on PlatformException catch (e) {
      print("Failed to send scan result: '${e.message}'.");
    }
  }
}
