import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../providers/app_providers.dart';

class AddSongDialog extends ConsumerStatefulWidget {
  const AddSongDialog({super.key});

  @override
  ConsumerState<AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends ConsumerState<AddSongDialog> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _durationController = TextEditingController(text: "0");

  String? _selectedAlbumId;
  File? _audioFile;
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitSong() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final durationStr = _durationController.text.trim();

    if (title.isEmpty || artist.isEmpty || durationStr.isEmpty || _audioFile == null || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select both files')));
      return;
    }

    final duration = int.tryParse(durationStr);
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid duration format')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Upload Audio
      final audioRef = FirebaseStorage.instance.ref().child('songs/${timestamp}_${_audioFile!.path.replaceAll('\\', '/').split('/').last}');
      try {
        await audioRef.putFile(_audioFile!);
      } catch (e) {
        throw Exception("Audio putFile failed: $e");
      }
      
      String audioUrl;
      try {
        audioUrl = await audioRef.getDownloadURL();
      } catch (e) {
        throw Exception("Audio getDownloadURL failed: $e. Did you click 'Get Started' in Firebase Storage?");
      }

      // 2. Upload Image
      final imageRef = FirebaseStorage.instance.ref().child('covers/${timestamp}_${_imageFile!.path.replaceAll('\\', '/').split('/').last}');
      try {
        await imageRef.putFile(_imageFile!);
      } catch (e) {
        throw Exception("Image putFile failed: $e");
      }
      
      String imageUrl;
      try {
        imageUrl = await imageRef.getDownloadURL();
      } catch (e) {
        throw Exception("Image getDownloadURL failed: $e");
      }

      // 3. Save to Firestore `songs` collection
      final songDocRef = await FirebaseFirestore.instance.collection('songs').add({
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'duration': duration,
        'albumId': _selectedAlbumId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. If album selected, update the album's `songs` array
      if (_selectedAlbumId != null && _selectedAlbumId != 'none') {
        await FirebaseFirestore.instance.collection('albums').doc(_selectedAlbumId).update({
          'songs': FieldValue.arrayUnion([songDocRef.id])
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song created successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch albums to populate the dropdown
    final albumsAsync = ref.watch(albumsProvider);

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Song', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Add a new song to your music library', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              // Audio Picker
              const Text('Audio File', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickAudio,
                icon: const Icon(Icons.audio_file, color: Colors.greenAccent),
                label: Text(_audioFile == null ? 'Choose Audio File' : _audioFile!.path.replaceAll('\\', '/').split('/').last, style: const TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 16),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload, color: Colors.grey, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _imageFile == null ? 'Upload artwork' : _imageFile!.path.replaceAll('\\', '/').split('/').last,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', filled: true, fillColor: Colors.black26),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist', filled: true, fillColor: Colors.black26),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (seconds)', filled: true, fillColor: Colors.black26),
              ),
              const SizedBox(height: 12),
              
              // Album Dropdown
              const Text('Album (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              albumsAsync.when(
                data: (albums) {
                  return DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[850],
                    decoration: const InputDecoration(filled: true, fillColor: Colors.black26),
                    value: _selectedAlbumId,
                    hint: const Text('Select album'),
                    items: [
                      const DropdownMenuItem(value: 'none', child: Text('No Album (Single)')),
                      ...albums.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))),
                    ],
                    onChanged: (val) {
                       setState(() => _selectedAlbumId = val);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading albums: $e'),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                     child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                   ElevatedButton(
                    onPressed: _isLoading ? null : _submitSong,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                     child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('Add Song', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
