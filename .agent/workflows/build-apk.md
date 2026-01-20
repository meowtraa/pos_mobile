---
description: Build APK for dev or prod environment
---

# Build Commands for Flutter Flavors

## Development Build

### Debug (untuk testing)
// turbo
```powershell
flutter run --flavor dev --dart-define=FLAVOR=dev
```

### Release APK
```powershell
flutter build apk --flavor dev --dart-define=FLAVOR=dev --release
```

Output: `build\app\outputs\flutter-apk\Macho's POS Dev v1.0.0-dev.apk`

---

## Production Build

### Debug (untuk testing)
// turbo
```powershell
flutter run --flavor prod --dart-define=FLAVOR=prod
```

### Release APK
```powershell
flutter build apk --flavor prod --dart-define=FLAVOR=prod --release
```

Output: `build\app\outputs\flutter-apk\Macho's POS Prod v1.0.0.apk`

---

## Build Both (Dev + Prod)
```powershell
flutter build apk --flavor dev --dart-define=FLAVOR=dev --release; flutter build apk --flavor prod --dart-define=FLAVOR=prod --release
```

---

## Notes

- **Dev** uses Firebase project: `pos-fire-d563d`
- **Prod** uses Firebase project: `machos-pos`
- Dev APK has `.dev` suffix on package name, so both can be installed simultaneously
- Dev app name shows "(Dev)" suffix for easy identification
