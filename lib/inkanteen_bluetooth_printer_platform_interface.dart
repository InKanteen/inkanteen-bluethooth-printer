// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:inkanteen_bluetooth_printer/bluetooth_device.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'inkanteen_bluetooth_printer_method_channel.dart';

abstract class InkanteenBluetoothPrinterPlatform extends PlatformInterface {
  /// Constructs a InkanteenBluetoothPrinterPlatform.
  InkanteenBluetoothPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static InkanteenBluetoothPrinterPlatform _instance =
      MethodChannelInkanteenBluetoothPrinter();

  /// The default instance of [InkanteenBluetoothPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelInkanteenBluetoothPrinter].
  static InkanteenBluetoothPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InkanteenBluetoothPrinterPlatform] when
  /// they register themselves.
  static set instance(InkanteenBluetoothPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<BluetoothDevice>> getDevices() {
    throw UnimplementedError('getBondedDevices() has not been implemented.');
  }

  Future<bool> write(
    String address, {
    required Uint8List data,
  }) {
    throw UnimplementedError('write() has not been implemented.');
  }
}
