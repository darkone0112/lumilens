import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:async';

class MoviePlayerScreen extends StatefulWidget {
  final Uri movieUrl;
  const MoviePlayerScreen({Key? key, required this.movieUrl}) : super(key: key);

  @override
  _MoviePlayerScreenState createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late VideoPlayerController _controller;
  Timer? _hideTimer;
  bool _areControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.movieUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
        });
      });

    _startHideTimer();
    Wakelock.enable();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
      if (_areControlsVisible) {
        _startHideTimer(); // Restart timer when controls are shown
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _areControlsVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    Wakelock.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: VideoPlayer(_controller),
            ),
            if (_areControlsVisible) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: _areControlsVisible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Wrap(
          children: [
            VideoProgressIndicator(_controller, allowScrubbing: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  onPressed: () => setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  }),
                ),
                IconButton(
                  icon: Icon(Icons.fullscreen_exit),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ]
        )
      )
      );
  }
}

      
