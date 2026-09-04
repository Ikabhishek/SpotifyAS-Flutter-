import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAlbumDialog extends StatefulWidget {
  const AddAlbumDialog({super.key});

  @override
  State<AddAlbumDialog> createState() => _AddAlbumDialogState();
}

class _AddAlbumDialogState extends State<AddAlbumDialog> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _releaseYearController = TextEditingController(text: DateTime.now().year.toString());

  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitAlbum() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final yearStr = _releaseYearController.text.trim();

    if (title.isEmpty || artist.isEmpty || yearStr.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select an image')));
      return;
    }

    final year = int.tryParse(yearStr);
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid year format')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload Image to Firebase Storage
      final fileName = 'albums/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.replaceAll('\\', '/').split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      try {
        await ref.putFile(_imageFile!);
      } catch (e) {
        throw Exception("Album Image putFile failed: $e");
      }
      
      String imageUrl;
      try {
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        throw Exception("Album Image getDownloadURL failed: $e. Did you click 'Get Started' in Firebase Storage?");
      }

      // 2. Save metadata to Firestore
      await FirebaseFirestore.instance.collection('albums').add({
        'title': title,
        'artist': artist,
        'imageUrl': imageUrl,
        'releaseYear': year,
        'songs': [], // New albums start with no songs
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album created successfully!')));
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
    _releaseYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Album', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add a new album to your collection', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
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
                      _imageFile == null ? 'Upload album artwork' : _imageFile!.path.replaceAll('\\', '/').split('/').last,
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
              decoration: const InputDecoration(labelText: 'Album Title', filled: true, fillColor: Colors.black26),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist', filled: true, fillColor: Colors.black26),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _releaseYearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Release Year', filled: true, fillColor: Colors.black26),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                   child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                 ElevatedButton(
                  onPressed: _isLoading ? null : _submitAlbum,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                   child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Album', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
