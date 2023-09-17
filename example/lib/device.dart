import 'package:inkanteen_bluetooth_printer/inkanteen_bluetooth_printer.dart';

class Devices {
  BluetoothDevice? bluetoothDevice;
  bool? food;
  bool? drink;
  bool? receipt;

  Devices({this.bluetoothDevice, this.food, this.drink, this.receipt});

  Devices.fromJson(Map<String, dynamic> json) {
    bluetoothDevice = json['bluetooth_device'] != null
        ? BluetoothDevice.fromJson(json['bluetooth_device'])
        : null;
    food = json['food'];
    drink = json['drink'];
    receipt = json['receipt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bluetoothDevice != null) {
      data['bluetooth_device'] = bluetoothDevice!.toJson();
    }
    data['food'] = food;
    data['drink'] = drink;
    data['receipt'] = receipt;
    return data;
  }
}
