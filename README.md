# 🕯️ Enola — The Map of Riddles

A Flutter app that turns school book pages into interactive quest maps.  
Students scan pages → AI generates riddles → they play through a fantasy RPG-style map.

---

## Features

- 📸 **Scan book pages** — photograph one or more pages with your camera
- 🤖 **AI riddle generation** — Gemini 1.5 Flash reads the text and crafts riddles
- 🗺️ **Quest map** — riddles displayed as nodes on a torch-lit fantasy path
- ✅ **Multiple choice** — classic 4-option questions
- 🔢 **Ordering** — drag items into the correct sequence
- 🏆 **Score & rank** — Grand Sage / Scholar / Apprentice / Novice
- 📱 **100% local** — all data stored on-device via Isar, no backend needed

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Generate Isar schemas

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Add your Gemini API key

Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey).

Then build with:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Or for permanent local development, create a `launch.json` (VS Code) with:

```json
{
  "configurations": [
    {
      "name": "Enola",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=GEMINI_API_KEY=YOUR_KEY"]
    }
  ]
}
```

---

## Project Structure

```
lib/
  main.dart                  # Entry point
  models/                    # Isar schemas
    riddle_map.dart
    riddle.dart
    play_session.dart
  services/
    isar_service.dart        # DB singleton
    gemini_service.dart      # Gemini API client
    riddle_generation_service.dart
    map_repository.dart      # CRUD
  providers/
    map_providers.dart       # Riverpod
  screens/
    home/                    # Map list
    map_detail/              # RPG path view
    create_map/              # Create/edit + add riddles
    scan/                    # Camera capture + AI generation
    play/                    # Gameplay + results
  widgets/
    fantasy_widgets.dart     # Shared RPG components
  theme/
    enola_theme.dart
```

---

## Riddle Types

| Type | Description |
|------|-------------|
| `multipleChoice` | Question + 4 choices, one correct |
| `ordering` | List of items to drag into correct order |

New types can be added by extending the `RiddleType` enum and handling them in the play screen.

---

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` |
| Storage | `isar` |
| AI | `google_generative_ai` (Gemini 1.5 Flash) |
| Camera | `image_picker` |
| Animation | `flutter_animate` |
