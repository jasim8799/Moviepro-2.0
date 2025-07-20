import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_new_movie_app/pages/fullscreen_video_player.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:my_new_movie_app/models/movie.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MoviePlayerWidget extends StatefulWidget {
  final List<VideoSource> videoSources;
  final bool autoPlay;

  const MoviePlayerWidget({
    super.key,
    required this.videoSources,
    this.autoPlay = true,
  });

  @override
  State<MoviePlayerWidget> createState() => _MoviePlayerWidgetState();
}

class _MoviePlayerWidgetState extends State<MoviePlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  String? _selectedQuality;
  String? _selectedLanguage;
  String? _currentVideoUrl;

  bool _showFullLabels = true;
  bool _adCompleted = false;
  bool _midRollAdShown = false;
  bool _isDisposing = false;

  Timer? _midRollCheckTimer;

  bool get _isPlayerReady {
    if (_isDisposing) return false;
    try {
      return _videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  bool get _isPlaybackFinished {
    return _isPlayerReady &&
        _videoPlayerController!.value.position >=
            _videoPlayerController!.value.duration;
  }

  @override
  void initState() {
    super.initState();
    UnityAds.init(gameId: '5899030', testMode: true);

    final firstSource = widget.videoSources.first;
    _selectedQuality = firstSource.quality;
    _selectedLanguage = firstSource.language;
    _currentVideoUrl = firstSource.url;

    _showRewardedAdBeforePlayback();
  }

  void _showRewardedAdBeforePlayback() {
    UnityAds.load(
      placementId: 'Rewarded_Android',
      onComplete: (placementId) {
        UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (_) => _onAdComplete(),
          onSkipped: (_) => _onAdComplete(),
          onFailed: (_, __, ___) => _onAdComplete(),
        );
      },
      onFailed: (_, __, ___) => _onAdComplete(),
    );
  }

  void _onAdComplete() {
    if (!mounted) return;
    setState(() => _adCompleted = true);
    WakelockPlus.enable();

    if (_currentVideoUrl != null) {
      _initializePlayer(_currentVideoUrl!);
    }

    Future.delayed(const Duration(seconds: 59), () {
      if (mounted) setState(() => _showFullLabels = false);
    });
  }

  Future<void> _initializePlayer(String url, {Duration? resumeFrom}) async {
    try {
      _isDisposing = true;
      final oldChewie = _chewieController;
      final oldController = _videoPlayerController;

      _chewieController = null;
      _videoPlayerController = null;
      if (mounted) setState(() {});

      oldChewie?.dispose();
      await oldController?.dispose();
      _isDisposing = false;

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoPlayerController = controller;

      await controller.initialize();

      if (resumeFrom != null) {
        await controller.seekTo(resumeFrom);
      }

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        showControls: true,
        allowMuting: true,
      );

      if (widget.autoPlay || resumeFrom != null) {
        await controller.play();
      }

      _startMidRollAdMonitor();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Error initializing player: $e");
    }
  }

  void _startMidRollAdMonitor() {
    _midRollCheckTimer?.cancel();
    _midRollCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isPlayerReady || _midRollAdShown) return;

      final position = _videoPlayerController!.value.position;
      final duration = _videoPlayerController!.value.duration;

      if (duration.inSeconds > 120 &&
          position.inSeconds >= duration.inSeconds ~/ 2) {
        _midRollAdShown = true;
        _midRollCheckTimer?.cancel();
        await _pauseAndShowMidRollAd(position);
      }
    });
  }

  Future<void> _pauseAndShowMidRollAd(Duration resumeFrom) async {
    await _videoPlayerController?.pause();
    await _chewieController?.pause();
    _midRollCheckTimer?.cancel();

    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) {
        UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (_) => _resumePlaybackAfterAd(resumeFrom),
          onSkipped: (_) => _resumePlaybackAfterAd(resumeFrom),
          onFailed: (_, __, ___) => _resumePlaybackAfterAd(resumeFrom),
        );
      },
      onFailed: (_, __, ___) => _resumePlaybackAfterAd(resumeFrom),
    );
  }

  void _resumePlaybackAfterAd(Duration resumeFrom) {
    if (!mounted) return;
    WakelockPlus.enable(); // <--- ✅ Optional safety net
    if (_currentVideoUrl != null) {
      _initializePlayer(_currentVideoUrl!, resumeFrom: resumeFrom);
    }
  }

  void _onChangeSource() {
    final newSource = widget.videoSources.firstWhere(
      (e) => e.quality == _selectedQuality && e.language == _selectedLanguage,
      orElse: () => widget.videoSources.first,
    );
    _currentVideoUrl = newSource.url;
    _initializePlayer(newSource.url);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _midRollCheckTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          if (!_adCompleted)
            _buildLoading()
          else if (_chewieController != null && _isPlayerReady)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                ),
                if (_isPlaybackFinished)
                  Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.replay,
                        color: Colors.white,
                        size: 48,
                      ),
                      onPressed: () {
                        if (_currentVideoUrl != null) {
                          _initializePlayer(_currentVideoUrl!);
                        }
                      },
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () async {
                      final currentPos =
                          _videoPlayerController?.value.position ??
                          Duration.zero;
                      if (_currentVideoUrl != null) {
                        final result = await Navigator.push<Duration>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FullScreenVideoPage(
                                  videoUrl: _currentVideoUrl!,
                                  startAt: currentPos,
                                ),
                          ),
                        );
                        if (result != null) {
                          _initializePlayer(
                            _currentVideoUrl!,
                            resumeFrom: result,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            )
          else
            _buildLoading(),

          if (_adCompleted && availableLanguages.isNotEmpty)
            _buildDropdownWidget(
              alignment: Alignment.bottomLeft,
              icon: Icons.arrow_drop_down,
              value: _selectedLanguage!,
              items: availableLanguages,
              onChanged: (val) {
                setState(() {
                  _selectedLanguage = val;
                  _onChangeSource();
                });
              },
            ),

          if (_adCompleted && availableQualities.isNotEmpty)
            _buildDropdownWidget(
              alignment: Alignment.bottomRight,
              icon: Icons.arrow_drop_down,
              value: _selectedQuality!,
              items: availableQualities,
              onChanged: (val) {
                setState(() {
                  _selectedQuality = val;
                  _onChangeSource();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Container(
    height: 250,
    color: Colors.black,
    child: const Center(
      child: CircularProgressIndicator(color: Colors.redAccent),
    ),
  );

  Widget _buildDropdownWidget({
    required Alignment alignment,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child:
              _showFullLabels
                  ? _buildDropdown(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                  )
                  : _buildDropdownIconOnly(
                    icon: icon,
                    items: items,
                    onSelected: onChanged,
                  ),
        ),
      ),
    );
  }

  List<String> get availableQualities =>
      widget.videoSources.map((e) => e.quality).toSet().toList();

  List<String> get availableLanguages =>
      widget.videoSources.map((e) => e.language).toSet().toList();

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: Colors.black,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        items:
            items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildDropdownIconOnly({
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      color: Colors.black,
      onSelected: onSelected,
      itemBuilder:
          (context) =>
              items
                  .map(
                    (e) => PopupMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
    );
  }
}
