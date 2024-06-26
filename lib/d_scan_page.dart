import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'd_scan_channel.dart';

class DScanPage extends StatefulWidget {
  const DScanPage({super.key});

  @override
  State<DScanPage> createState() => _DScanPageState();
}

class _DScanPageState extends State<DScanPage> with SingleTickerProviderStateMixin {
  List<String> scanList = [];
  MobileScannerController _controller = MobileScannerController();
  bool _flashOn = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  List<Offset> offsetList = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.2).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 0.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0,
      ),
    ]).animate(_animationController);

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodes) {
    final List<Barcode> barcodeList = barcodes.barcodes;
    List<String> temp = [];
    for (var barcode in barcodeList) {
      temp.add(barcode.rawValue!);
    }
    List<Offset> tempOffsetList = [];
    for (var barcode in barcodeList) {
      tempOffsetList.add(barcode.corners.first);
    }
    setState(() {
      scanList = temp;
      offsetList = tempOffsetList;
    });
    DScanChannel.sendScanResult(scanList);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final BarcodeCapture? barcodes = await _controller.analyzeImage(image.path);
      List<String> temp = [];
      for (var barcode in barcodes!.barcodes) {
        temp.add(barcode.rawValue!);
      }
      setState(() {
        scanList = temp;
      });
      DScanChannel.sendScanResult(scanList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scannerHeight = MediaQuery.of(context).size.height * 0.95;
    final double scannerWidth = MediaQuery.of(context).size.width * 0.95;
    final double topPadding = (MediaQuery.of(context).size.height - scannerHeight) / 2;

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: topPadding,
            left: (MediaQuery.of(context).size.width - scannerWidth) / 2,
            child: Container(
              width: scannerWidth,
              height: scannerHeight,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: scannerHeight * _animationController.value,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Container(
                            height: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30.0),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Column(
            children: <Widget>[
              Spacer(),
              /*Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Scan Result: $scanList | $offsetList',
                  style: TextStyle(color: Colors.white),
                ),
              ),*/
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      iconSize: 40.0,
                      onPressed: () {
                        setState(() {
                          _flashOn = !_flashOn;
                          _controller.toggleTorch();
                        });
                      },
                    ),
                    SizedBox(width: 180),
                    IconButton(
                      icon: Icon(
                        Icons.photo,
                        color: Colors.white,
                      ),
                      iconSize: 40.0,
                      onPressed: _pickImage,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'DScan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
