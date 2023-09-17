import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:inkanteen_bluetooth_printer/src/inkanteen_bluetooth_printer_platform_interface.dart';

class BluetoothDevice {
  final String address;
  final int type;
  final String name;
  BluetoothDevice({
    required this.address,
    required this.type,
    required this.name,
  });

  final _queue = Queue<Uint8List>();
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

  Future<void> _doPrint() async {
    if (_queue.isNotEmpty) {
      final data = _queue.removeFirst();
      await _write(
        address,
        data: data,
      );

      await _doPrint();
    } else {
      _isPrinting = false;
    }
  }

  bool _isPrinting = false;
  Future<void> writeBytes({
    required Uint8List data,
  }) async {
    _queue.add(data);

    if (_isPrinting) {
      return;
    }

    _isPrinting = true;
    _doPrint();
  }
}
