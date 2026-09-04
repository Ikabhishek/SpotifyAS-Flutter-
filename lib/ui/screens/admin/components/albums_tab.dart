import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/models.dart';
import '../../../../providers/app_providers.dart';
import 'add_album_dialog.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

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
                    Icon(Icons.album, color: Colors.purpleAccent),
                    SizedBox(width: 8),
                    Text('Albums Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => const AddAlbumDialog());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Album'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: albumsAsync.when(
                data: (albums) => _buildAlbumsTable(context, albums),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsTable(BuildContext context, List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(child: Text('No albums found. Add your first album!'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Artist')),
            DataColumn(label: Text('Release Year')),
            DataColumn(label: Text('Songs')),
            DataColumn(label: Text('Actions')),
          ],
          rows: albums.map((album) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: album.imageUrl.isNotEmpty
                            ? Image.network(album.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                            : Container(color: Colors.grey[800], width: 40, height: 40, child: const Icon(Icons.album)),
                      ),
                      const SizedBox(width: 12),
                      Text(album.title),
                    ],
                  ),
                ),
                DataCell(Text(album.artist)),
                DataCell(Text(album.releaseYear.toString())),
                DataCell(Text(album.songs.length.toString())),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteAlbum(context, album.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteAlbum(BuildContext context, String albumId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: const Text('Are you sure you want to delete this album?'),
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
        await FirebaseFirestore.instance.collection('albums').doc(albumId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
