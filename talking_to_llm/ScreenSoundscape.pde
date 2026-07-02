// Soundscape screen

Textfield soundscapePromptField, soundscapeNegativeField;
Slider soundscapeSecondsSlider, soundscapeStepsSlider, soundscapeCfgSlider;
Button soundscapeGenerateButton, soundscapePlayButton;

volatile boolean soundscapeBusy = false;
volatile String soundscapeOutFile = null;

void setupSoundscapeScreen() {
  int x = 20;
  int y = 60;

  soundscapePromptField = cp5.addTextfield("scapePrompt")
    .setPosition(x, y)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("gentle rain on a tin roof")
    .setLabel("prompt");

  soundscapeNegativeField = cp5.addTextfield("scapeNegative")
    .setPosition(x, y + 40)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("")
    .setLabel("negative");

  soundscapeSecondsSlider = cp5.addSlider("scapeSeconds")
    .setPosition(x, y + 90)
    .setSize(150, 15)
    .setRange(4, 47)
    .setValue(30)
    .setLabel("seconds");

  soundscapeStepsSlider = cp5.addSlider("scapeSteps")
    .setPosition(x, y + 115)
    .setSize(150, 15)
    .setRange(10, 60)
    .setValue(40)
    .setLabel("steps");

  soundscapeCfgSlider = cp5.addSlider("scapeCfg")
    .setPosition(x, y + 140)
    .setSize(150, 15)
    .setRange(1, 15)
    .setValue(7)
    .setLabel("cfg");

  soundscapeGenerateButton = cp5.addButton("btnGenerateScape")
    .setPosition(x, y + 180)
    .setLabel("generate");

  soundscapePlayButton = cp5.addButton("btnReplayScape")
    .setPosition(x + 80, y + 180)
    .setLabel("replay");

  soundscapeControllers.add(soundscapePromptField);
  soundscapeControllers.add(soundscapeNegativeField);
  soundscapeControllers.add(soundscapeSecondsSlider);
  soundscapeControllers.add(soundscapeStepsSlider);
  soundscapeControllers.add(soundscapeCfgSlider);
  soundscapeControllers.add(soundscapeGenerateButton);
  soundscapeControllers.add(soundscapePlayButton);
}

void drawSoundscapeScreen() {
  fill(0);
  textAlign(LEFT, CENTER);
  text("Soundscape Generation", 100, 30);
  
  textAlign(LEFT, TOP);
  text(soundscapeBusy ? "working..." : "idle", 20, 280);
  if (soundscapeOutFile != null) {
    text("output: " + soundscapeOutFile, 20, 300);
  }
}

void btnGenerateScape() {
  if (soundscapeBusy) return;
  if (soundscapePromptField.getText().trim().length() == 0) {
    println("Enter a prompt first.");
    return;
  }
  soundscapeBusy = true;
  println("Generating soundscape...");
  thread("generateSoundscape");
}

void btnReplayScape() {
  if (soundscapeOutFile != null) playAudioFile(soundscapeOutFile);
}

void generateSoundscape() {
  try {
    JSONObject body = new JSONObject();
    body.setString("prompt", soundscapePromptField.getText());
    body.setInt("seconds", (int) soundscapeSecondsSlider.getValue());
    body.setInt("steps", (int) soundscapeStepsSlider.getValue());
    body.setFloat("cfg_scale", soundscapeCfgSlider.getValue());
    if (soundscapeNegativeField.getText().trim().length() > 0) {
      body.setString("negative_prompt", soundscapeNegativeField.getText());
    }

    byte[] audio = httpPostJsonBytes(SOUNDSCAPE_BASE + "/generate", body.toString());
    soundscapeOutFile = saveWavToOutput(audio, "soundscape");
    println("Soundscape done. Playing...");
    playAudioFile(soundscapeOutFile);
  } catch (Exception e) {
    println("Soundscape error: " + e.getMessage());
  } finally {
    soundscapeBusy = false;
  }
}
