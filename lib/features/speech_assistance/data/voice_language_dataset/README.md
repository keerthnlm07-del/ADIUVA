# ADIUVA Global Multilingual Voice Control Dataset

Master Voice Phrases & Response Dataset for ADIUVA Global Voice Control across 5 supported Indian languages:
- **English (`en-IN`)**
- **Telugu (`te-IN`)**
- **Tamil (`ta-IN`)**
- **Kannada (`kn-IN`)**
- **Hindi (`hi-IN`)**

---

## Dataset Architecture & Design Principles

1. **Dual Representation**:
   - **Line 1**: Native script (rendered on TOP in UI, spoken ONLY by TTS for natural regional accent).
   - **Line 2**: Exact same-sentence Latin transliteration (rendered UNDERNEATH in UI).

2. **Strict Transliteration Rule**:
   - Transliteration is **NOT** an English translation.
   - Example: Native = `నేను ఎక్కడ ఉన్నాను?`, Transliteration = `Nenu ekkada unnanu?`.

3. **Code-Switching / Mixed-Language Awareness**:
   - Natural spoken combinations of English keywords + regional verbs/suffixes (e.g. `"Location చూపించు"`, `"Location காட்டுங்க"`, `"Location ತೋರಿಸು"`, `"Location बताओ"`) resolve to a single canonical intent (`open_location`).

4. **Location Hierarchy Formatting**:
   - Geographic hierarchy: `Village → Post → City/Town → Taluk/Mandal → District → State → Country`.
   - Filters out raw lat/long coordinates, plus codes (e.g. `Q900+7`), house numbers, and standalone 6-digit PIN codes.

5. **False-Positive Protection**:
   - Word boundaries (`\b...`) prevent partial word collisions (e.g., `"relocation"` will never trigger `open_location`).

---

## Intent Coverage

Each major intent features 20–30 natural spoken variations per language:
- `open_location`: Location & Where Am I
- `go_home`: Go Home / Main Dashboard
- `go_back`: Go Back / Previous Screen
- `emergency_sos`: Emergency SOS / Danger Alert
- `help`: Help & Voice Commands
- `open_visual_assistance`: Visual Assistance
- `object_detection`: Object Detection
- `ocr`: OCR Text Reader
- `scene_description`: Scene Description
- `document_reader`: Document & Storybook Reader
- `open_hearing_assistance`: Hearing Assistance & Captions
- `open_sign_language`: Sign Language Translator
- `open_translator`: Speech Translator
- `open_cognitive_assistance`: Cognitive Assistance
- `open_tasks`: Daily Tasks
- `open_reminders`: Medication & Reminders
- `open_notes`: Notes & Memory Notebook
- `open_physical_assistance`: Physical Assistance
- `open_speech_assistance`: Speech AI Assistant
- `change_language`: Language Switcher
