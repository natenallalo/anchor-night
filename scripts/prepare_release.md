# הכנת Release

## 1. Android SDK
התקינו Android Studio, אשרו SDK, ואז:
```bash
puro flutter doctor --android-licenses
puro flutter config --android-sdk "C:\Users\User\AppData\Local\Android\sdk"
```

## 2. מפתח חתימה (פעם אחת)
```bash
mkdir keystore
keytool -genkey -v -keystore keystore/anchor-night-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias anchor_night
copy android\key.properties.example android\key.properties
```
עדכנו סיסמאות ב־`android/key.properties` (אל תעלו לקובץ git).

## 3. אייקון
```bash
puro flutter pub get
puro dart run flutter_launcher_icons
```

## 4. בילד
```bash
puro flutter test
puro flutter build appbundle --release
```
הקובץ: `build/app/outputs/bundle/release/app-release.aab`

## 5. מדיניות פרטיות מקוונת
העלו את תיקיית `docs/` ל־GitHub Pages (Settings → Pages → Deploy from `/docs`).
עדכנו את `AppConfig.privacyPolicyUrl` לכתובת האמיתית.

## 6. צילומי מסך
הריצו על מכשיר אמיתי + שעון, וצלמו את 5 המסכים ב־`STORE.md`.
ניתן גם להשתמש בבילד web: `puro flutter run -d chrome`
