# SEND-IT Replays 🎾

**The simplest way to access your padel and pickleball game videos. Watch your best shots, download clips instantly, and share your highlights with ease.**

SEND-IT Replays is a Flutter mobile application that connects players to their recorded game footage. Players can browse nearby clubs, select courts, view game videos by date, and download their favorite moments directly to their device.

## App Screens Overview

### Launcher Screen (`lib/screens/launcher_screen.dart`)
- **Brand Introduction**: Animated splash screen with SEND-IT branding
- **Visual Elements**: Tennis ball icon with scale/fade animations
- **Loading State**: Shows "Loading nearby clubs" with progress indicator
- **Auto Navigation**: 2.5-second timer before transitioning to home page
- **Smooth Transitions**: Fade transition to main application

### Home Page (`lib/screens/home_page.dart`)
- **Location Services**: Requests user location to find nearby clubs
- **Club Discovery**: Displays a list of clubs sorted by distance
- **Club Search**: Search functionality to find specific venues
- **Navigation**: Entry point to court selection

### Court Page (`lib/screens/court_page.dart`) 
- **Court Listing**: Shows available courts for the selected club
- **Court Selection**: Allows users to choose their specific playing court
- **Calendar Access**: Navigate to date picker for video browsing

### Court Calendar Page (`lib/screens/court_calendar_page.dart`)
- **Date Picker**: Calendar interface to select game dates
- **Video Availability**: Shows which dates have recorded content
- **Video Navigation**: Direct access to videos for selected dates

### Video Player Screen (`lib/screens/video_player_screen.dart`)
- **Video Playback**: Full-screen video player with standard controls
- **Download Feature**: Save videos directly to device photo library
- **Video Metadata**: Display game information and timestamps

## Critical Configuration Files

### API Service
- **`lib/services/api_service.dart`**: Core API communication layer
  - Club discovery endpoints
  - Court listing functionality  
  - Video retrieval methods
  - Authentication headers

### App Configuration
- **`pubspec.yaml`**: Dependencies and app metadata
- **`android/app/build.gradle.kts`**: Android build configuration
- **`ios/Runner.xcodeproj/`**: iOS project settings

## Getting Started

### Prerequisites
- Flutter SDK (^3.7.2)
- Dart SDK
- Android Studio / Xcode for device testing
- Valid `.env` file with API credentials

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd send_it_mobile

# Install dependencies
flutter pub get

# Configure environment
cp .env.example .env  # Add your API credentials

# Run the app
flutter run
```

### Build for Production
```bash
# Android
flutter build appbundle --release

# iOS  
flutter build ios --release
```

## Key Dependencies

- **http**: API communication
- **geolocator**: Location services
- **video_player**: Video playback functionality
- **image_gallery_saver_plus**: Video downloads
- **flutter_dotenv**: Environment variable management
- **shared_preferences**: Local data persistence

## Security Notes

- All API communication uses HTTPS
- Authentication via API key headers (`send-it-api-key`)
- Environment variables protect sensitive credentials
- Location permissions requested for club discovery

## Development Workflow

1. **API Changes**: Update `lib/services/api_service.dart`
2. **UI Modifications**: Edit respective screen files in `lib/screens/`
3. **Dependencies**: Add to `pubspec.yaml` and run `flutter pub get`
4. **Environment**: Update `.env` for API configuration changes
5. **Testing**: Use `flutter run` for development, test on real devices for location/video features

---

*For support or feature requests, contact the development team - Duncan / Marco*