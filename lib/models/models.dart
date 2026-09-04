class Song {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String audioUrl;
  final int duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final int releaseYear;
  final List<Song> songs;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.releaseYear,
    required this.songs,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? '',
      releaseYear: json['releaseYear'] ?? 0,
      songs: (json['songs'] as List?)?.map((s) {
        if (s is Map<String, dynamic>) {
          return Song.fromJson(s);
        }
        return null;
      }).whereType<Song>().toList() ?? [],
    );
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String imageUrl;
  final String clerkId;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.imageUrl,
    required this.clerkId,
    this.isAdmin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? '',
      clerkId: json['clerkId'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}
