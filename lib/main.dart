import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WebRTC Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _getUserMedia();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    super.dispose();
  }

  void _getUserMedia() async {
    final constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = stream;
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Demo'),
      ),
      body: Center(
        child: RTCVideoView(_localRenderer),
      ),
    );
  }
}
