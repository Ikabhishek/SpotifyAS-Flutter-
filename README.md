#  Spotify Clone - Flutter

A feature-rich, full-stack cross-platform Spotify clone built with **Flutter**, **Firebase**, and **Riverpod**.

---

##  Features

- ** Seamless Audio Streaming**: Background audio playback, continuous queue management, looping, seeking, and lock-screen notification controls via `just_audio` & `just_audio_background`.
- ** Spotify-Inspired UI**: Beautiful dark theme with Spotify green accents (`#1DB954`), gradient greeting headers, and responsive layouts.
- ** Dynamic Search & Discovery**: Instant search across tracks and artists, along with vibrant category tiles.
- ** Library & Playback History**: Track recently played songs and user library state in real-time.
- ** Admin Dashboard**: Dedicated portal for administrators to upload songs/albums (audio files + album art) and view live dashboard analytics.
- ** Firebase Authentication**: Seamless Google Sign-In and Firestore profile persistence.

---

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev) (Dart SDK `^3.11.0`)
- **State Management**: [Riverpod (`flutter_riverpod`)](https://riverpod.dev)
- **Audio Engine**: [`just_audio`](https://pub.dev/packages/just_audio) & [`just_audio_background`](https://pub.dev/packages/just_audio_background)
- **Backend & Database**: 
  - [Cloud Firestore](https://firebase.google.com/docs/firestore)
  - [Firebase Auth](https://firebase.google.com/docs/auth) (Google Sign-In)
  - [Firebase Storage](https://firebase.google.com/docs/storage)
- **Networking**: [Dio](https://pub.dev/packages/dio) with Firebase Auth interceptors

---

## 📦 Getting Started

### 1. Prerequisites
- Flutter SDK installed (`>=3.11.0`)
- Android Studio / VS Code with Flutter extension
- Firebase project configured

### 2. Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Ikabhishek/SpotifyAS-Flutter-.git
   cd SpotifyAS-Flutter-
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── firebase_options.dart      # Firebase configuration
├── main.dart                  # App entry point & theme configuration
├── models/                    # Data models (Song, Album, UserProfile)
├── providers/                 # Riverpod state management & repositories
├── services/                  # Audio player, API & Socket services
└── ui/
    ├── screens/               # Home, Search, Library, Album Details, Admin
    └── widgets/               # Bottom persistent audio player, shared widgets
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
