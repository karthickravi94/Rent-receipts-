# Rent Receipt Manager

A professional Flutter mobile app for managing tenants and generating PDF rent receipts.

## Features

- **Tenant Management** – Add, edit, delete tenants with all details
- **PDF Receipt Generation** – Professional receipts with itemized charges
- **Receipt History** – View, filter, and share past receipts
- **Share via WhatsApp & Email** – Native share sheet + mailto
- **Firebase Firestore** – Free-tier cloud storage
- **Dark Mode** support

---

## Project Structure

```
lib/
├── main.dart                   # Entry point
├── app.dart                    # MaterialApp + theme
├── firebase_options.dart       # Firebase config (replace with yours)
├── models/
│   ├── tenant.dart
│   └── receipt.dart
├── services/
│   ├── firestore_service.dart   # Firestore CRUD
│   └── pdf_service.dart         # PDF generation
├── providers/
│   ├── tenant_provider.dart
│   ├── receipt_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── main_screen.dart         # Bottom nav shell
│   ├── dashboard_screen.dart
│   ├── tenants_screen.dart
│   ├── add_edit_tenant_screen.dart
│   ├── generate_receipt_screen.dart
│   ├── receipt_history_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── custom_text_field.dart
    ├── stat_card.dart
    ├── tenant_card.dart
    └── receipt_card.dart
```

---

## Database Schema (Firestore)

### Collection: `tenants`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID (UUID) |
| `name` | string | Tenant full name |
| `phone` | string | Phone number |
| `email` | string | Email address |
| `houseName` | string | Property / house name |
| `monthlyRent` | number | Base monthly rent (₹) |
| `advanceAmount` | number | Security deposit (₹) |
| `gpayNumber` | string | GPay number |
| `phonePeNumber` | string | PhonePe number |
| `createdAt` | timestamp | Creation date |

### Collection: `receipts`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID (UUID) |
| `tenantId` | string | Reference to tenant |
| `tenantName` | string | Snapshot of tenant name |
| `tenantPhone` | string | Snapshot of phone |
| `tenantEmail` | string | Snapshot of email |
| `houseName` | string | Property name |
| `rentAmount` | number | Base rent (₹) |
| `milkCharge` | number | Milk charges (₹) |
| `electricityCharge` | number | Electricity (₹) |
| `waterCharge` | number | Water charges (₹) |
| `otherCharges` | number | Miscellaneous (₹) |
| `notes` | string | Additional notes |
| `totalAmount` | number | Sum of all charges |
| `advanceAmount` | number | Advance held (reference) |
| `gpayNumber` | string | GPay for payment |
| `phonePeNumber` | string | PhonePe for payment |
| `month` | string | Billing month name |
| `year` | number | Billing year |
| `generatedAt` | timestamp | When receipt was made |

---

## Setup & Deployment

### Prerequisites

- Flutter SDK 3.x ([install](https://flutter.dev/docs/get-started/install))
- Android Studio or Xcode
- Firebase account (free)
- Node.js (for Firebase CLI)

---

### Step 1 — Clone & Install

```bash
git clone <this-repo>
cd rent_receipt_manager
flutter pub get
```

---

### Step 2 — Firebase Setup (Free Spark Plan)

#### 2a. Create Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `rent-receipt-manager`
3. Disable Google Analytics (optional)

#### 2b. Enable Firestore

1. In the Firebase console → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (update rules before production)
3. Select your region

#### 2c. Add Android App

1. In Firebase Console → **Project settings** → **Add app** → Android
2. Package name: `com.example.rent_receipt_manager`
3. Download `google-services.json`
4. Place it at `android/app/google-services.json`

#### 2d. Add iOS App

1. In Firebase Console → **Project settings** → **Add app** → iOS
2. Bundle ID: `com.example.rentReceiptManager`
3. Download `GoogleService-Info.plist`
4. Place it at `ios/Runner/GoogleService-Info.plist`

#### 2e. Update `firebase_options.dart`

Run FlutterFire CLI (recommended):

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure
```

Or manually replace the placeholder values in `lib/firebase_options.dart`.

#### 2f. Deploy Firestore rules & indexes

```bash
npm install -g firebase-tools
firebase login
firebase init firestore   # select existing project
firebase deploy --only firestore
```

---

### Step 3 — Run the App

```bash
# Android
flutter run --release  # or flutter run for debug

# iOS
cd ios && pod install && cd ..
flutter run --release
```

---

### Step 4 — Build Release APK (Android)

```bash
# Generate keystore
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# Add to android/key.properties:
# storePassword=<password>
# keyPassword=<password>
# keyAlias=release
# storeFile=../release-key.jks

# Build
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk

# Or build App Bundle for Play Store
flutter build appbundle --release
```

### Step 4 — Build Release IPA (iOS)

```bash
flutter build ios --release
# Then archive in Xcode and upload to App Store Connect
```

---

## Firebase Free Tier Limits

| Resource | Free Limit |
|---------|------------|
| Firestore reads | 50,000 / day |
| Firestore writes | 20,000 / day |
| Firestore deletes | 20,000 / day |
| Storage | 1 GiB |
| Network egress | 10 GiB / month |

For typical rental management with <50 tenants, the free tier is more than sufficient.

---

## Sharing Receipts

- **WhatsApp**: Uses native Android/iOS share sheet → user selects WhatsApp. No WhatsApp Business API needed.
- **Email**: Opens device mail client with PDF attached and pre-filled subject/body.
- **Other apps**: Any app that accepts PDF files (Drive, Telegram, etc.).

---

## Customisation

- **App color**: Change `_seed` in `lib/utils/theme.dart`
- **PDF header**: Edit `_header()` in `lib/services/pdf_service.dart`
- **Bundle ID**: Update `applicationId` in `android/app/build.gradle` and iOS bundle ID in Xcode
