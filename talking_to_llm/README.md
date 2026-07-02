# Talking to LLM — Voice & Soundscape Stack

A minimal [Processing](https://processing.org/) sketch that demos four audio modules against the IMC4 voice stack:

| Module | Endpoint | Description |
|--------|----------|-------------|
| Speech-to-Text | gateway `/stt` | Transcribe microphone input |
| Text-to-Speech | gateway `/tts` | Synthesize speech from text |
| Soundscape | Stable Audio Open `/generate` | Generate ambient soundscapes / SFX |
| Music | ACE-Step `/release_task` + `/query_result` | Generate music from lyrics |

UI via [ControlP5](https://github.com/sojamo/controlp5) (default styling). HTTP calls use plain `java.net`.

## Requirements

- Processing 4.x
- ControlP5 — install via **Sketch → Import Library → Add Library**

## Setup

1. Open `talking_to_llm.pde` in Processing.
2. Copy `.env.example` to `.env` and set your bearer token:

   ```bash
   cp .env.example .env
   ```

   ```env
   API_KEY=your-token-here
   ```

   The `.env` file is gitignored and read at startup via `sketchPath(".env")`.

3. Run the sketch. Pick a module from the home screen.

Default service URLs are configured in `talking_to_llm.pde` (`GATEWAY_BASE`, `MUSIC_BASE`, `SOUNDSCAPE_BASE`).

## Project layout

| File | Role |
|------|------|
| `talking_to_llm.pde` | Main sketch, screen routing |
| `ScreenHome.pde` | Module launcher |
| `ScreenSTT.pde` / `ScreenTTS.pde` | Speech I/O demos |
| `ScreenSoundscape.pde` / `ScreenMusic.pde` | Audio generation demos |
| `ConfigUtil.pde` | `.env` loading |
| `NetUtil.pde` | HTTP helpers |
| `AudioUtil.pde` | Playback utilities |
| `TextField.pde` | Custom multi-line input (music lyrics) |
