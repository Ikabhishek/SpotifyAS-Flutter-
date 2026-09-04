import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

import '../services/audio_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// --- Auth Service & State ---
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Stream<UserProfile?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      // Fetch user profile from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
         final data = doc.data()!;
         data['_id'] = doc.id;
         return UserProfile.fromJson(data);
      }
      
      // If doc doesn't exist, they just signed up, so we create it
      final newProfile = UserProfile(
        id: user.uid,
        fullName: user.displayName ?? 'Unknown User',
        imageUrl: user.photoURL ?? '',
        clerkId: user.uid, // Using uid as clerkId to maintain compatibility
      );
      
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': newProfile.fullName,
        'imageUrl': newProfile.imageUrl,
        'clerkId': newProfile.clerkId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return newProfile;
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Attempt sign in
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user canceled

    // Obtain auth details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Create new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase Auth
    return await _auth.signInWithCredential(credential);
  }
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authUserProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// A provider that checks if the current user is an admin.
// For now, it checks if the email matches the authorized admin email.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider).value;
  // TODO: In a real app, check an 'isAdmin' boolean right from the Firestore UserProfile model.
  // For this development, assuming 'user@example.com' or the user's specific email is the admin.
  // Using a fallback that anyone logged in with a valid user profile gets basic admin access for demo purposes,
  // but we can harden this easily.
  if (user == null) return false;
  
  // Since we don't have the user's explicit email stored in UserProfile yet (only full name and image),
  // we could just fetch the current Firebase user directly for this check.
  final currentUser = FirebaseAuth.instance.currentUser;
  return user.isAdmin || currentUser?.email == 'abhishuklaanu163@gmail.com'; // Allow known admin or users with isAdmin flag
});

// --- Content State ---
final topSongsProvider = FutureProvider<List<Song>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('songs').get();
    
    // Convert to Song models
    List<Song> allSongs = snapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id; // Map Firestore ID to _id for model parsing
      return Song.fromJson(data);
    }).toList();
    
    // Sample 6 random songs
    allSongs.shuffle();
    return allSongs.take(6).toList();
  } catch (e) {
    print('Error fetching featured songs: $e');
    return [];
  }
});

final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('songs').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return Song.fromJson(data);
    }).toList();
  } catch (e) {
    print('Error fetching all songs: $e');
    return [];
  }
});

final madeForYouProvider = FutureProvider<List<Song>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('songs').get();
    
    List<Song> allSongs = snapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return Song.fromJson(data);
    }).toList();
    
    // Sample 4 random songs
    allSongs.shuffle();
    return allSongs.take(4).toList();
  } catch (e) {
    print('Error fetching made for you songs: $e');
    return [];
  }
});

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('albums').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return Album.fromJson(data);
    }).toList();
  } catch (e) {
    print('Error fetching albums: $e');
    return [];
  }
});

final albumDetailsProvider = FutureProvider.family<Album, String>((ref, id) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance.collection('albums').doc(id).get();
    if (!docSnapshot.exists) throw Exception("Album not found");
    
    final data = docSnapshot.data()!;
    data['_id'] = docSnapshot.id;
    
    // The songs array might just contain IDs, we need to populate them if the model expects full song objects
    // Assuming Album.fromJson expects a list of Song objects in 'songs' key:
    if (data['songs'] != null && data['songs'] is List) {
       List<dynamic> songIds = data['songs'];
       List<Map<String, dynamic>> populatedSongs = [];
       
       for (String songId in songIds) {
          final songDoc = await FirebaseFirestore.instance.collection('songs').doc(songId).get();
          if (songDoc.exists) {
            final songData = songDoc.data()!;
            songData['_id'] = songDoc.id;
            populatedSongs.add(songData);
          }
       }
       data['songs'] = populatedSongs;
    }
    
    return Album.fromJson(data);
  } catch (e) {
    print('Error fetching album details: $e');
    throw e;
  }
});

// --- Audio Player State ---
class CurrentSongNotifier extends Notifier<Song?> {
  @override
  Song? build() => null;
}
final currentSongProvider = NotifierProvider<CurrentSongNotifier, Song?>(CurrentSongNotifier.new);

class IsPlayingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}
final isPlayingProvider = NotifierProvider<IsPlayingNotifier, bool>(IsPlayingNotifier.new);

class PlaylistContextNotifier extends Notifier<List<Song>> {
  @override
  List<Song> build() => [];
}
final playlistContextProvider = NotifierProvider<PlaylistContextNotifier, List<Song>>(PlaylistContextNotifier.new);

class HistoryNotifier extends Notifier<List<Song>> {
  @override
  List<Song> build() => [];

  void add(Song song) {
    if (!state.any((s) => s.id == song.id)) {
      state = [song, ...state];
    }
  }
}
final historyProvider = NotifierProvider<HistoryNotifier, List<Song>>(HistoryNotifier.new);

class IsLoopingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}
final isLoopingProvider = NotifierProvider<IsLoopingNotifier, bool>(IsLoopingNotifier.new);

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

// --- Audio Service Provider ---
final audioServiceProvider = Provider((ref) => AudioService(ref));

final audioPositionProvider = StreamProvider<PositionData>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final player = audioService.player;

  return Stream.periodic(const Duration(milliseconds: 200), (_) {
    return PositionData(
      player.position,
      player.bufferedPosition,
      player.duration ?? Duration.zero,
    );
  }).distinct();
});
