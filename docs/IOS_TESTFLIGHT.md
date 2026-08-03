# iOS / TestFlight — הכנה

נדרש Mac עם Xcode.

```bash
cd ios
pod install
open Runner.xcworkspace
```

1. Signing & Capabilities: Team + Bundle ID ייחודי  
2. HealthKit capability (כבר יש entitlements)  
3. Background Modes: Audio + Processing  
4. Archive → Distribute → TestFlight  
5. App Privacy: Heart Rate, Microphone, Contacts, Health  

מדיניות פרטיות: קישור ל־`docs/privacy.html` אחרי GitHub Pages.
