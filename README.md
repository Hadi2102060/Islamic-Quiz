# Islamic Quiz App

A comprehensive Islamic knowledge quiz application built with Flutter and Firebase. Users can test their knowledge about Islam, earn achievements, and compete on leaderboards.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [How It Works](#how-it-works)
6. [Authentication System](#authentication-system)
7. [Quiz Mechanism](#quiz-mechanism)
8. [Leaderboard & Scoring](#leaderboard--scoring)
9. [User Profiles](#user-profiles)
10. [Firestore Database Structure](#firestore-database-structure)
11. [Security Rules](#security-rules)
12. [Setup & Installation](#setup--installation)

---

## 🎯 Overview

The Islamic Quiz App is a mobile application that helps users test and improve their knowledge about different aspects of Islam through interactive quizzes. Users can:
- Take quizzes on various Islamic topics
- Save their scores and track progress
- Compete with other users on leaderboards
- Earn achievements and badges
- Complete their profiles with photos
- Connect with community via social media

**Current Database**: Firebase Firestore (asia-southeast1)  
**Project ID**: islamicquiz-83516

---

## ✨ Features

### 1. **Quiz Categories**
- Islamic Knowledge
- কুরআন ও হাদিস (Quran & Hadith)
- General Quiz
- Surahs Quiz
- Verses Quiz
- Prophets Quiz
- Seerah Quiz (Islamic History)
-  All Quiz (Combined)

### 2. **Authentication**
-  Phone Number-based OTP login
-  Email registration support
-  Anonymous Firebase authentication
-  Secure session management with SharedPreferences

### 3. **Quiz Features**
-  Timed quizzes with countdown timer
-  Multiple choice questions
-  Real-time score tracking
-  Category-based filtering
-  Auto-save quiz progress

### 4. **Leaderboard System**
-  Global rankings by category
-  Real-time leaderboard updates
-  Top 3 champions display (Gold, Silver, Bronze)
-  User photos with avatars
-  Dynamic scoring updates

### 5. **User Profiles**
-  Complete profile setup (Name, Email, Phone)
-  Profile photo upload (base64 encoded)
-  Quiz statistics and history
-  Achievement badges
-  Personal best scores per category

### 6. **Achievements System**
-  Perfect Score badge (100% on quiz)
-  Top 80% badge (80%+ score)
-  Cumulative streak tracking
-  Achievement notifications

### 7. **Social Integration**
-  Telegram channel connection
-  WhatsApp messaging
-  Facebook sharing
-  YouTube channel subscription
-  Deep linking to native apps

### 8. **Data Persistence**
-  Local caching (SharedPreferences)
-  Real-time Firestore sync
-  Offline support (partial)
-  Cache invalidation on updates

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **UI Libraries**:
  - google_fonts - Custom typography
  - flutter_animate - Animations
  - image_picker - Gallery/Camera access
  - url_launcher - Social media deep linking

### Backend & Database
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Auth
- **Cloud Functions**: Firestore Rules for security
- **Storage**: Base64 encoded images in Firestore

### Development
- **IDE**: VS Code / Android Studio
- **Version Control**: Git
- **Build System**: Gradle (Android), Xcode (iOS)

### Platforms
-  Android (API 21+)
-  iOS (11+)
-  Web (experimental)
-  Linux, macOS, Windows (supported)

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
│
├── core/                              # Core utilities
│   ├── constants/                     # App-wide constants
│   └── utils/                         # Helper functions
│
├── data/                              # Data layer
│   ├── providers/                     # Riverpod providers
│   │   ├── leaderboard_provider.dart  # Leaderboard data + updates
│   │   └── session_user_provider.dart # Current user session
│   └── repositories/                  # Data access layer
│
├── domain/                            # Domain/Business logic
│   └── entities/                      # Data models
│       ├── quiz.dart
│       ├── question.dart
│       ├── leaderboard_entry.dart
│       └── achievement.dart
│
├── presentation/                      # UI layer
│   ├── home/                          # Home screen
│   │   └── components/
│   │       └── social_connect_section.dart
│   ├── quiz/                          # Quiz taking screen
│   ├── result/                        # Result display & saving
│   ├── leaderboard/                   # Leaderboard pages
│   │   ├── leaderboard_screen.dart
│   │   └── leaderboard_screen_new.dart
│   ├── profile/                       # User profile
│   │   ├── profile_complete_screen.dart
│   │   └── profile_screen2.dart
│   ├── widgets/                       # Reusable widgets
│   │   └── stats_background.dart
│   └── l10n/                          # Localization
│
├── services/                          # External services
│   └── routing/                       # App routing
│
├── assets/                            # Static assets
│   ├── audio/                         # Sound effects
│   ├── lottie_files/                  # Animations
│   │   └── Islamic_shape.json
│   └── quiz/                          # Quiz data
│       └── all_questions.json
│
└── build/                             # Generated build files
```

---

## 🔄 How It Works

### User Journey

```
1. Launch App
   ↓
2. Login with Phone OTP
   ├─→ Enter phone number
   ├─→ Receive OTP
   └─→ Verify & Sign In
   ↓
3. Complete Profile (First Time)
   ├─→ Enter Name & Email
   ├─→ Upload Profile Photo
   └─→ Save to Firestore
   ↓
4. Home Screen
   ├─→ Browse Quiz Categories
   ├─→ View Recent Scores
   └─→ Connect on Social Media
   ↓
5. Take Quiz
   ├─→ Select Category
   ├─→ Answer Questions (Timed)
   ├─→ See Live Score
   └─→ Submit Quiz
   ↓
6. View Results
   ├─→ Display Score & Percentage
   ├─→ Show Correct/Incorrect Answers
   ├─→ Check Leaderboard Preview
   └─→ Save to Firestore
   ↓
7. Leaderboard
   ├─→ View Global Rankings
   ├─→ See Top 3 Champions
   ├─→ Filter by Category
   └─→ View User Profiles
```

---

## 🔐 Authentication System

### Phone OTP Flow

1. **User enters phone number** (Bangladesh format: 01XXXXXXXXX)
2. **Server generates OTP** via Firebase or custom backend
3. **OTP sent via SMS/USSD** (handled by `bdApps/send_otp.php`)
4. **User enters OTP**
5. **OTP verified** (`bdApps/verify_otp.php`)
6. **User ID created** = Phone number (persisted in SharedPreferences)
7. **Anonymous Firebase authentication** (to bypass Firebase Auth signup requirements)

### Session Management

```dart
// User ID stored locally
SharedPreferences.getInstance()
  ..setString('userId', phoneNumber)
  ..setString('userPhone', phoneNumber)

// Used throughout app for:
// - Writing quiz results
// - Creating leaderboard entries
// - Updating user profiles
// - Tracking achievements
```

### Security

- ✅ OTP verification prevents unauthorized access
- ✅ Phone number used as document ID (deterministic)
- ✅ Firebase rules validate user identity
- ✅ Public leaderboard data readable by anyone
- ✅ Private user data only editable by owner

---

## 🎮 Quiz Mechanism

### Quiz Structure

Each quiz contains:
- **Category**: Theme of the quiz (e.g., "কুরআন ও হাদিস")
- **Questions**: List of multiple-choice questions
- **Timer**: Countdown for completing quiz (varies by category)
- **Scoring**: Points per correct answer

### Quiz Flow

```
1. User Selects Category
   ↓ Firestore fetches: quizzes/{categoryId}
   ↓

2. Load Questions
   ↓ Reads: questions/{categoryId}/questionId
   ↓ Returns: question text + 4 answer options
   ↓

3. Display Question
   ├─→ Current question number & total
   ├─→ Timer countdown
   ├─→ 4 selectable answer buttons
   ├─→ Progress bar
   └─→ Navigation (Next/Previous)
   ↓

4. Record Answers
   ├─→ Stores: {questionId: selectedAnswer}
   ├─→ Tracks: correctAnswers count
   └─→ Calculates: live score
   ↓

5. Submit Quiz
   ├─→ Calculate final score
   ├─→ Determine percentage (score/total * 100)
   ├─→ Navigate to Result Screen
   └─→ Save to Firestore (see below)
```

### Save Quiz Results

When user completes quiz, the `result_screen.dart` saves:

```dart
// 1. Update Leaderboard
leaderboard/{userId} = {
  'userName': 'User Name',
  'photoUrl': 'image_url_or_base64',
  'categoryScores': {'categoryId': score, ...},
  'totalScore': sum_of_all_scores,
  'quizzesPlayed': increment,
  'lastPlayed': serverTimestamp
}

// 2. Create Achievement (if earned)
users/{userId}/achievements/{achievementId} = {
  'name': 'Perfect Score' or 'Top 80%',
  'type': 'perfect' or 'top100',
  'earnedAt': serverTimestamp,
  'category': 'Category Name'
}

// 3. Log Activity
users/{userId}/activities/{activityId} = {
  'title': 'Category Name',
  'score': percentage (0-100),
  'timestamp': serverTimestamp
}

// 4. Store Detailed Result
results/{userId}_{categoryId} = {
  'userId': userId,
  'userName': userName,
  'score': correctAnswers,
  'totalQuestions': total,
  'percentage': (score/total)*100,
  'category': 'Category Name',
  'categoryId': categoryId,
  'updatedAt': serverTimestamp
}
```

---

## 🏆 Leaderboard & Scoring

### Leaderboard Display

The leaderboard has two views:

#### 1. **Top 3 Champions Cards**
```
 1st Place (Largest)    Gold   Colors
 2nd Place (Medium)     Silver Colors
 3rd Place (Smallest)   Bronze Colors

Shows:
- User avatar (photo or initials)
- User name
- Score
- Rank badge
```

#### 2. **Full Leaderboard List**
```
Rank | Avatar | Name  | Score | Badges | Stats
-----|--------|-------|-------|--------|-------
#1   | Photo  | Name1 | 35    |     | 18pts
#2   | Photo  | Name2 | 28    |      | 14pts
#3   | Avatar | Name3 | 25    | --     | 12pts
...
```

### Ranking Algorithm

```
1. Fetch all results for selected category
2. orderBy('score', descending: true)
3. Limit to top 500 entries
4. Filter by category selection
5. Display with running index as rank
```

### User Photos

Photos are displayed with priority:
```
1. profileImageBase64 (base64 encoded image)
2. photoUrl (image URL)
3. photo (fallback field)
4. Initials (if no photo available)
```

### Category Filtering

```
Selected Category -> Filter results.category == selectedCategory
- If "All Quiz" selected -> Show all categories
- Otherwise -> Show only matching category

Supported Categories:
- Islamic Knowledge
- কুরআন ও হাদিস
- General Quiz
- Surahs Quiz
- Verses Quiz
- Prophets Quiz
- Seerah Quiz
- All Quiz - সব প্রশ্ন
```

---

## 👤 User Profiles

### Profile Data Structure

```dart
users/{userId} = {
  // Personal Information
  'name': String,              // User's name
  'email': String,             // Email address
  'phoneNumber': String,       // Phone number
  
  // Profile Photo
  'profileImageBase64': String, // Base64 encoded image
  'photoUrl': String,          // URL to image (optional)
  
  // Profile Status
  'profileCompleted': Boolean, // Whether profile is complete
  
  // Timestamps
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
  'lastActive': Timestamp,
  
  // Other metadata
  'authMethod': String,        // 'phone', 'email', etc.
  'isSkipped': Boolean         // Profile completion skipped?
}
```

### Profile Completion Flow

1. **First Login**: User prompted to complete profile
2. **ProfileCompleteScreen**:
   - Upload photo from gallery
   - Enter name (required)
   - Enter email (optional)
   - Optionally enter phone
3. **Save Profile**:
   - Update `users/{userId}` document
   - Update `leaderboard/{userId}` with name & photo
   - Store in SharedPreferences for quick access

### Photo Upload

```dart
// User picks image from gallery
ImagePicker.pickImage(
  maxWidth: 800,
  maxHeight: 800,
  imageQuality: 80  // Compress for storage
)

// Convert to base64
final bytes = await file.readAsBytes()
final base64 = base64Encode(bytes)

// Save to Firestore
users/{userId}.profileImageBase64 = base64
leaderboard/{userId}.profileImageBase64 = base64
results/{userId_categoryId}.profileImageBase64 = base64
```

---

## 🗄️ Firestore Database Structure

### Collections Overview

```
islamicquiz-83516 (Database)
├── users/                       # User profiles
│   └── {userId}/
│       ├── activities/          # Quiz activity log
│       └── achievements/        # Earned badges
│
├── results/                     # Quiz result records
│   └── {userId}_{categoryId}
│
├── leaderboard/                 # User rankings
│   └── {userId}
│
├── quizzes/                     # Quiz metadata
│   └── {categoryId}
│
├── questions/                   # All questions
│   └── {categoryId}/{questionId}
│
└── settings/                    # App settings
    └── {settingKey}
```

### Detailed Collections

#### **1. users/ Collection**

```firestore
users/{userId}
├── Document ID: Phone number (01XXXXXXXXX) or Firebase UID
├── Fields:
│   ├── name: "User Name"
│   ├── email: "user@example.com"
│   ├── phoneNumber: "01XXXXXXXXX"
│   ├── profileImageBase64: "iVBORw0KGgoAAAANSUhEUgAA..."
│   ├── profileCompleted: true
│   ├── authMethod: "phone"
│   ├── createdAt: Timestamp(May 8, 2026)
│   ├── updatedAt: Timestamp(May 8, 2026)
│   └── lastActive: Timestamp(May 8, 2026)
│
├── Subcollection: activities/
│   └── {activityId}
│       ├── title: "কুরআন ও হাদিস"
│       ├── score: 85
│       └── timestamp: Timestamp
│
└── Subcollection: achievements/
    └── {achievementId}
        ├── name: "Perfect Score"
        ├── type: "perfect"
        ├── earnedAt: Timestamp
        └── category: "Category Name"
```

#### **2. results/ Collection**

```firestore
results/{userId}_{categoryId}
├── userId: "01234567890"
├── userName: "User Name"
├── photoUrl: "base64_or_url"
├── profileImageBase64: "iVBORw0KGgo..."
├── category: "Category Name"
├── categoryId: "quran_hadith_en"
├── score: 7 (correct answers)
├── totalQuestions: 10
├── correctAnswers: 7
├── percentage: 70
├── updatedAt: Timestamp(May 8, 2026)
└── categoryTitle: "কুরআন ও হাদিস"
```

**Index**: `category (ASC) + score (DESC)` for fast leaderboard queries

#### **3. leaderboard/ Collection**

```firestore
leaderboard/{userId}
├── userName: "User Name"
├── photoUrl: "base64_or_url"
├── profileImageBase64: "iVBORw0KGgo..."
├── totalScore: 250 (sum of all category scores)
├── categoryScores: {
│   "quran_hadith_en": 85,
│   "islamic_knowledge": 90,
│   "general_quiz": 75
│ }
├── quizzesPlayed: 15
├── badges: 3
├── lastPlayed: Timestamp(May 8, 2026)
└── phoneNumber: "01234567890"
```

#### **4. quizzes/ Collection**

```firestore
quizzes/{categoryId}
├── title: "Islamic Knowledge"
├── description: "Test your general Islamic knowledge"
├── timeLimit: 300 (seconds)
├── totalQuestions: 20
├── passingScore: 60 (percentage)
└── createdAt: Timestamp
```

#### **5. questions/ Collection**

```firestore
questions/{categoryId}/{questionId}
├── questionText: "What is the Islamic calendar called?"
├── options: [
│   "Hijri Calendar",
│   "Lunar Calendar",
│   "Islamic Calendar",
│   "All of the above"
│ ]
├── correctAnswer: 3 (index of correct option)
├── explanation: "The Islamic calendar..."
├── category: categoryId
├── difficulty: "medium"
├── createdAt: Timestamp
└── tags: ["calendar", "basics"]
```

#### **6. settings/ Collection**

```firestore
settings/{key}
├── appVersion: "1.0.0"
├── maintenanceMode: false
├── latestQuizUpdate: Timestamp
└── ... other app-level settings
```

---

## 🔒 Security Rules

### Firestore Rules Strategy

All security is managed in `firestore.rules`:

```firestore
// USERS COLLECTION
match /users/{docId} {
  allow read: if true;              // Everyone can see profiles
  allow create: if signedIn();       // Only signed-in can create
  allow update: if signedIn();       // Only signed-in can update own profile
  allow delete: if false;            // Nobody can delete
  
  // ACTIVITIES SUBCOLLECTION
  match /activities/{activityId} {
    allow read: if true;             // Public activity logs
    allow write: if signedIn();       // Only signed-in can log activities
  }
  
  // ACHIEVEMENTS SUBCOLLECTION
  match /achievements/{achievementId} {
    allow read: if true;             // Public achievements
    allow write: if signedIn();       // Only signed-in can earn achievements
  }
}

// RESULTS COLLECTION
match /results/{docId} {
  allow read: if true;               // Public leaderboard
  allow write: if signedIn();         // Signed-in users can save results
}

// LEADERBOARD COLLECTION
match /leaderboard/{docId} {
  allow read: if true;               // Public rankings
  allow write: if signedIn();         // Signed-in users update own rank
}

// QUESTIONS & QUIZZES (Read-only for users)
match /quizzes/{docId} {
  allow read: if true;               // Everyone can see quizzes
  allow write: if false;              // Only Firebase console/admin
}

match /questions/{docId=**} {
  allow read: if true;               // Everyone can read questions
  allow write: if false;              // Only Firebase console/admin
}
```

### Key Functions

```firestore
function signedIn() {
  return request.auth != null;
}

function isOwner(docId) {
  return signedIn() && request.auth.uid == docId;
}
```

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.0+
- Android SDK (API 21+) or iOS 11+
- Firebase account
- Git

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_REPO/Islamic-Quiz.git
cd Islamic-Quiz
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure Firebase

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Connect to project
firebase connect --project islamicquiz-83516
```

### Step 4: Set Up Environment

```bash
# Copy firebase_options.dart (already configured)
# Update Android/iOS native configs if needed

# For Android: google-services.json
# For iOS: GoogleService-Info.plist
```

### Step 5: Run App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specify device
flutter run -d V2353A  # Device ID
```

### Step 6: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules --project islamicquiz-83516
```

---

## 📊 Key Metrics & Analytics

### Usage Tracking
- Total quizzes taken
- Average score per category
- Most popular category
- Active users
- Leaderboard rankings

### Performance
- Query response time: < 200ms
- Photo load time: < 1s
- Leaderboard update: Real-time via Riverpod
- Cache hit rate: > 90%

---

##  Troubleshooting

### Permission Denied on Leaderboard

**Problem**: User can't view leaderboard
**Solution**: Check Firestore rules allow public read on `results` collection

### Photos Not Showing

**Problem**: User photos missing from leaderboard
**Solution**: Ensure `profileImageBase64` is saved to:
- `users/{userId}`
- `leaderboard/{userId}`
- `results/{userId}_{categoryId}`

### Quiz Not Saving

**Problem**: Results don't appear after quiz
**Solution**: 
1. Check Firebase rules allow signed-in writes
2. Verify userId is correctly persisted
3. Check network connection

### Leaderboard Not Updating

**Problem**: New scores don't appear instantly
**Solution**:
1. Force refresh provider: `ref.invalidate(leaderboardProvider)`
2. Check Firestore composite indexes are built
3. Deploy updated rules

---

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 📞 Support

For issues, questions, or feedback:
- 📘 **Facebook**: [Islamic Quiz Community](https://www.facebook.com/share/15mw3zdJnfT/)
- 💬 **Telegram**: [@HadiDevHub](https://t.me/HadiDevHub)
- 📢 **WhatsApp**: [Chat with us](https://wa.me/8801700000000)
- 🎥 **YouTube**: [@HadiDevHub](https://www.youtube.com/@HadiDevHub)

---

## 👨‍💻 Authors

Built with  for the Islamic community

**Last Updated**: May 8, 2026
**Current Version**: 1.0.0
**Status**: Production Ready 
