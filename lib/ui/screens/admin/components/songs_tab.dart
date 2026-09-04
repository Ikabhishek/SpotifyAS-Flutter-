import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/models.dart';
import '../../../../providers/app_providers.dart';
import 'add_song_dialog.dart';

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Text('Songs Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => const AddSongDialog());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Song'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: songsAsync.when(
                data: (songs) => _buildSongsTable(context, songs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTable(BuildContext context, List<Song> songs) {
    if (songs.isEmpty) {
      return const Center(child: Text('No songs found. Add your first track!'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Artist')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Actions')),
          ],
          rows: songs.map((song) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: song.imageUrl.isNotEmpty
                            ? Image.network(song.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                            : Container(color: Colors.grey[800], width: 40, height: 40, child: const Icon(Icons.music_note)),
                      ),
                      const SizedBox(width: 12),
                      Text(song.title),
                    ],
                  ),
                ),
                DataCell(Text(song.artist)),
                DataCell(Text('${song.duration}s')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteSong(context, song.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteSong(BuildContext context, String songId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: const Text('Are you sure you want to delete this song?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('songs').doc(songId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
