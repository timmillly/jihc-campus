# JIHC Campus Hub - Events & News App

**Developer:** Kaisarbai Akniyet  
**Student ID:** `090616651079`  
**Assigned accent color:** `#118AB2`

A Flutter mobile application for JIHC (Jabil International High College) students to discover campus events, read news, and stay connected with their college community.

---

## App Screenshots

Add screenshots before submission:

- Onboarding slide
- Login
- Register
- Home dashboard
- Events list
- News list
- Create post with selected image
- Event/news detail with uploaded image
- Profile/About screen

---

## Feature Checklist

| # | Feature | Status |
|---|---------|--------|
| 1 | Google Sign-In | ✅ |
| 2 | Email/Password Registration & Login | ✅ |
| 3 | Logout (returns to login screen) | ✅ |
| 4 | Authenticated UID used as Firestore key | ✅ |
| 5 | Firestore CRUD (Create, Read, Update, Delete) | ✅ |
| 6 | At least 2 Firestore collections (`/users`, `/posts`) | ✅ |
| 7 | Real-time data sync via Firestore streams | ✅ |
| 8 | Firestore security rules (users edit only own data) | ✅ |
| 9 | Firebase Storage — image upload from camera or gallery | ✅ |
| 10 | Images displayed via CachedNetworkImage | ✅ |
| 11 | 25+ screens / UI states and sections | ✅ |
| 12 | Bottom navigation bar | ✅ |
| 13 | Consistent colors, spacing, typography | ✅ |
| 14 | Personal identity block (name + student ID) | ✅ |
| 15 | Assigned accent color `#118AB2` from TODO project | ✅ |
| 16 | Loading states (CircularProgressIndicator) | ✅ |
| 17 | Empty states with friendly messages | ✅ |
| 18 | Error states (network/auth errors) | ✅ |
| 19 | README with feature list and data structure | ✅ |
| 20 | Compiled APK in GitHub Releases | Add before final submission |

---

## Tech Stack

- **Framework:** Flutter 3.x / Dart
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Auth:** Firebase Auth — Google Sign-In + Email/Password
- **Database:** Cloud Firestore (real-time)
- **Storage:** Firebase Storage
- **State:** StreamBuilder (real-time reactive UI)
- **Image:** image_picker + cached_network_image

---

## Project Structure

```
lib/
├── main.dart                    # App entry + auth gate
├── app_theme.dart               # Theme, colors, constants
├── models/
│   └── models.dart              # EventModel, UserModel
├── services/
│   ├── auth_service.dart        # Google + Email auth
│   ├── firestore_service.dart   # CRUD operations
│   └── storage_service.dart     # Image upload/pick
├── widgets/
│   └── event_card.dart          # Reusable post card
└── screens/
    ├── onboarding_screen.dart   # 3-slide onboarding
    ├── main_nav_screen.dart     # Bottom nav container
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   └── home_screen.dart
    ├── events/
    │   ├── events_screen.dart
    │   └── event_detail_screen.dart
    ├── news/
    │   └── news_screen.dart
    ├── post/
    │   └── create_post_screen.dart
    └── profile/
        └── profile_screen.dart
```

---

## Firestore Data Structure

```
/users/{uid}
  - email: string
  - displayName: string
  - photoUrl: string | null
  - createdAt: timestamp

/posts/{postId}
  - title: string
  - description: string
  - category: 'event' | 'news'
  - authorId: string (= user UID)
  - authorName: string
  - createdAt: timestamp
  - eventDate: timestamp | null
  - imageUrl: string | null
  - location: string
  - likes: number
  - likedBy: string[]
```

## Firebase Storage Structure

```
/event_images/{postId}.jpg
  - uploaded when creating or editing a post
  - download URL saved in /posts/{postId}.imageUrl

/profile_images/{uid}.jpg
  - uploaded when changing profile photo
  - download URL saved in /users/{uid}.photoUrl and Firebase Auth photoURL
```

Storage security:

- Any authenticated user can read images.
- Authenticated users can upload event images under `/event_images`.
- Users can only write their own profile image under `/profile_images/{uid}.jpg`.
- Images are limited by rules to 5 MB for posts and 2 MB for profile photos.

## Firestore Security Summary

- `/users/{uid}` can be created and updated only by the same authenticated UID.
- `/posts/{postId}` can be read by authenticated users.
- Posts can be created only when `authorId == request.auth.uid`.
- Posts can be updated/deleted only by their author.
- Likes can be updated by authenticated users without editing unrelated fields.

## Demo Test Script

Use this for the 3-minute teacher QA test:

1. Register with email/password and show the user in Firebase Authentication.
2. Open Profile and show the hardcoded name, student ID, and accent color.
3. Create an Event with title, description, date, location, and image from gallery.
4. Show the uploaded file in Firebase Storage under `/event_images`.
5. Show the created document in Firestore `/posts`.
6. Open Events and confirm the post appears instantly.
7. Edit the post title or description and confirm Firestore updates.
8. Like the post and show the likes field updating.
9. Delete the post and confirm it disappears from the app and Firestore.
10. Logout and confirm the app returns to the login screen.

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio or VS Code
- Firebase project configured

### Setup

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/jihc_campus_app.git
cd jihc_campus_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Add your `google-services.json` to `android/app/`

4. Run the app:
```bash
flutter run
```

### Firebase commands

Deploy Firestore indexes:

```bash
firebase deploy --only firestore:indexes --project jihc-campus
```

Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules --project jihc-campus
```

Deploy Storage rules after Firebase Storage is enabled in the console:

```bash
firebase deploy --only storage --project jihc-campus
```

Build release APK:

```bash
flutter build apk --release
```

---

## Author

**Kaisarbai Akniyet**  
Student ID: `090616651079`  
JIHC — Jabil International High College  
Assigned Accent Color: `#118AB2` (JIHC Blue)

---

## License

This project was created for the JIHC Final Project assessment.
