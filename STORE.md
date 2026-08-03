# הכנה לחנויות — עוגן לילה

## סטטוס מוכנות

| פריט | סטטוס |
|---|---|
| ליבת לילה + דופק + קרקוע | ✅ |
| רקע / Foreground Service | ✅ |
| יומן בוקר | ✅ |
| אנשי חירום + קווי סיוע | ✅ |
| Onboarding + דיסקליימר | ✅ |
| מדיניות פרטיות באפליקציה | ✅ |
| דף פרטיות לאירוח (`docs/`) | ✅ מוכן להעלאה |
| אייקון חנות (Android/iOS) | ✅ נוצר מ־`assets/branding/icon.png` |
| חתימת Release (תבנית) | ✅ `key.properties.example` |
| Android SDK במחשב זה | ❌ צריך התקנה |
| קישור פרטיות חי באינטרנט | ⏳ אחרי GitHub Pages |
| צילומי מסך ממכשיר | ⏳ ידני |
| AAB / IPA | ⏳ אחרי SDK |

## שם
- עברית: עוגן לילה
- אנגלית: AnchorNight  
- Package: `com.anchornight.app.anchor_night`

## תיאור קצר
הגנת לילה עדינה למתמודדי פוסט־טראומה — זיהוי, עוגן קולי וקרקוע.

## תיאור מלא
עוגן לילה הוא כלי תמיכה ללילה עבור מתמודדי פוסט־טראומה.
האפליקציה מנטרת בעדינות מדדים מהשעון/המכשיר, מפעילה התערבות רכה (רטט ו/או עוגן קולי), ומציעה מסך קרקוע עם אנשי קשר וקווי סיוע.

חשוב: כלי תמיכה בלבד — אינו אבחון או טיפול רפואי.

## מדיניות פרטיות
1. הקובץ המקומי: [`docs/privacy.html`](docs/privacy.html)
2. העלו את `docs/` ל־GitHub Pages
3. עדכנו את `AppConfig.privacyPolicyUrl` ב־`lib/app/app_config.dart`
4. הדביקו את הקישור ב־Play Console / App Store Connect

## הצעדים שלך עכשיו (חובה)
פעל לפי [`scripts/prepare_release.md`](scripts/prepare_release.md):

1. התקן **Android Studio + SDK**
2. צור keystore והעתק ל־`android/key.properties`
3. `puro flutter build appbundle --release`
4. פרסם `docs/` ל־GitHub Pages
5. צלם 5 מסכים במכשיר אמיתי (+ שעון)

## צילומי מסך נדרשים
1. Onboarding / דיסקליימר  
2. הגנת לילה + חיבור שעון  
3. מסך קרקוע  
4. יומן בוקר  
5. אנשי חירום + קווי סיוע  

## הרשאות להצהרה בחנות
- Health data (heart rate)
- Microphone
- Contacts (אופציונלי)
- Notifications / Background

## נתיב עבודה מומלץ
הפרויקט הפעיל נמצא ב־`C:\dev\anchor_night` (נתיב ASCII — נדרש לבילדים ב־Windows).
בילד web מוכן ב־`build/web`.
צילום ראשון נשמר ב־`store_assets/screenshots/01-onboarding.png`.
