import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/audio_service.dart';

class BottomPlayer extends ConsumerWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final audioService = ref.read(audioServiceProvider);

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Here we could open the full screen player
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3E3E3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: currentSong.imageUrl.isNotEmpty
                      ? Image.network(
                          currentSong.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey, width: 40, height: 40, child: const Icon(Icons.music_note, size: 20)),
                        )
                      : Container(color: Colors.grey, width: 40, height: 40, child: const Icon(Icons.music_note, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Center controls (Skip, Play, Skip, Loop)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () => audioService.playPrevious(),
                        iconSize: 24,
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        onPressed: () {
                          audioService.togglePlayPause().then((_) {
                            ref.read(isPlayingProvider.notifier).state = !isPlaying;
                          });
                        },
                        iconSize: 32,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () => audioService.playNext(),
                        iconSize: 24,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: ref.watch(isLoopingProvider) ? const Color(0xFF1DB954) : Colors.white,
                        ),
                        onPressed: () => audioService.toggleLoop(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const _PlayerProgressBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// A helper widget to show the position data slider
class _PlayerProgressBar extends ConsumerWidget {
  const _PlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionData = ref.watch(audioPositionProvider).value;
    final audioService = ref.read(audioServiceProvider);

    if (positionData == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            _formatDuration(positionData.position),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0.0,
                max: positionData.duration.inMilliseconds.toDouble(),
                value: positionData.position.inMilliseconds.toDouble().clamp(0.0, positionData.duration.inMilliseconds.toDouble()),
                onChanged: (value) {
                  audioService.seek(Duration(milliseconds: value.round()));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(positionData.duration),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
