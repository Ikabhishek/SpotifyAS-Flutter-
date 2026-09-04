import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/audio_service.dart';
import 'album_details_screen.dart';
import 'admin/admin_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final featuredSongsAsync = ref.watch(topSongsProvider);
    final madeForYouAsync = ref.watch(madeForYouProvider);
    final albumsAsync = ref.watch(albumsProvider);
    final historySongs = ref.watch(historyProvider);
    
    // Auth stream
    final authUserAsync = ref.watch(authUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade900.withOpacity(0.5),
            Colors.black,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/spotify.png', height: 32, width: 32, fit: BoxFit.contain),
              const SizedBox(width: 12),
              const Text('Good afternoon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
            ],
          ),
          actions: [
          if (isAdmin)
             IconButton(
               icon: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent),
               onPressed: () {
                 // Navigate to Admin Screen
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
               },
             ),
          authUserAsync.when(
            data: (user) {
              if (user == null) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(authRepositoryProvider).signInWithGoogle();
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged in globally!')));
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
                         }
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 24),
                    label: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      elevation: 0,
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      // simple logout on tap for demo purposes
                      ref.read(authRepositoryProvider).signOut();
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
                      child: user.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                  ),
                );
              }
            },
            loading: () => const Padding(
               padding: EdgeInsets.only(right: 24.0),
               child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
            error: (e, st) => const Icon(Icons.error, color: Colors.red),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.greenAccent,
        backgroundColor: Colors.grey[900],
        onRefresh: () async {
          ref.refresh(topSongsProvider);
          ref.refresh(albumsProvider);
          ref.refresh(madeForYouProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Featured Songs section (Good afternoon grid)
              featuredSongsAsync.when(
                data: (songs) => _buildGoodAfternoonGrid(context, ref, songs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Playlists',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              
              // Map albums to Playlists since web app shows albums in the left sidebar
              albumsAsync.when(
                data: (albums) => _buildAlbumsList(albums),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
              
              const SizedBox(height: 32),

              const Text(
                'Made For You',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              
              madeForYouAsync.when(
                data: (songs) => _buildSongsList(context, ref, songs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
              
              const SizedBox(height: 32),
              
              // History section replacing Albums
              if (historySongs.isNotEmpty) ...[
                const Text(
                  'Recently Played',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                _buildHistoryList(context, ref, historySongs),
              ],
              // adding space at bottom for player
               const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildGoodAfternoonGrid(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return GestureDetector(
          onTap: () {
            final audioService = ref.read(audioServiceProvider);
            ref.read(currentSongProvider.notifier).state = song;
            ref.read(isPlayingProvider.notifier).state = true;
            ref.read(historyProvider.notifier).add(song);
            audioService.playSong(song, contextPlaylist: songs);
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                song.imageUrl.isNotEmpty
                    ? Image.network(
                        song.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note),
                      ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsList(List<Album> albums) {
    if (albums.isEmpty) return const Text('No playlists found');
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailsScreen(albumId: album.id),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.imageUrl.isNotEmpty
                    ? Image.network(
                        album.imageUrl, 
                        height: 140, 
                        width: 140, 
                        fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) => 
                            Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.album)),
                      )
                    : Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.album)),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  album.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildSongsList(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return const Text('No songs found');
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
               // Play song logic
               final audioService = ref.read(audioServiceProvider);
               ref.read(currentSongProvider.notifier).state = song;
               ref.read(isPlayingProvider.notifier).state = true;
               ref.read(historyProvider.notifier).add(song); // Add to history
               audioService.playSong(song, contextPlaylist: songs);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.imageUrl.isNotEmpty 
                      ? Image.network(
                          song.imageUrl, 
                          height: 140, 
                          width: 140, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.music_note)),
                        )
                      : Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.music_note)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHistoryList(BuildContext context, WidgetRef ref, List<Song> songs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
             onTap: () {
               final audioService = ref.read(audioServiceProvider);
               ref.read(currentSongProvider.notifier).state = song;
               ref.read(isPlayingProvider.notifier).state = true;
               // Already in history, moving to top could be implemented
               audioService.playSong(song, contextPlaylist: songs);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.imageUrl.isNotEmpty
                      ? Image.network(
                          song.imageUrl, 
                          height: 140, 
                          width: 140, 
                          fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) => 
                              Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.music_note)),
                        )
                      : Container(color: Colors.grey[800], height: 140, width: 140, child: const Icon(Icons.music_note)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
