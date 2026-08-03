# צילומי מסך לחנות (web preview)

```bash
puro flutter build web --release --no-tree-shake-icons
python -m http.server 8765 --directory build/web
```

פתחו בדפדפן (רוחב מובייל מומלץ 390×844):

| מסך | כתובת |
|---|---|
| Onboarding | http://127.0.0.1:8765/?preview=onboarding |
| הגנת לילה | http://127.0.0.1:8765/?preview=night |
| קרקוע | http://127.0.0.1:8765/?preview=grounding |
| בוקר | http://127.0.0.1:8765/?preview=morning |

שמרו PNG ל־`store_assets/screenshots/`.
