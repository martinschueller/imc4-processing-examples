# IMC4 Processing Examples

A Processing launcher plus independent sketch folders for the voice stack and fluid renderer demos.

Open this sketch in Processing:

```text
imc4_processing_examples/imc4_processing_examples.pde
```

The launcher starts each module as a separate Processing process:

- Speech-to-Text
- Text-to-Speech
- Soundscape generation
- Music generation
- Fluid CPU
- Fluid GPU
- OpenCV hand catch

The fluid windows include a ControlP5 `particles` slider, so you can compare CPU and GPU performance at different particle counts. The OpenCV example uses webcam contour tracking to catch falling balls with your hand.

Each module folder can also be opened and run directly in Processing.

## Requirements

- Processing 4.x
- ControlP5, installed via **Sketch > Import Library > Add Library**
- Video library, for the OpenCV webcam example
- OpenCV for Processing, for the hand catch example
- `processing-java` command-line tool for launching modules from the start sketch

On macOS, the launcher tries common absolute paths such as `/usr/local/bin/processing-java` and `/opt/homebrew/bin/processing-java`, then falls back to the Processing app CLI and your shell `PATH`.

## API Setup

Voice and music sketches need a bearer token. From the repo root:

```bash
cp .env.example .env
```

Edit `.env` and set your token:

```env
API_KEY=your-token-here
```

The sketches read `.env` from the repo root and write generated audio to `output/`. Both paths are gitignored.

## Sketch Folders

```text
imc4_processing_examples/   start launcher
stt/                        speech-to-text
tts/                        text-to-speech
soundscape/                 soundscape generation
music/                      music generation
fluid_cpu/                  Java2D particle simulation
fluid_gpu/                  P2D particle simulation
hand_pose/                  OpenCV webcam hand catch game
```

Processing compiles every `.pde` file in a sketch folder as a tab. The previous symlink approach linked shared files into every example folder, so each folder appeared to contain every sketch. This version avoids symlinks: every module is a real independent sketch folder.
