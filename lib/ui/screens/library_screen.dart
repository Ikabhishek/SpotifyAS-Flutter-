import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import 'album_details_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);
    final userAsync = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            userAsync.when(
               data: (user) {
                 if (user != null) {
                   return Padding(
                     padding: const EdgeInsets.only(right: 12.0),
                     child: CircleAvatar(
                       radius: 16,
                       backgroundImage: user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
                       child: user.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                     ),
                   );
                 }
                 return const SizedBox.shrink();
               },
               loading: () => const SizedBox.shrink(),
               error: (_, __) => const SizedBox.shrink(),
            ),
            const Text('Your Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildPill('Playlists'),
                const SizedBox(width: 8),
                _buildPill('Albums'),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: albumsAsync.when(
              data: (albums) {
                if (albums.isEmpty) return const Center(child: Text('No albums found'));

                return ListView.builder(
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: album.imageUrl.isNotEmpty 
                            ? Image.network(album.imageUrl, fit: BoxFit.cover)
                            : Container(color: Colors.grey[800], child: const Icon(Icons.album)),
                        ),
                      ),
                      title: Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Album • ${album.artist}', style: TextStyle(color: Colors.grey[400])),
                      onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => AlbumDetailsScreen(albumId: album.id),
                           ),
                         );
                      },
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
          ),
          const SizedBox(height: 80), // Bottom player space
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
