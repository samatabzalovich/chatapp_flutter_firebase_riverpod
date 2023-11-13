import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late CachedVideoPlayerController cachedVideoPlayerContoller;
  bool isPlay = false;

  @override
  void initState() {
    super.initState();
    cachedVideoPlayerContoller =
        CachedVideoPlayerController.network(widget.videoUrl)
          ..initialize().then((value) {
            cachedVideoPlayerContoller.setVolume(1);
          });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          CachedVideoPlayer(cachedVideoPlayerContoller),
          Align(
              alignment: Alignment.center,
              child: IconButton(
                  onPressed: () {
                    if (isPlay) {
                      cachedVideoPlayerContoller.pause();
                    } else {
                      cachedVideoPlayerContoller.play();
                    }
                    setState(() {
                      isPlay = !isPlay;
                    });
                  },
                  icon: Icon(isPlay ? Icons.pause_circle : Icons.play_circle)))
        ],
      ),
    );
  }
}
