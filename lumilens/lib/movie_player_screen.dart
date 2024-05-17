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
  bool _isVolumeSliderVisible = false;
  double _volume = 1.0; // Initial volume

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
        _isVolumeSliderVisible = false; // Hide the volume slider when controls hide
      });
    });
  }

  void _seekForward() {
    final newPosition = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPosition);
  }

  void _seekBackward() {
    final newPosition = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPosition);
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
      _controller.setVolume(volume);
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
      duration: const Duration(milliseconds: 300),
      child: Container(
        alignment: Alignment.bottomCenter,
        color: Colors.black54, // Slightly dark background for better visibility
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                backgroundColor: Colors.grey,
                playedColor: Color.fromARGB(255, 243, 33, 33),
                bufferedColor: Color.fromARGB(255, 244, 3, 3),
              ),
            ),
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
                  icon: const Icon(Icons.replay_10),
                  color: Colors.white,
                  onPressed: _seekBackward,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  color: Colors.white,
                  onPressed: _seekForward,
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isVolumeSliderVisible = !_isVolumeSliderVisible;
                      if (_isVolumeSliderVisible) {
                        _startHideTimer(); // Restart timer when volume slider is shown
                      }
                    });
                  },
                ),
                if (_isVolumeSliderVisible)
                  SizedBox(
                    width: 150,
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _setVolume(value);
                        });
                      },
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
