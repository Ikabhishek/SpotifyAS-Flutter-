import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider to hold online user IDs
class OnlineUsersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setUsers(List<String> users) {
    state = users;
  }
}

final onlineUsersProvider = NotifierProvider<OnlineUsersNotifier, List<String>>(OnlineUsersNotifier.new);

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// Initialize real-time presence using Firestore
  void initSocket(WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid; 

    if (userId != null) {
      // 1. Mark current user as online
      _updateUserPresence(userId, true);

      // 2. Listen to other online users
      FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
            
        final onlineUserIds = snapshot.docs
            .map((doc) => doc.id)
            .where((id) => id != userId) // exclude self
            .toList();
            
        ref.read(onlineUsersProvider.notifier).setUsers(onlineUserIds);
        print('Online users updated: $onlineUserIds');
      });
    }
  }

  void disconnect() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _updateUserPresence(user.uid, false);
    }
  }

  Future<void> _updateUserPresence(String userId, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating presence: $e');
    }
  }
}
