import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;
  final Duration startAt;

  const FullScreenVideoPage({
    super.key,
    required this.videoUrl,
    this.startAt = Duration.zero,
  });

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  Timer? _midRollTimer;
  bool _adShown = false;
  Duration? _videoHalfPoint;
  bool _isOffline = false;
  bool _isLoading = true;
  Duration _lastPosition = Duration.zero;
  bool _isVideoEnded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _checkConnectionAndInitialize();
  }

  Future<void> _checkConnectionAndInitialize() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isOffline = false;
        _isLoading = true;
      });
      await _initializeVideo(widget.videoUrl, resumeFrom: widget.startAt);
    }
  }

  Future<void> _initializeVideo(String url, {Duration? resumeFrom}) async {
    try {
      _chewieController?.dispose();
      await _controller?.dispose();

      final controller = VideoPlayerController.network(
        url,
        httpHeaders: {
          'Accept': 'video/*',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Accept-Encoding': 'identity',
        },
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(false);

      controller.addListener(() {
        if (controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          setState(() => _isVideoEnded = true);
        }
      });

      if (resumeFrom != null) {
        await controller.seekTo(resumeFrom);
      }

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        showControls: true,
        allowFullScreen: false,
        allowMuting: true,
        showControlsOnInitialize: true,
      );

      if (controller.value.duration.inSeconds > 60) {
        _videoHalfPoint = Duration(
          seconds: controller.value.duration.inSeconds ~/ 2,
        );
        _startMidRollAdTimer();
      }

      controller.play();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVideoEnded = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error initializing video: $e");
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  void _startMidRollAdTimer() {
    _midRollTimer?.cancel();
    _midRollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isPlaying &&
          !_adShown &&
          _videoHalfPoint != null &&
          _controller!.value.position >= _videoHalfPoint!) {
        _adShown = true;
        _midRollTimer?.cancel();
        _showMidRollAd(_controller!.value.position);
      }
    });
  }

  void _showMidRollAd(Duration resumeFrom) async {
    await _controller?.pause();
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) {
        UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (_) => _resumeAfterAd(resumeFrom),
          onSkipped: (_) => _resumeAfterAd(resumeFrom),
          onFailed: (_, __, ___) => _resumeAfterAd(resumeFrom),
        );
      },
      onFailed: (_, __, ___) => _resumeAfterAd(resumeFrom),
    );
  }

  void _resumeAfterAd(Duration resumeFrom) async {
    setState(() => _isLoading = true);
    _chewieController?.dispose();
    await _controller?.dispose();

    _chewieController = null;
    _controller = null;

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      await _initializeVideo(widget.videoUrl, resumeFrom: resumeFrom);
    }
  }

  @override
  void dispose() {
    _midRollTimer?.cancel();
    _chewieController?.dispose();
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _lastPosition = _controller?.value.position ?? Duration.zero;
        Navigator.pop(context, _lastPosition);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
            _isOffline
                ? const Center(
                  child: Text(
                    'No Internet Connection',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : (_isLoading ||
                    _chewieController == null ||
                    _controller == null ||
                    !_controller!.value.isInitialized)
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
                    ),
                    if (_isVideoEnded)
                      Center(
                        child: IconButton(
                          iconSize: 80,
                          icon: const Icon(
                            Icons.replay_circle_filled_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _initializeVideo(widget.videoUrl);
                          },
                        ),
                      ),
                    Positioned(
                      bottom: 30,
                      right: 30,
                      child: IconButton(
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          _lastPosition =
                              _controller?.value.position ?? Duration.zero;
                          Navigator.pop(context, _lastPosition);
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
