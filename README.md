# Spltly — Flutter + Supabase

A Splitwise alternative built with Flutter and Supabase. ID-based (no phone numbers), glassmorphism UI, fully working auth, groups, expenses, splits, file uploads, and RLS security.

---

## Stack
- **Frontend**: Flutter (iOS + Android)
- **Backend**: Supabase (Auth + PostgreSQL + Storage + RLS)

---

## Setup instructions

### 1. Install Flutter
Download from flutter.dev — follow the install guide for your OS.
Verify with: `flutter doctor`

### 2. Clone this repo
```bash
git clone https://github.com/YOUR_USERNAME/spltly.git
cd spltly
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Run the Supabase SQL
Go to your Supabase project → SQL Editor → paste and run the full schema SQL (see supabase_schema.sql in this repo).

### 5. Create the Storage bucket
Supabase Dashboard → Storage → New bucket → Name: `receipts` → Private

### 6. Environment
Your `.env` file is already configured with your Supabase URL and anon key.
⚠️ Never commit `.env` to GitHub — it's in `.gitignore`.

### 7. Run the app
```bash
# iOS simulator
flutter run -d ios

# Android emulator
flutter run -d android

# Check available devices
flutter devices
```

---

## Project structure

```
lib/
  main.dart                    # Entry point, Supabase init
  router/
    app_router.dart            # GoRouter with auth guard
  models/
    models.dart                # All data models
  services/
    supabase_service.dart      # All Supabase operations
  utils/
    app_theme.dart             # Glassmorphism dark theme
  screens/
    auth/
      splash_screen.dart
      login_screen.dart
      signup_screen.dart
    dashboard/
      dashboard_screen.dart
    groups/
      groups_screen.dart       # Groups + GroupDetail + CreateGroup
    expenses/
      add_expense_screen.dart  # AddExpense + ExpenseDetail
    friends/
      friends_screen.dart      # Friends + Settings
    shell_screen.dart          # Bottom navigation
  widgets/
    glass_card.dart            # GlassCard + AppButton + AppTextField
                               # AmbientBackground + GroupCardWidget
                               # ExpenseItemWidget
```

---

## Features
- ✅ Email/password auth via Supabase
- ✅ Auto-generated Spltly ID (SPL-XXXXXX) on signup
- ✅ Create groups, add members by Spltly ID
- ✅ Add expenses with equal/exact/percent split
- ✅ Attach receipts (camera, gallery, PDF)
- ✅ Balance calculation per group and overall
- ✅ Settle up individual splits
- ✅ RLS — users only see their own data
- ✅ Glassmorphism dark UI
- ✅ Pull to refresh everywhere

---

## Deploying to App Store
1. Open `ios/` in Xcode
2. Set your Bundle ID and Apple Developer account
3. Archive → Distribute → App Store Connect
(Requires a Mac and Apple Developer account — $99/year)
