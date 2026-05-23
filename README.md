# ✈️ Smart Travel Planner

A Flutter app to plan trips, manage itineraries, chat with your travel group, and check weather — all in one place.

---

## 📱 Features

| Feature | Description |
|---|---|
| 🔐 Authentication | Sign up, sign in, forgot password via Firebase Auth |
| 🗺️ My Trips | Create, edit, delete upcoming and past trips |
| 📋 Itinerary | Add daily activities with time, location, type, and notes |
| 💬 Group Chat | Real-time chat with trip members via Firebase Realtime Database |
| 🌤️ Weather | Live weather + 5-day forecast for any city |
| 🌍 Explore | Search cities and instantly start planning a trip |
| 📚 History | View past trips and reuse them as templates |
| 📍 Maps | Tap any location to open it directly in Google Maps |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A Firebase project (free tier is fine)
- Android Studio / VS Code

### 1. Clone the repo

```bash
git clone https://github.com/AIMAN-YASIR/-Smart-Travel-Planner.git
cd smart-travel-planner
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com) and create a new project
2. Enable the following services:
    - **Authentication** → Email/Password
    - **Cloud Firestore**
    - **Realtime Database**
3. Download `google-services.json` and place it in `android/app/`
4. Run `flutterfire configure` or manually update `lib/firebase_options.dart`

> ⚠️ Make sure `databaseURL` is set in `firebase_options.dart`:
> ```dart
> databaseURL: 'https://YOUR-PROJECT-default-rtdb.firebaseio.com',
> ```

### 4. Firebase Rules

**Firestore Rules** (Firebase Console → Firestore → Rules):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Realtime Database Rules** (Firebase Console → Realtime Database → Rules):
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

### 5. API Keys

Open `lib/utils/constants.dart` and replace the placeholder keys:

```dart
class ApiKeys {
  // Get free key from https://openweathermap.org/api
  static const openWeatherMap = 'YOUR_OPENWEATHER_API_KEY';

  // Get free key from https://rapidapi.com/wirefreethought/api/geodb-cities
  static const geoDb = 'YOUR_GEODB_RAPIDAPI_KEY';
}
```

> 💡 The app works without these keys — weather will show an error and city search will use a built-in list of 15 popular cities as fallback.

### 6. Android — Maps & URL Launcher Setup

Add the following inside `<manifest>` (before `<application>`) in `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="geo" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

### 7. Run the app

```bash
flutter run
```

---

## 🗂️ Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── trip_model.dart
│   ├── itinerary_model.dart
│   ├── message_model.dart        # MessageModel + WeatherModel + CityModel
├── providers/
│   ├── auth_provider.dart
│   └── trip_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── trip_service.dart
│   └── api_service.dart          # WeatherService + PlacesService
├── screens/
│   ├── home_screen.dart
│   ├── auth/
│   │   └── auth_screen.dart
│   ├── trips/
│   │   ├── trips_screen.dart
│   │   ├── trip_detail_screen.dart
│   │   └── create_trip_screen.dart
│   ├── itinerary/
│   │   └── itinerary_form_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   ├── weather/
│   │   └── weather_screen.dart
│   ├── explore/
│   │   └── explore_screen.dart
│   └── history/
│       └── history_screen.dart
├── widgets/
│   └── common_widgets.dart
└── utils/
    └── constants.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_database: ^11.0.0
  provider: ^6.1.2
  intl: ^0.19.0
  http: ^1.2.1
  url_launcher: ^6.2.5
```

---

## 🔥 Firebase Collections

### Firestore

| Collection | Description |
|---|---|
| `users` | User profile — name, email, createdAt |
| `trips` | Trip data — destination, dates, memberIds |
| `itinerary` | Activity items linked to a trip via `tripId` |

### Realtime Database

```
chats/
  {tripId}/
    messages/
      {messageId}: { senderId, senderName, text, timestamp, type }
```

---

## 🛠️ Troubleshooting

**Real-time chat not syncing between devices**
- Check Firebase Console → Realtime Database → Rules (must allow authenticated reads/writes)
- Confirm `databaseURL` is present in `firebase_options.dart`
- Check Firebase Console → Realtime Database → Data tab to see if messages are being saved

**Weather not loading**
- Verify your OpenWeatherMap API key in `constants.dart`
- Free tier has a limit of 1,000 calls/day

**City search not working**
- The app falls back to 15 built-in popular cities if the GeoDB API key is missing
- Add your RapidAPI key to enable full search

**Maps not opening**
- Make sure the `<queries>` block is added to `AndroidManifest.xml`
- Run `flutter clean && flutter pub get` after adding

---

