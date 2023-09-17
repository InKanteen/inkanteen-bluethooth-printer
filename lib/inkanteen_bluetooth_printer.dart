// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'package:inkanteen_bluetooth_printer/bluetooth_device.dart';

import 'inkanteen_bluetooth_printer_platform_interface.dart';

export 'bluetooth_device.dart';

class InkanteenBluetoothPrinter {
  Future<List<BluetoothDevice>> getDevices() {
    return InkanteenBluetoothPrinterPlatform.instance.getDevices();
  }

  Future<BluetoothDevice?> getDevice(String address) async {
    final devices =
        await InkanteenBluetoothPrinterPlatform.instance.getDevices();
    final idx = devices.indexWhere((element) => element.address == address);
    if (idx >= 0) {
      return devices[idx];
    }

    return null;
  }
}
