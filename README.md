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

The fluid windows include a ControlP5 `particles` slider, so you can compare CPU and GPU performance at different particle counts.

Each module folder can also be opened and run directly in Processing.

## Requirements

- Processing 4.x
- ControlP5, installed via **Sketch > Import Library > Add Library**
- `processing-java` command-line tool for launching modules from the start sketch

On macOS, the launcher first tries `/Applications/Processing.app/Contents/MacOS/processing-java`, then falls back to `processing-java` on your `PATH`.

## API Setup

Copy the example env file and set your bearer token:

```bash
cp talking_to_llm/.env.example talking_to_llm/.env
```

```env
API_KEY=your-token-here
```

The voice/music sketches read `talking_to_llm/.env` and write generated audio to `talking_to_llm/output/`.

## Sketch Folders

```text
imc4_processing_examples/   start launcher
stt/                        speech-to-text
tts/                        text-to-speech
soundscape/                 soundscape generation
music/                      music generation
fluid_cpu/                  Java2D particle simulation
fluid_gpu/                  P2D particle simulation
```

Processing compiles every `.pde` file in a sketch folder as a tab. The previous symlink approach linked shared files into every example folder, so each folder appeared to contain every sketch. This version avoids symlinks: every module is a real independent sketch folder.
