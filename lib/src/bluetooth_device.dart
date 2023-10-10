// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:collection';

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

  final _queue = Queue<_Task>();
  Future<bool> _write(
    String address, {
    required Uint8List data,
  }) {
    return InkanteenBluetoothPrinterPlatform.instance.write(
      address,
      data: data,
    );
  }

  Future<void> _doPrint() async {
    if (_isPrinting) {
      return;
    }

    _isPrinting = true;
    if (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      final data = task.data;
      try {
        await _write(
          address,
          data: data,
        );

        if (!task.completer.isCompleted) {
          task.completer.complete(true);
        }
      } catch (e) {
        if (!task.completer.isCompleted) {
          task.completer.completeError(e);
        }
      } finally {
        _isPrinting = false;
        _doPrint();
      }
    } else {
      _isPrinting = false;
    }
  }

  bool _isPrinting = false;
  Future<bool> writeBytes({
    required Uint8List data,
  }) async {
    final task = _Task(data: data);
    _queue.add(task);

    _doPrint();

    return task.completer.future;
  }
}

class _Task {
  final Uint8List data;
  _Task({
    required this.data,
  });
  final completer = Completer<bool>();
}
