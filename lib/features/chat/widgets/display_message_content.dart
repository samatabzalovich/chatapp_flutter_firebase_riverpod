import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp_ui/common/enums/message_enums.dart';
import 'package:whatsapp_ui/features/chat/widgets/video_player_item.dart';

class DisplayMessageContent extends StatelessWidget {
  final String message;
  final MessageEnum messageEnum;

  const DisplayMessageContent(
      {super.key, required this.message, required this.messageEnum});

  @override
  Widget build(BuildContext context) {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();
    return messageEnum == MessageEnum.text
        ? Text(
            message,
            style: const TextStyle(fontSize: 16),
          )
        : messageEnum == MessageEnum.audio
            ? StatefulBuilder(builder: (context, setState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minWidth: 100,
                      ),
                      onPressed: () async {
                        if (isPlaying) {
                          setState(() {
                            isPlaying = false;
                          });
                        } else {
                          await audioPlayer.play(UrlSource(message));
                          setState(() {
                            isPlaying = true;
                          });
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                      ),
                    ),
                    Container(),
                  ],
                );
              })
            : messageEnum == MessageEnum.video
                ? VideoPlayerItem(videoUrl: message)
                : messageEnum == MessageEnum.gif
                    ? CachedNetworkImage(imageUrl: message)
                    : CachedNetworkImage(imageUrl: message);
  }
}
