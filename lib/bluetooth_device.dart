import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:inkanteen_bluetooth_printer/inkanteen_bluetooth_printer_platform_interface.dart';

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
      await InkanteenBluetoothPrinterPlatform.instance.connect(
        address,
      );

      await InkanteenBluetoothPrinterPlatform.instance.write(
        address,
        data: data,
      );

      await InkanteenBluetoothPrinterPlatform.instance.disconnect(address);
      return true;
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

  Future<void> printImage({
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
    PaperSize paperSize = PaperSize.mm58,
    int addFeeds = 0,
    bool useImageRaster = false,
    required bool keepConnected,
  }) async {
    final bytes = await _optimizeImage(
      paperSize: paperSize,
      src: imageBytes,
      srcWidth: imageWidth,
      srcHeight: imageHeight,
    );

    img.Image src = img.decodeJpg(bytes)!;

    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize,
      profile,
      spaceBetweenRows: 0,
    );
    List<int> imageData;
    if (useImageRaster) {
      imageData = generator.imageRaster(
        src,
        highDensityHorizontal: true,
        highDensityVertical: true,
        imageFn: PosImageFn.bitImageRaster,
      );
    } else {
      imageData = generator.image(src);
    }

    final additional = [
      ...generator.emptyLines(addFeeds),
      ...generator.text('.'),
    ];

    return writeBytes(
      data: Uint8List.fromList([
        ...generator.reset(),
        ...imageData,
        ...generator.reset(),
        ...additional,
      ]),
    );
  }

  static Future<Uint8List> _optimizeImage({
    required List<int> src,
    required PaperSize paperSize,
    required int srcWidth,
    required int srcHeight,
  }) async {
    final arg = <String, dynamic>{
      'src': src,
      'width': srcWidth,
      'height': srcHeight,
      'paperSize': paperSize,
    };

    return compute(_blackwhiteInternal, arg);
  }

  static Future<Uint8List> _blackwhiteInternal(Map<String, dynamic> arg) async {
    final srcBytes = arg['src'] as List<int>;
    final width = arg['width'] as int;
    final height = arg['height'] as int;
    final paperSize = arg['paperSize'] as PaperSize;

    final bytes = Uint8List.fromList(srcBytes).buffer;
    img.Image src = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes,
    );

    final w = src.width;
    final h = src.height;

    src = img.smooth(src, weight: 1.5);
    final res = img.Image(width: w, height: h);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        final pixel = src.getPixel(x, y);
        final r = pixel.r;
        final b = pixel.b;
        final g = pixel.g;

        int c;
        final l = img.getLuminanceRgb(r, g, b) / 255;
        if (l > 0.8) {
          c = 255 * 255 * 255;
        } else {
          c = 0;
        }

        res.setPixel(x, y, img.ColorInt32(c));
      }
    }

    src = res;
    src = img.pixelate(
      src,
      size: (src.width / paperSize.width).round(),
      mode: img.PixelateMode.average,
    );

    final dotsPerLine = paperSize.width;
    // make sure image not bigger than printable area
    if (src.width > dotsPerLine) {
      double ratio = dotsPerLine / src.width;
      int height = (src.height * ratio).ceil();
      src = img.copyResize(
        src,
        width: dotsPerLine,
        height: height,
      );
    }

    return img.encodeJpg(src);
  }
}
