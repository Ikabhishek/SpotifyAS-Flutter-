import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/audio_service.dart';

class AlbumDetailsScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailsScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailsProvider(albumId));

    return Scaffold(
      body: albumAsync.when(
        data: (album) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
                  background: album.imageUrl.isNotEmpty
                    ? Image.network(album.imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800], child: const Icon(Icons.album, size: 80)),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text('Album • ${album.artist}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: () {},
                      ),
                      FloatingActionButton(
                        backgroundColor: const Color(0xFF1DB954),
                        onPressed: () {
                          if (album.songs.isNotEmpty) {
                            ref.read(audioServiceProvider).playSong(album.songs.first, contextPlaylist: album.songs);
                            ref.read(isPlayingProvider.notifier).state = true;
                          }
                        },
                        child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = album.songs[index];
                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: song.imageUrl.isNotEmpty
                              ? Image.network(song.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                              : Container(width: 48, height: 48, color: Colors.grey[800], child: const Icon(Icons.music_note)),
                          ),
                        ],
                      ),
                      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.more_vert, color: Colors.grey),
                      onTap: () {
                        // Play the song and set the rest of the album as the playlist
                        ref.read(audioServiceProvider).playSong(song, contextPlaylist: album.songs);
                        ref.read(isPlayingProvider.notifier).state = true;
                      },
                    );
                  },
                  childCount: album.songs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for bottom player
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
