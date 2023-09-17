import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inkanteen_bluetooth_printer/inkanteen_bluetooth_printer.dart';
import 'package:inkanteen_bluetooth_printer_example/device.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bluetoothPrinter = InkanteenBluetoothPrinter();
  List<Devices> devices = [];

  bool isPrinting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> readyPrint(String type) async {
    final selectedDevices = devices.where((e) =>
        (type == "food" && (e.food ?? false)) ||
        (type == "drink" && (e.drink ?? false)) ||
        (type == "receipt" && (e.receipt ?? false)));

    for (var device in selectedDevices) {
      if (devices.any((e) =>
          e.bluetoothDevice?.address == device.bluetoothDevice?.address)) {
        try {
          setState(() {
            isPrinting = true;
          });

          final startTime = DateTime.now();

          await device.bluetoothDevice?.writeBytes(
            data: Uint8List.fromList(
              await testTicket(type),
            ),
          );

          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);

          setState(() {
            isPrinting = false;
          });

          print("Is print ${duration.inMilliseconds}");
        } catch (e) {
          print(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await bluetoothPrinter.getDevices().then((value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  devices = value
                                      .map((e) => Devices(bluetoothDevice: e))
                                      .toList();
                                });
                              }
                            });
                          },
                          child: const Text('Get Devices'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await readyPrint("food");
                          },
                          child: const Text('Test Food'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await readyPrint("drink");
                          },
                          child: const Text('Test Drink'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await readyPrint("receipt");
                          },
                          child: const Text('Test Receipt'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await readyPrint("receipt");
                            await readyPrint("drink");
                            await readyPrint("food");
                          },
                          child: const Text('Test All'),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final item = devices[index];
                        return ListTile(
                          title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.bluetoothDevice?.name ?? ""),
                                Text(item.bluetoothDevice?.address ?? "")
                              ]),
                          subtitle: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    CupertinoCheckbox(
                                      value: item.food ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          item.food = value;
                                        });
                                      },
                                    ),
                                    const Text("Food"),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    CupertinoCheckbox(
                                      value: item.drink ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          item.drink = value;
                                        });
                                      },
                                    ),
                                    const Text("Drink"),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    CupertinoCheckbox(
                                      value: item.receipt ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          item.receipt = value;
                                        });
                                      },
                                    ),
                                    const Text("Receipt"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isPrinting)
            Container(
                color: Colors.black.withOpacity(0.12),
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Future<List<int>> testTicket(String content) async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    bytes += generator.text(content.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    bytes += generator.text('Align left',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}
