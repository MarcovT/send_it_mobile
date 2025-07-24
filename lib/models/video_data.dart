class VideoData {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String courtId;
  final String description;
  final String sponsors;
  final String tags;
  final DateTime? createdAt;

  VideoData({
    required this.id,
    required this.title,
    this.thumbnailUrl = '', // Default empty string since API doesn't provide this
    this.videoUrl = '', // Default empty string since API doesn't provide this
    this.duration = '', // Default empty string since API doesn't provide this
    required this.courtId,
    required this.description,
    required this.sponsors,
    required this.tags,
    this.createdAt,
  });
  String get streamingUrl => 'https://api.senditreplays.com:3000/api/videos/serve-video/$id';
  
  // Factory constructor to create VideoData from API JSON
  factory VideoData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any type to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List) return value.toString();
      return value.toString();
    }

    return VideoData(
      id: safeToString(json['_id']),
      title: safeToString(json['title']),
      thumbnailUrl: safeToString(json['thumbnailUrl']), // Not in API response
      videoUrl: safeToString(json['videoUrl']), // Not in API response
      duration: safeToString(json['duration']), // Not in API response
      courtId: safeToString(json['courtId']),
      description: safeToString(json['description']),
      sponsors: safeToString(json['sponsors']),
      tags: safeToString(json['tags']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  // Method to convert VideoData to JSON (useful for debugging)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'courtId': courtId,
      'description': description,
      'sponsors': sponsors,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}