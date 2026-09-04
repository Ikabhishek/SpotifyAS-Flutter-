import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';

class AudioService {
  final Ref ref;
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  ConcatenatingAudioSource? _playlist;
  List<Song>? _currentPlaylist;
  
  AudioService(this.ref) {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        final isLooping = ref.read(isLoopingProvider);
        if (isLooping) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          playNext();
        }
      }
    });
    
    _player.currentIndexStream.listen((index) {
      if (index != null && _playlist != null && index < _playlist!.children.length) {
         final source = _playlist!.children[index] as UriAudioSource;
         final tag = source.tag;
         
         if (tag is MediaItem && _currentPlaylist != null) {
           try {
             final song = _currentPlaylist!.firstWhere((s) => s.id == tag.id);
             ref.read(currentSongProvider.notifier).state = song;
           } catch (e) {
              // Song not found
           }
         } else if (tag is Song) {
           ref.read(currentSongProvider.notifier).state = tag;
         }
      }
    });
  }

  Future<void> playSong(Song song, {List<Song>? contextPlaylist}) async {
    try {
      if (contextPlaylist != null && contextPlaylist.isNotEmpty) {
        _currentPlaylist = contextPlaylist;
        // Create a playlist source starting from the selected song
        final index = contextPlaylist.indexWhere((s) => s.id == song.id);
        
        final List<AudioSource> audioSources = contextPlaylist.map((s) {
          return AudioSource.uri(
            Uri.parse(s.audioUrl), 
            tag: MediaItem(
              id: s.id,
              album: s.artist,
              title: s.title,
              artist: s.artist,
              artUri: Uri.parse(s.imageUrl),
            )
          );
        }).toList();
        
        _playlist = ConcatenatingAudioSource(children: audioSources);
        
        await _player.setAudioSource(_playlist!, initialIndex: index >= 0 ? index : 0);
      } else {
        _currentPlaylist = [song];
        _playlist = ConcatenatingAudioSource(children: [
          AudioSource.uri(
            Uri.parse(song.audioUrl), 
            tag: MediaItem(
              id: song.id,
              album: song.artist,
              title: song.title,
              artist: song.artist,
              artUri: Uri.parse(song.imageUrl),
            )
          )
        ]);
        await _player.setAudioSource(_playlist!);
      }
      
      _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  Future<void> playNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    } else {
       ref.read(isPlayingProvider.notifier).state = false;
       await _player.stop();
    }
  }

  Future<void> playPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> toggleLoop() async {
    final currentLoopState = ref.read(isLoopingProvider);
    ref.read(isLoopingProvider.notifier).state = !currentLoopState;
    if (!currentLoopState) {
       await _player.setLoopMode(LoopMode.one);
    } else {
       await _player.setLoopMode(LoopMode.off);
    }
  }

  void dispose() {
    _player.dispose();
  }
}
