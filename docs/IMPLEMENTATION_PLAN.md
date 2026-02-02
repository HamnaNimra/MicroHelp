# MicroHelp – Implementation Plan

Implementation phases and task breakdown for the MicroHelp Flutter + Firebase app.

---

## Phase 1: Foundation

### 1.1 Project Setup
| Task | Details |
|------|---------|
| Initialize Flutter | `flutter create .` (or with org) |
| Folder structure | `lib/` → `screens/`, `models/`, `services/`, `widgets/` |
| Dependencies | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `google_sign_in`, `sign_in_with_apple` |
| State management | Provider / Riverpod / Bloc (choose one) |

### 1.2 Firebase Configuration
| Task | Details |
|------|---------|
| Create Firebase project | console.firebase.google.com |
| Add Flutter apps | Android, iOS, Web |
| Download config | `google-services.json`, `GoogleService-Info.plist` |
| FlutterFire CLI | `flutterfire configure` |
| Firestore indexes | Composite indexes for `posts` (expiresAt, location, etc.) |

---

## Phase 2: Auth & Profile

### 2.1 Auth Flow
| Task | Details |
|------|---------|
| Splash screen | Logo, tagline, navigation to Landing |
| Landing screen | "Sign Up" / "Sign In" buttons |
| Auth screen | Tabs or toggle for Sign Up vs Sign In |
| Email/Password | `signInWithEmailAndPassword`, `createUserWithEmailAndPassword` |
| Google Sign-In | `signInWithCredential` (Google Sign-In) |
| Apple Sign-In | `signInWithCredential` (Sign in with Apple) |
| Post-login | Fetch or create `users/{userId}` document |

### 2.2 Profile
| Task | Details |
|------|---------|
| User model | `name`, `profilePic`, `trustScore`, `lastActive`, `location`, badges ref |
| Profile screen | Display user info, edit button |
| Edit profile | Update `users/{userId}` in Firestore |

---

## Phase 3: Posts & Feed

### 3.1 Post Micro-Help
| Task | Details |
|------|---------|
| Post model | `type`, `description`, `userId`, `location`, `radius`, `global`, `expiresAt`, `acceptedBy`, `completed` |
| Create post screen | Form with all fields |
| Validation | Max 200 chars, optional estimated time |
| Firestore write | `posts.add({ ... })` |

### 3.2 Feed
| Task | Details |
|------|---------|
| Query active posts | `where('expiresAt', '>', now)` |
| Client-side radius filter | Filter by distance from user location |
| Optional global | Include global posts |
| Real-time | Snapshot listener for live updates |
| Tap → Post Detail | Navigate with `postId` |

---

## Phase 4: Accept & Chat

### 4.1 Post Detail / Accept
| Task | Details |
|------|---------|
| Post detail screen | Show post info, author (or "Anonymous") |
| Accept button | `posts/{postId}.update({ acceptedBy: userId })` |
| Firestore rules | Ensure only one user can accept |

### 4.2 Chat
| Task | Details |
|------|---------|
| Messages model | `senderId`, `text`, `timestamp` |
| Path | `messages/{postId}/messages/{messageId}` |
| Real-time listener | Snapshot listener for messages |
| Send message | `add({ ... })` |
| Access control | Only poster + accepted helper can read/write |

---

## Phase 5: Completion & Notifications

### 5.1 Task Completion
| Task | Details |
|------|---------|
| Mark completed | `posts/{postId}.update({ completed: true })` |
| Cloud Function | On post completion → increment `users/{helperId}.trustScore` |
| Optional push | Notify poster/helper via FCM |

### 5.2 Notifications
| Task | Details |
|------|---------|
| FCM setup | Configure Firebase Messaging in Flutter |
| Cloud Functions triggers | New nearby post, post accepted, task completed |
| Handle notifications | Foreground, background, terminated states |

---

## Phase 6: Gamification & Polish

### 6.1 Gamification / Badges
| Task | Details |
|------|---------|
| Badges subcollection | `users/{userId}/badges/{badgeId}` |
| Badges screen | Display streaks, badges, trust score |
| Cloud Function | Optional: Badge earned on milestone |

### 6.2 Security Rules
| Task | Details |
|------|---------|
| Users | `allow read, write: if request.auth.uid == userId` |
| Posts | Create if auth; update/delete if owner; read with location logic (client filter + rules) |
| Messages | Read/write only poster or accepted helper |
| Deploy | `firebase deploy --only firestore:rules` |

---

## Suggested Order of Implementation

```
1. Project setup + Firebase config
2. Auth (Splash, Landing, Auth screen)
3. Profile (User model, Profile screen)
4. Post Micro-Help (Post model, create post)
5. Feed (query, filter, display)
6. Post Detail + Accept
7. Chat
8. Task Completion + Cloud Function (trust score)
9. Firestore security rules
10. Notifications (FCM + Cloud Functions)
11. Gamification / Badges
```

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.10
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0
  geolocator: ^10.1.0
  # provider or riverpod for state management
```

---

## File Structure (Target)

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── user_model.dart
│   ├── post_model.dart
│   └── message_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── notification_service.dart
│   └── location_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── landing_screen.dart
│   ├── auth_screen.dart
│   ├── profile_screen.dart
│   ├── post_help_screen.dart
│   ├── feed_screen.dart
│   ├── post_detail_screen.dart
│   ├── chat_screen.dart
│   ├── task_completion_screen.dart
│   └── badges_screen.dart
└── widgets/
    └── (reusable components)
```
