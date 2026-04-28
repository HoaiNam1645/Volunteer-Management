# Volunteer App

Mobile application for Volunteer Management System (Android/iOS)

Built with Flutter, matching the existing Vue 3 frontend and Laravel backend.

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Routing**: go_router
- **HTTP Client**: Dio
- **Secure Storage**: flutter_secure_storage
- **UI**: Material Design 3

## Project Structure

```
lib/
├── config/           # App configuration
│   └── app_router.dart
├── core/             # Core utilities
│   ├── constants/    # API endpoints, app constants
│   ├── network/      # API client, auth service
│   ├── theme/        # App theme
│   └── utils/        # Helpers, validators
├── data/             # Data layer
│   ├── models/        # Data models
│   └── repositories/  # API repositories
├── presentation/     # UI layer
│   ├── providers/     # State providers
│   ├── screens/       # App screens
│   └── widgets/       # Reusable widgets
└── main.dart         # Entry point
```

## Screens (matching Vue FE)

| Route | Screen | Status |
|-------|--------|--------|
| `/` | Home | Done |
| `/login` | Login | Done |
| `/register` | Register | Done |
| `/forgot-password` | Forgot Password | Done |
| `/reset-password` | Reset Password | Done |
| `/campaigns` | Campaign List | Done |
| `/campaign/:id` | Campaign Detail | Done |
| `/my-campaigns` | My Campaigns | Done |
| `/feedback` | Feedback / Registrations | Done |
| `/profile` | Profile | Done |
| `/competency-profile` | Competency Profile | Done |
| `/coordinator` | Personnel Coordinator | Placeholder |
| `/report` | Report Monitoring | Placeholder |
| `/admin` | Admin Dashboard | Placeholder |

## Setup

### Prerequisites

- Flutter SDK 3.x
- Android Studio / Xcode
- Backend server running at `http://localhost:8000`

### Installation

```bash
# Navigate to project
cd VolunteerApp

# Install dependencies
flutter pub get

# Copy environment file
cp .env.example .env

# Run on Android
flutter run

# Run on iOS (macOS only)
flutter run -d ios
```

### Configuration

Edit `.env` file:

```env
API_BASE_URL=http://10.0.2.2:8000/api   # Android emulator
API_BASE_URL=http://localhost:8000/api  # iOS simulator
API_BASE_URL=https://your-domain.com/api  # Production
```

## API Integration

The app integrates with the existing Laravel backend:

- **Auth**: JWT + Google OAuth
- **Campaigns**: CRUD, search, filtering
- **Registrations**: Register, cancel, feedback
- **TrustEval**: Admin ML dashboard (placeholder)

## State Management

Uses Provider pattern:

- `AuthProvider` - Authentication state
- `CampaignProvider` - Campaign data
- `RegistrationProvider` - Registration data
- `LocaleProvider` - Language preference

## TODO

- [ ] Implement actual TrustEval screens
- [ ] Image picker for campaign creation
- [ ] Push notifications
- [ ] Offline support
- [ ] Deep linking
- [ ] Unit tests
- [ ] E2E tests
