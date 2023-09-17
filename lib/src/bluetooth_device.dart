import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:inkanteen_bluetooth_printer/src/inkanteen_bluetooth_printer_platform_interface.dart';

class BluetoothDevice {
  final String address;
  final int type;
  final String name;
  const BluetoothDevice({
    required this.address,
    required this.type,
    required this.name,
  });

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) =>
      BluetoothDevice(
          address: json['address'], type: json['type'], name: json['name']);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['type'] = type;
    data['name'] = name;
    return data;
  }

  Future<bool> _write({
    required Uint8List data,
  }) async {
    try {
      return await InkanteenBluetoothPrinterPlatform.instance.write(
        address,
        data: data,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> writeBytes({
    required Uint8List data,
  }) async {
    await _write(
      data: data,
    );
  }
}
