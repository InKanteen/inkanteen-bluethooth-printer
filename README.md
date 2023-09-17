# inkanteen_bluetooth_printer

A new Flutter plugin project.

## Usage

Add `inkanteen_bluetooth_printer` package to your pubspec.yaml
```yaml
  dependencies:
    # other dependencies

    inkanteen_bluetooth_printer:
      path: your/path

```

Get Paired Devices
```dart
final manager = InkanteenBluetoothPrinter();

Future<void> getDevices() async {
    final devices = await manager.getDevices();
    /// show devices data to the UI using ListView.builder
}
```

Print Receipt
```dart
Future<void> print(BluetoothDevice device) async {
    final bytes = await _generateESCPOSCommand();
    await device.writeBytes(bytes);
}
```