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
- **Time Filtering**: Filter videos by Morning, Afternoon, Evening, or All Day
- **Video List**: Browse available videos with timestamps
- **Watched Status Tracking**: Visual indicators for videos already viewed (color-coded cards)
- **Collapsible Calendar**: Expandable/collapsible calendar view for better screen space management

### Swipeable Video Player Screen (`lib/screens/swipeable_video_player_screen.dart`)
- **Swipeable Navigation**: Swipe left/right to browse through videos seamlessly
- **Smart Pre-loading**: Adjacent videos are pre-loaded for smooth transitions
- **Auto-Play**: Videos automatically play when swiped to
- **Video Controls**: Play/pause, seek, and progress tracking
- **Download Feature**: Save videos directly to device photo library
- **Delete Requests**: Submit requests to remove videos from the system
- **Position Indicator**: Shows current video position (e.g., "Video 3 of 10")
- **Time Display**: Shows video timestamp in the app bar
- **Watched Tracking**: Automatically marks videos as watched when viewed

## Critical Configuration Files

### Services
- **`lib/services/api_service.dart`**: Core API communication layer
  - Club discovery endpoints
  - Court listing functionality
  - Video retrieval methods
  - Video delete request submission
  - Authentication headers

- **`lib/services/watched_videos_service.dart`**: Video tracking service
  - Tracks which videos users have watched
  - Persists watched state using SharedPreferences
  - Auto-cleanup of old entries (14-day retention)
  - Migration support for legacy data

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
- **geolocator**: Location services and nearby club discovery
- **video_player**: Video playback functionality with network streaming support
- **image_gallery_saver_plus**: Video downloads to device gallery
- **flutter_dotenv**: Environment variable management for API credentials
- **shared_preferences**: Local data persistence for watched videos
- **calendar_date_picker2**: Interactive calendar widget for date selection
- **intl**: Internationalization and date/time formatting
- **path_provider**: Access to device storage directories

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

## Recent Updates

### Swipeable Video Player (Latest)
- Replaced single video player with swipeable multi-video player
- Users can now swipe left/right to navigate between videos without returning to the list
- Smart pre-loading of adjacent videos for seamless transitions
- Automatic watched video tracking with visual indicators in video list
- Videos marked as watched have white background; unwatched videos have colored (indigo) background
- Position indicator shows current video number (e.g., "Video 3 of 10")
- Time display in app bar shows when the video was recorded

---

*For support or feature requests, contact the development team - Duncan / Marco*