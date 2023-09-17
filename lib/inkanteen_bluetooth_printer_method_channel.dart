import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inkanteen_bluetooth_printer/bluetooth_device.dart';

import 'inkanteen_bluetooth_printer_platform_interface.dart';

class MethodChannelInkanteenBluetoothPrinter
    extends InkanteenBluetoothPrinterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('com.inkanteen/bluetooth_printer');



  @override
  Future<List<BluetoothDevice>> getDevices() async {
    final result = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('getDevices');
    return result
            ?.map(
              (e) => BluetoothDevice(
                address: e['address'],
                type: e['type'],
                name: e['name'],
              ),
            )
            .toList() ??
        [];
  }

  @override
  Future<bool> write(
    String address, {
    required Uint8List data,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('write', {
      'address': address,
      'data': data,
    });
    return result ?? false;
  }
}
