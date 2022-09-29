import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_demo/signaling.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  final _inputController = TextEditingController();

  Map<String, dynamic> get _input {
    final input = jsonDecode(_inputController.text.replaceAll('[log] ', ''));
    _inputController.clear();
    return input;
  }

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("WebRTC"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _inputController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await signaling.openUserMedia(
                        _localRenderer,
                        _remoteRenderer,
                      );
                      setState(() {});
                    },
                    child: const Text("Open cam & mic"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signaling.offer();
                    },
                    child: const Text("Offer"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signaling.answer(_input);
                    },
                    child: const Text("Answer"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signaling.setRemoteDescription(_input);
                    },
                    child: const Text("Set remote description"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signaling.addCandidate(_input);
                    },
                    child: const Text("Add candidate"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signaling.hangUp(_localRenderer);
                    },
                    child: const Text("Hangup"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RTCVideoView(_localRenderer, mirror: true),
                      ),
                      Expanded(child: RTCVideoView(_remoteRenderer)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
