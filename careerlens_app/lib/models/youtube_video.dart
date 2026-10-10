class YouTubeVideo {
  final String title;
  final String videoId;
  final String channel;
  final String thumbnail;
  final String url;

  YouTubeVideo({
    required this.title,
    required this.videoId,
    required this.channel,
    required this.thumbnail,
    required this.url,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      title: json['title'] ?? '',
      videoId: json['video_id'] ?? '',
      channel: json['channel'] ?? 'YouTube Educational',
      thumbnail: json['thumbnail'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'video_id': videoId,
      'channel': channel,
      'thumbnail': thumbnail,
      'url': url,
    };
  }
}
