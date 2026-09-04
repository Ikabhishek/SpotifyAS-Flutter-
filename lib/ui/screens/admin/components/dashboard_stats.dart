import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminStatsProvider = StreamProvider<Map<String, int>>((ref) async* {
  final firestore = FirebaseFirestore.instance;
  
  // We can yield updates if we prefer, but listening to 3 large collections 
  // might be heavy, so we yield once or periodically. 
  // For a reliable dashboard, we can just do a one-off fetch or use count() queries
  
  while (true) {
    try {
      final songsCount = await firestore.collection('songs').count().get();
      final albumsCount = await firestore.collection('albums').count().get();
      final usersCount = await firestore.collection('users').count().get();
      
      // Let's assume artists are unique artist names in the songs collection
      // Fetching all songs just for artist count is heavy, so we'll mock or just show "Users" as the 3rd stat
      
      yield {
        'songs': songsCount.count ?? 0,
        'albums': albumsCount.count ?? 0,
        'users': usersCount.count ?? 0,
      };
      
      // Refresh stats every 30 seconds
      await Future.delayed(const Duration(seconds: 30));
    } catch (e) {
      yield {'songs': 0, 'albums': 0, 'users': 0};
      await Future.delayed(const Duration(seconds: 30));
    }
  }
});

class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Total Songs', stats['songs'].toString(), Icons.music_note, Colors.tealAccent, Colors.tealAccent.withOpacity(0.1)),
            _buildStatCard('Total Albums', stats['albums'].toString(), Icons.library_music, Colors.purpleAccent, Colors.purpleAccent.withOpacity(0.1)),
            _buildStatCard('Total Users', stats['users'].toString(), Icons.people, Colors.lightBlueAccent, Colors.lightBlueAccent.withOpacity(0.1)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading stats: $e'),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Expanded(
      child: Card(
        color: bgColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
