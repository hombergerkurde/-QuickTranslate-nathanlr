# QuickTranslate v3.0 - Mit AltList Integration!

## 🎉 KOMPLETT NEU!

### ✨ Neue Features:

1. **🌐 Button unter markiertem Text**
   - Kein Menü mehr - Button erscheint direkt unter der Auswahl!
   
2. **📱 App-Auswahl mit AltList**
   - Wähle in welchen Apps der Tweak aktiv sein soll
   - System-Apps und User-Apps getrennt
   
3. **💬 Kompaktes Popup**
   - Kleines, schönes Fenster mit Übersetzung
   - Kopieren-Button
   - Schließen-Button
   
4. **⚡ Sofortige Übersetzung**
   - Text markieren → Button drücken → Fertig!

---

## 📦 Installation:

**Wichtig:** AltList muss installiert sein!

```bash
# AltList installieren (aus Opa334's Repo)
# Dann QuickTranslate installieren:
dpkg -i QuickTranslate-v3.0.0.deb
killall -9 SpringBoard
```

---

## ⚙️ Einstellungen:

**Einstellungen → QuickTranslate**

1. **Apps aktivieren**
   - Öffne die App-Liste
   - Wähle Apps aus (z.B. Safari, WhatsApp, etc.)
   - Wenn keine Apps ausgewählt: Überall aktiv!

2. **Zielsprache**
   - 13 Sprachen verfügbar
   - Standard: Deutsch

---

## 🎮 Verwendung:

1. **Öffne eine App** (z.B. Safari)
2. **Markiere Text** (langes Drücken)
3. **"🌐 Übersetzen" Button** erscheint unter dem Text
4. **Drücke drauf**
5. **Popup** zeigt die Übersetzung
6. **Kopieren** oder **Schließen**

---

## 🔧 Technische Details:

- **Hook:** UITextSelectionView
- **Dependencies:** mobilesubstrate, preferenceloader, AltList
- **Architekturen:** arm64 + arm64e
- **Kompatibel:** nathanlr rootless, iOS 15-18

---

## 🎯 Unterschiede zu v2.x:

| Feature | v2.x | v3.0 |
|---------|------|------|
| Auslöser | Menü-Eintrag | Button unter Text |
| App-Auswahl | Keine | ✅ Mit AltList |
| Popup | Groß | Kompakt |
| UI | Standard | Modern |

---

**Made by hombergerkurde - v3.0 with AltList!** 🚀
