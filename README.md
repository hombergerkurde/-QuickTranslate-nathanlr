# QuickTranslate v2.4.0 - FINAL VERSION

## 🎯 Basiert auf Translomatic Struktur!

Nach Analyse von Translomatic wurden folgende kritische Änderungen gemacht:

---

## ✅ WAS GEÄNDERT WURDE:

### **1. Dependencies:**
```
VORHER: ellekit, preferenceloader
JETZT: mobilesubstrate, preferenceloader
```

### **2. Makefile:**
```makefile
export ARCHS = arm64 arm64e  # Beide Architekturen!
QuickTranslate_EXTRA_FRAMEWORKS = CydiaSubstrate  # Nicht Ellekit!
```

### **3. QuickTranslate.plist:**
```xml
<key>Bundles</key>
<array>
    <string>com.apple.UIKit</string>
    <string>com.apple.Translation</string>  ← NEU!
</array>
```

**WICHTIG:** Wird zu BINÄR Format konvertiert wie Translomatic!

### **4. GitHub Actions:**
- Konvertiert .plist zu binär Format
- Baut Universal Binary (arm64 + arm64e)
- Nutzt CydiaSubstrate Framework

---

## 📦 Installation:

1. .deb von GitHub Actions herunterladen
2. Auf iPhone kopieren
3. Installieren:
   ```bash
   dpkg -i QuickTranslate-v2.4.0.deb
   killall -9 SpringBoard
   ```

---

## 🎯 Kompatibilität:

- **nathanlr rootless** ✅
- **iOS 15.0 - 18.x** ✅
- **arm64 + arm64e** ✅
- **CydiaSubstrate** ✅

---

## 🚀 Features:

- Text in allen Apps markieren und übersetzen
- 16 Sprachen verfügbar
- Schönes Overlay mit Original + Übersetzung
- Kopieren-Button

---

**Made by hombergerkurde - Based on Translomatic structure**
