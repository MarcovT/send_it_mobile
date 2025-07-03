class VideoData {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String courtId;
  final String description;
  final dynamic sponsors;
  final String tags;

  VideoData({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.courtId,
    required this.description,
    required this.sponsors,
    required this.tags,
  });
}