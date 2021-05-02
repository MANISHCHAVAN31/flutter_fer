import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fer/main.dart';
import 'package:flutter_fer/pages/imageResult.dart';
import 'package:flutter_fer/routes.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CaptureImage extends StatefulWidget {
  @override
  _CaptureImageState createState() => _CaptureImageState();
}

class _CaptureImageState extends State<CaptureImage>
    with WidgetsBindingObserver {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  int _currentCamera = 0;

  var isCameraReady = false;
  var showCapturedPhoto = false;
  var imagePath;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        setState(() {
          _controller = CameraController(cameras.first, ResolutionPreset.max);
          _initializeControllerFuture = _controller.initialize();
        });
      }
    }
  }

  captureImage(BuildContext context) async {
    final path = join((await getTemporaryDirectory()).path,
        '${DateTime.now().millisecondsSinceEpoch}.png');
    await _controller.takePicture().then((XFile file) async {
      if (mounted) {
        print('Image Saved to ${file.path}');
        _controller?.dispose();
        Navigator.of(context).pushReplacementNamed(
          IMAGE_RESULT,
          arguments: ImageResultArguments(
            imagePath: file.path.toString(),
          ),
        );
      }
    });
  }

  changeCamera() {
    if (_currentCamera == 0) {
      setState(() {
        _currentCamera = 1;
        _controller = CameraController(cameras[1], ResolutionPreset.max);
        _initializeControllerFuture = _controller.initialize();
      });
    } else {
      setState(() {
        _currentCamera = 0;
        _controller = CameraController(cameras[0], ResolutionPreset.max);
        _initializeControllerFuture = _controller.initialize();
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      isCameraReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final size = MediaQuery.of(context).size;
                var camera = _controller.value;
                var scale = size.aspectRatio * camera.aspectRatio;
                if (scale < 1) scale = 1 / scale;
                return Transform.scale(
                  scale: scale,
                  child: Center(
                    child: CameraPreview(_controller),
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: IconButton(
                icon: Icon(Icons.camera),
                iconSize: 70.0,
                color: Colors.white,
                onPressed: () {
                  captureImage(context);
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0, right: 20.0),
              child: IconButton(
                icon: Icon(_currentCamera == 0
                    ? Icons.camera_front
                    : Icons.camera_rear),
                iconSize: 40.0,
                color: Colors.white,
                onPressed: () {
                  changeCamera();
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
