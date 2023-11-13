enum MessageEnum {
  text('text'),
  image('image'),
  audio('audio'),
  video('video'),
  gif('gif');

  const MessageEnum(this.type);
  final String type;
}

extension ConvertMessage on String {
  MessageEnum toEnum() {
    switch (this) {
      case 'audio':
        return MessageEnum.audio;
      case 'image':
        return MessageEnum.image;
      case 'text':
        return MessageEnum.text;
      case 'gif':
        return MessageEnum.gif;
      case 'video':
        return MessageEnum.video;
      default:
        return MessageEnum.text;
    }
  }
}

extension ConvertEnum on MessageEnum {
  String fromEnum() {
    switch (this) {
      case MessageEnum.audio:
        return 'audio';
      case MessageEnum.image:
        return 'image';
      case MessageEnum.text:
        return 'text';
      case MessageEnum.gif:
        return 'gif';
      case MessageEnum.video:
        return 'video';
      default:
        return 'text';
    }
  }
}
