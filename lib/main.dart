import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart' as sdp;

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
  bool _offer = false;
  RTCPeerConnection? _peerConnection;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  // SDP: Session Description Protocol
  final _sdpController = TextEditingController();

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _sdpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initRTC();
  }

  void _initRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final constraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    final localStream = await _getUserMedia();

    final connection = await createPeerConnection(configuration, constraints);

    connection.addStream(localStream);

    // ICE: Interactive Connectivity Establishment
    connection.onIceCandidate = (ice) {
      if (ice.candidate != null) {
        print('ICE candidate');
        print(json.encode({
          'candidate': ice.candidate,
          'sdpMid': ice.sdpMid,
          'sdpMlineIndex': ice.sdpMLineIndex,
        }));
      }
    };

    connection.onIceConnectionState = (state) {
      print('ICE connection state: $state');
    };

    connection.onAddStream = (stream) {
      print('Add stream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };

    _peerConnection = connection;
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

    _localRenderer.srcObject = stream;

    return stream;
  }

  void _createOffer() async {
    final connection = _peerConnection;
    if (connection == null) {
      print('No peer connection');
    } else {
      final description = await connection.createOffer({
        'offerToReceiveVideo': 1,
      });
      final session = sdp.parse(description.sdp.toString());
      print(json.encode(session));
      _offer = true;

      _peerConnection!.setLocalDescription(description);
    }
  }

  void _createAnswer() async {
    final description = await _peerConnection!.createAnswer({
      'offerToReceiveVideo': 1,
    });

    final session = sdp.parse(description.sdp.toString());

    print('SDP: ${description.sdp}');
    print('Answer');
    print(json.encode(session));

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    final session = jsonDecode(_sdpController.text);

    final description = RTCSessionDescription(
      sdp.write(session, null),
      _offer ? 'answer' : 'offer',
    );
    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    final session = jsonDecode(_sdpController.text);
    print(session['candidate']);
    final candidate = RTCIceCandidate(
      session['candidate'],
      session['sdpMid'],
      session['sdpMlineIndex'],
    );
    await _peerConnection!.addCandidate(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Demo'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: RTCVideoView(_localRenderer)),
                  Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _createOffer,
                  child: const Text('Offer'),
                ),
                ElevatedButton(
                  onPressed: _createAnswer,
                  child: const Text('Answer'),
                ),
              ],
            ),
            TextField(
              controller: _sdpController,
              maxLines: 6,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _setRemoteDescription,
                  child: const Text('Set remote desc'),
                ),
                ElevatedButton(
                  onPressed: _addCandidate,
                  child: const Text('Add candidate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
