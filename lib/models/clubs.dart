class Club {
  final String id;
  final String name;
  final String address;
  final double distance;

  Club({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
  });

  // Just like the video: Create an Image URL that we parse to the widget.
   String get imageUrl => 'https://api.senditreplays.com:3000/api/clubs/download-club-image/$id';
}