# 🔥 FireWatch — Flutter Mobile App

A real-time fire detection monitoring app that connects to a Jetson-based inference server running YOLO fire detection models. Built with Flutter using the BLoC pattern.

---

## Table of Contents

- [Overview](#overview)
- [Screens](#screens)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Configuration](#configuration)
- [API Integration](#api-integration)
- [BLoC Pattern](#bloc-pattern)
- [Dependencies](#dependencies)
- [Known Issues & Notes](#known-issues--notes)

---

## Overview

FireWatch connects to a FastAPI server running on a Jetson device over a local network. On launch the app pings the server health endpoint, checks whether cameras are already running, and routes the user to the appropriate screen automatically.

```
App launch
    │
    ▼
Screen 1 — Enter Jetson IP + Port
    │
    ├── GET /health → server unreachable → show error
    │
    └── server OK
          │
          ├── active_cameras > 0 → Screen 3 (Camera List)
          │
          └── no cameras → Screen 2 (Register Camera)
```

---

## Screens

### Screen 1 — Server Config (Jetson Health)
- User enters IP address and port of the Jetson server
- App pings `GET /health` to verify the server is alive
- Displays GPU, CPU, and RAM info on success
- Saves IP/port to local storage — auto-reconnects on next launch
- Routes automatically: cameras exist → Screen 3, no cameras → Screen 2

### Screen 2 — Register Camera
- Two modes: **Video Upload** (mp4, avi, mov, mkv) or **RTSP/HTTP Stream URL**
- User sets a unique Camera ID (e.g. `cam_entrance`, `roof_cam`)
- Frame skip slider (0 = every frame, up to 10 = every 10th frame)
- On success → navigates to Screen 3

### Screen 3 — Camera List
- Lists all registered cameras with live status (polling every 5 seconds)
- Each camera card shows:
  - Snapshot thumbnail (pulled from `/cameras/{id}/snapshot`)
  - Fire detected status with colored indicator
  - Latest intensity level and trend
  - Source type badge (VIDEO / LIVE)
- **Visualize** button → Screen 4
- **See Logs** button → Screen 5
- **Register Camera Again** button (top-right) — stops all running jobs and goes back to Screen 2
- Pull-to-refresh supported

### Screen 4 — Live View
- Shows live annotated MJPEG feed (polled as snapshots every second using `gaplessPlayback`)
- Real-time stats panel updated every 1 second via `GET /cameras/{id}/result`:
  - Fire detected verdict
  - Intensity level and frame coverage %
  - Trend (Increasing / Decreasing / Stable)
  - Direction with compass indicator (up, down, left, right, diagonals)
  - Frame number and detection count
- Fire alert overlay glows red when fire is detected
- Top-right button navigates to Screen 5 (logs)

### Screen 5 — Fire Logs
- Fetches last N frames of detection history via `GET /cameras/{id}/history`
- Summary card showing:
  - Overall verdict
  - Total fire frames, coverage %, first and last fire frame numbers
- Per-frame log list (newest first) with trend, direction, intensity per frame
- Configurable limit (50 / 100 / 200 / 500 frames) via top-right menu
- Pull-to-refresh

---

## Architecture

```
lib/
├── core/
│   ├── constants/        # API paths, polling intervals, timeouts
│   ├── router/           # Named route definitions with fade transitions
│   └── theme/            # Dark theme, colors, button/input styles
│
├── data/
│   ├── datasources/
│   │   ├── api_datasource.dart         # All HTTP calls via Dio
│   │   └── server_config_service.dart  # Base URL management + SharedPreferences
│   └── models/
│       ├── health_model.dart           # /health response
│       └── camera_model.dart           # Camera, result, intensity, direction, history
│
└── presentation/
    ├── blocs/
    │   ├── health_bloc.dart            # Screen 1 BLoC
    │   ├── camera_list_bloc.dart       # Screen 3 BLoC (polling)
    │   └── other_blocs.dart            # Register, LiveView, FireLogs BLoCs
    └── screens/
        ├── server_config_screen.dart   # Screen 1
        ├── register_camera_screen.dart # Screen 2
        ├── camera_list_screen.dart     # Screen 3
        ├── live_view_screen.dart       # Screen 4
        └── fire_logs_screen.dart       # Screen 5
```

---

## Project Structure

```
firewatch/
├── lib/
│   ├── main.dart                        # App entry, all BLoC providers
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_theme.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── api_datasource.dart
│   │   │   └── server_config_service.dart
│   │   └── models/
│   │       ├── health_model.dart
│   │       └── camera_model.dart
│   └── presentation/
│       ├── blocs/
│       │   ├── health_bloc.dart
│       │   ├── camera_list_bloc.dart
│       │   └── other_blocs.dart
│       └── screens/
│           ├── server_config_screen.dart
│           ├── register_camera_screen.dart
│           ├── camera_list_screen.dart
│           ├── live_view_screen.dart
│           └── fire_logs_screen.dart
├── pubspec.yaml
└── README.md
```

---

## Setup & Installation

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android Studio or VS Code with Flutter extension
- A running Jetson server with the FireWatch FastAPI backend
- Both devices on the **same local network**

### Steps

```bash
# 1. Create a new Flutter project
flutter create firewatch
cd firewatch

# 2. Replace the generated lib/ folder with the provided source files
# Replace pubspec.yaml with the provided one

# 3. Install dependencies
flutter pub get

# 4. Run on connected device or emulator
flutter run
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build for iOS

```bash
flutter build ios --release
# Requires macOS with Xcode installed
```

---

## Configuration

All API endpoints and timing constants are in one place:

```dart
// lib/core/constants/app_constants.dart

static const Duration cameraListPollInterval = Duration(seconds: 5);  // Screen 3 refresh
static const Duration liveResultPollInterval = Duration(seconds: 1);  // Screen 4 refresh
static const Duration connectTimeout = Duration(seconds: 10);
static const Duration receiveTimeout = Duration(seconds: 15);
static const String defaultPort = '8000';
```

To change the polling rate, edit these values — no other files need to change.

---

## API Integration

The app talks to these endpoints on the Jetson server. All paths are appended after `http://{ip}:{port}`:

| Method | Endpoint | Used by | Purpose |
|--------|----------|---------|---------|
| `GET` | `/health` | Screen 1 | Check server + GPU status |
| `GET` | `/cameras/` | Screen 3 | List all cameras |
| `POST` | `/cameras/upload` | Screen 2 | Upload video file |
| `POST` | `/cameras/start-stream` | Screen 2 | Start RTSP stream |
| `GET` | `/cameras/{id}/result` | Screen 4 | Latest detection result |
| `GET` | `/cameras/{id}/snapshot` | Screen 3, 4 | JPEG frame thumbnail |
| `GET` | `/cameras/{id}/history` | Screen 5 | Last N frame results |
| `DELETE` | `/cameras/{id}` | Screen 3 | Stop and remove camera |

### Live Video Feed

The app polls `/cameras/{id}/snapshot` every second and swaps the image using `gaplessPlayback: true` to avoid flicker. This approach works reliably across Android and iOS without requiring WebView or native MJPEG support.

> **Note:** For true MJPEG streaming (lower latency), add the `webview_flutter` package and load `/cameras/{id}/video?fps=15` in a `WebViewWidget`. The snapshot polling approach is used by default for maximum compatibility.

---

## BLoC Pattern

Each screen has a dedicated BLoC that manages its state independently:

```
HealthBloc
  Events:  HealthCheckRequested
  States:  HealthInitial → HealthLoading → HealthSuccess(hasCameras) | HealthFailure

CameraListBloc
  Events:  CameraListStarted, CameraListRefreshRequested,
           CameraListPollingStarted, CameraListPollingStoped,
           CameraDeleteRequested, CameraDeleteAllRequested
  States:  CameraListInitial → CameraListLoading → CameraListLoaded | CameraListError

RegisterCameraBloc
  Events:  RegisterWithVideoRequested, RegisterWithStreamRequested, RegisterFormReset
  States:  RegisterCameraInitial → RegisterCameraLoading → RegisterCameraSuccess | RegisterCameraFailure

LiveViewBloc
  Events:  LiveViewStarted, LiveViewPollingTick, LiveViewStopped
  States:  LiveViewInitial → LiveViewLoading → LiveViewUpdated | LiveViewError

FireLogsBloc
  Events:  FireLogsRequested, FireLogsRefreshed
  States:  FireLogsInitial → FireLogsLoading → FireLogsLoaded | FireLogsError
```

Polling is handled inside the BLoC using `dart:async Timer` — the timer starts on the relevant event and is cancelled in `close()` to prevent memory leaks.

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^8.1.3 | BLoC state management |
| `bloc` | ^8.1.2 | Core BLoC library |
| `equatable` | ^2.0.5 | Value equality for states/events |
| `dio` | ^5.3.2 | HTTP client with interceptors |
| `http` | ^1.1.0 | Supplementary HTTP calls |
| `shared_preferences` | ^2.2.2 | Persist IP/port across sessions |
| `file_picker` | ^6.1.1 | Video file selection |
| `shimmer` | ^3.0.0 | Loading skeleton animation |
| `flutter_animate` | ^4.3.0 | Page entry animations |
| `cached_network_image` | ^3.3.0 | Image caching |

---

## Known Issues & Notes

**Snapshot polling vs MJPEG**
The live view uses snapshot polling (1 req/sec) rather than true MJPEG streaming. This is intentional — Flutter's `Image.network` widget does not natively support `multipart/x-mixed-replace` streams on all platforms. If you need sub-second latency, integrate `webview_flutter` and load the `/cameras/{id}/video` endpoint directly in a WebView.

**Same network required**
The app communicates directly with the Jetson over HTTP. Both the phone and the Jetson must be on the same WiFi network. The app does not support remote access over the internet without a VPN or reverse proxy (e.g. ngrok).

**Video upload size**
Large video files (1GB+) may time out during upload. The upload timeout is set to 5 minutes in `api_datasource.dart`. Increase `receiveTimeout` in the `uploadVideo` method if needed.

**iOS file picker**
On iOS, `file_picker` requires the following entry in `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>FireWatch needs access to select video files</string>
```

**Android permissions**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

**Camera list not updating**
If the camera list appears stuck, the polling timer may not have started. Ensure `CameraListPollingStarted` is dispatched in `initState()` of `CameraListScreen` and `CameraListPollingStoped` is dispatched in `dispose()`.