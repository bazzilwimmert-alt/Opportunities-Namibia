import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final String? pin;
  const PlayerScreen({super.key, required this.channel, this.pin});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final state = context.read<AppState>();
      final url = await state.getPlayUrl(widget.channel.id, pin: widget.pin);
      final video = VideoPlayerController.networkUrl(Uri.parse(url));
      await video.initialize();
      final chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: BaxColors.primary,
          handleColor: BaxColors.primary,
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
      );
      if (!mounted) return;
      setState(() {
        _video = video;
        _chewie = chewie;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.channel.name),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _video!.value.aspectRatio == 0
                            ? 16 / 9
                            : _video!.value.aspectRatio,
                        child: Chewie(controller: _chewie!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (widget.channel.isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text('LIVE',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(widget.channel.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
