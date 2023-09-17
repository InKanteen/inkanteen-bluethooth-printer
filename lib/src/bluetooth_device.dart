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

  Future<bool> _write(
    String address, {
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
      address,
      data: data,
    );
  }
}
