# TVR E-Commerce App 🛍️

A modern, high-performance Flutter e-commerce application built with **Clean Feature-First Architecture**, **Riverpod 2.x**, **GoRouter**, and powered by a **Laravel REST API**.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.x-00569B?style=for-the-badge)
![GoRouter](https://img.shields.io/badge/Router-GoRouter_13-blue?style=for-the-badge)
![Localization](https://img.shields.io/badge/Languages-EN%20%7C%20KM%20%E1%9E%81%E1%9F%92%E1%9E%98%E1%9F%82%E1%9E%92-success?style=for-the-badge)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-green?style=for-the-badge)

---

## 👥 Project Information & Team

- **Project**: Final Year 4 Capstone Project
- **Group**: **SU20**

### Group Members

| No. | Member Name | Role |
|:---:|---|
| 1 | **Thary Vireak**
| 2 | **Leom Ratana**
| 3 | **Hout Phanit**
| 4 | **Rim Bunhieng**
| 5 | **Sok Youngje**
| 6 | **Seang Longmeng**

---

## 🌟 Key Features

### 🔐 Authentication & Security
- **Email & Password Auth**: User registration, login, profile management, and secure logout.
- **Password Recovery**: Complete Forgot Password flow with OTP verification and password reset.
- **Session Persistence**: Encrypted JWT storage (`flutter_secure_storage`) with automatic Dio token refreshing.

### 🛍️ Product Catalog & Discovery
- **Banners & Promotions**: Dynamic promotional banners carousel on the home screen.
- **Category & Brand Filtering**: Multi-level product filtering by categories, subcategories, and top brands.
- **Live Search & Auto-Suggestions**: Debounced instant search query with real-time suggestion pills and search history.
- **Rich Product Detail**: Multi-image gallery, variant selection, price calculations, related product recommendations, and customer reviews/ratings.

### 🛒 Cart & Checkout
- **Cart Management**: Add to cart, adjust quantities, remove items, and instant subtotal calculation.
- **Discount Coupons**: Apply promo codes with immediate price deduction and validation.
- **Delivery Address & Location Picker**: Interactive OpenStreetMap map picker (`flutter_map`, `latlong2`, `geolocator`, `geocoding`) to select precise delivery coordinates and reverse-geocode addresses.
- **Guest & Member Checkout**: Support for guest checkout as well as authenticated member checkout.

### 💳 Payment Methods
- **ABA PayWay**: Native mobile deep-link integration launching the ABA Mobile app with an in-app webview modal fallback.
- **Credit / Debit Cards**: Secure card payment processing.
- **Cash on Delivery (COD)**: Traditional cash on delivery payment option.

### 📦 Orders, Delivery Timeline & Reviews
- **Order History**: Track past and active orders with real-time status badges (*Pending*, *Processing*, *Completed*, *Cancelled*).
- **Visual Delivery Timeline**: Step-by-step progress stepper (*Order Placed* ➔ *Processing* ➔ *Shipped* ➔ *Delivered* / *Cancelled*) across Order Success, Details, and History.
- **Product Reviews & Ratings**: Post-purchase review sheet allowing customers to rate each purchased product individually with 5-star ratings and written feedback.
- **Digital Receipt Viewer**: View detailed digital receipts with itemized order breakdown and web/PDF receipt links with responsive print/open handling.

### ❤️ Wishlist
- **Instant Toggle**: Add or remove products from wishlist with instant optimistic UI feedback.
- **Cloud Sync**: Synchronized across user sessions with the backend API.

### 👤 Profile & Personalization
- **Customizable Avatar**: Integrated **Fluttermoji** SVG avatar customizer plus camera/gallery photo upload (`image_picker`).
- **Language Switcher**: Full bilingual support for **English** and **Khmer (ភាសាខ្មែរ)** with instant in-app switching and persistence.
- **Theme Switcher**: Dark Mode and Light Mode support with smooth transitions.
- **Responsive Layout**: Adaptive UI handling phone, tablet, and web desktop displays.

---

## 🎨 Design System

- **Design Language**: Material 3 with customized Emerald Green color palette (`#23AA49`).
- **Typography**: Clean, readable GoogleSans typography with fallback support.
- **Micro-Interactions**: Skeleton shimmer loaders (`shimmer`), custom fade and slide page route transitions, hero animations on product images.
- **Persistent Navigation**: 4-tab bottom navigation shell (`StatefulShellRoute.indexedStack`) maintaining individual tab history across Home, Explore, Wishlist, and Profile.

---

## 🏗️ Architecture & Project Structure

The project follows a **Feature-First Clean Architecture** pattern:

```text
lib/
├── core/                        # Core system utilities & configurations
│   ├── api/                     # Dio HTTP client, interceptors, API endpoints, error handling
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   ├── app_exception.dart
│   │   ├── dio_client.dart
│   │   └── interceptors/        # Auth token injector, refresh token interceptor
│   ├── localization/            # Multi-language support (AppLocalizations, LocaleProvider)
│   ├── router/                  # GoRouter configuration, route guards, custom page transitions
│   ├── services/                # Geolocation, storage services
│   ├── storage/                 # Secure storage (tokens) & shared preferences
│   ├── theme/                   # AppTheme (Light & Dark themes, color tokens, typography)
│   └── utils/                   # Formatting, validators, debounce helpers, snackbars
│
├── features/                    # Feature modules (Feature-First)
│   ├── auth/                    # Login, Register, Forgot Password, Auth State Controller
│   ├── brands/                  # Brand listing & brand-specific products
│   ├── cart/                    # Cart controller, Checkout, Coupon & ABA PayWay modal
│   ├── categories/              # Category listing & filtered views
│   ├── home/                    # Home screen, banner slider, location selector
│   ├── orders/                  # Order history, delivery timeline, product reviews, receipt viewer
│   ├── products/                # Product details, reviews, search suggestions, related products
│   ├── profile/                 # Profile management, Fluttermoji avatar customizer
│   ├── splash/                  # Animated splash screen & initialization wrapper
│   └── wishlist/                # Wishlist state & sync
│
├── shared/                      # Reusable components across features
│   ├── models/                  # Shared data models
│   ├── providers/               # Global providers (theme, locale, auth)
│   └── widgets/                 # Reusable UI widgets (cards, buttons, inputs, shimmers)
│
└── main.dart                    # Application entry point with ProviderScope
```

---

## 🛠️ Tech Stack & Dependencies

| Category | Package / Library | Description |
|---|---|---|
| **Framework** | [Flutter SDK](https://flutter.dev) (Dart 3) | Cross-platform UI toolkit (Android, iOS, Web) |
| **State Management** | `flutter_riverpod`, `riverpod_annotation` | Reactive, compile-safe state management |
| **Navigation** | `go_router` | Declarative routing with stateful bottom navigation |
| **Networking** | `dio` | Powerful HTTP client with token refresh & interceptors |
| **Storage** | `flutter_secure_storage`, `shared_preferences` | Encrypted token storage & local key-value store |
| **Maps & Location** | `flutter_map`, `latlong2`, `geolocator`, `geocoding` | OpenStreetMap rendering & reverse-geocoding |
| **Code Generation** | `freezed`, `json_serializable`, `build_runner` | Immutable data classes & JSON serialization |
| **Image & Media** | `cached_network_image`, `flutter_svg`, `image_picker` | Image caching, vector SVG, camera/gallery picking |
| **Avatars** | `fluttermoji` | In-app customizable SVG avatar generator |
| **UI Enhancements** | `shimmer`, `webview_flutter`, `url_launcher` | Loading skeletons, webviews (ABA PayWay), URL launching |

---

## 🚀 Getting Started

### Prerequisites

Ensure your development environment is set up with:
- **Flutter SDK**: `>= 3.11.5` ([Install Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `>= 3.0.0` (bundled with Flutter)
- **Xcode** (for iOS development, macOS only) + CocoaPods (`brew install cocoapods`)
- **Android Studio / Android SDK** (for Android development)
- **Google Chrome** (for Web debugging)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/flutter_e_commerce.git
   cd flutter_e_commerce
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (Freezed & Riverpod):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run on connected device / simulator / browser:**
   ```bash
   flutter run
   ```

---

## 🌐 Backend & API

The application connects to a **Laravel REST API**:
- **Base URL**: `https://e-commers-laravel.vercel.app/api`
- **Authentication**: Bearer JWT tokens with automatic token refreshing via Dio interceptors.
- **Postman Collection**: A complete Postman collection is included in the project root: [`postman_collection.json`](./postman_collection.json). Import it into Postman to explore and test all API endpoints.

---

## 🧪 Testing & Code Quality

Run tests and linter to verify code stability:

```bash
# Run unit and widget tests
flutter test

# Run static code analysis
flutter analyze
```

---

## 📦 Building for Production

### Android
```bash
# Build Android APK (split per ABI for smaller size)
flutter build apk --split-per-abi

# Build Android App Bundle (for Google Play Console)
flutter build appbundle
```

### iOS
```bash
# Build iOS IPA (requires macOS and Xcode)
flutter build ipa
```

### Web
```bash
# Build Web production bundle
flutter build web --release
```

---

## 📄 License

This project is developed for academic purposes for **Project Final Year 4 (Group SU20)**. All rights reserved.
