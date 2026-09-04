import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/audio_service.dart';

// We'll use the top songs provider to mimic a search discovery feed 
// since there's no dedicated search endpoint in the backend.

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(allSongsProvider); // Queries all songs from the backend

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'What do you want to listen to?',
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 24),
              const Text(
                'Browse all',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: songsAsync.when(
                  data: (songs) {
                    final filteredSongs = _searchQuery.isEmpty 
                        ? songs 
                        : songs.where((s) => s.title.toLowerCase().contains(_searchQuery) || s.artist.toLowerCase().contains(_searchQuery)).toList();

                    if (filteredSongs.isEmpty) {
                      return const Center(child: Text('No results found'));
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return GestureDetector(
                          onTap: () {
                            final audioService = ref.read(audioServiceProvider);
                            ref.read(currentSongProvider.notifier).state = song;
                            ref.read(isPlayingProvider.notifier).state = true;
                            audioService.playSong(song, contextPlaylist: filteredSongs);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color((song.title.hashCode & 0xFFFFFF) + 0xFF000000).withOpacity(0.6), // Randomize tile color
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    song.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                ),
              ),
              const SizedBox(height: 80), // Space for bottom player
            ],
          ),
        ),
      ),
    );
  }
}
