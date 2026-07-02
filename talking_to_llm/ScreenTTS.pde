// Text-to-Speech screen

Textfield ttsPromptField;
ScrollableList ttsVoiceList;
Button ttsGenerateButton, ttsPlayButton;

String[] ttsVoices = {"tara", "leah", "jess", "leo", "dan", "mia", "zac", "zoe"};
int ttsVoiceIndex = 0;

volatile boolean ttsBusy = false;
volatile String ttsOutFile = null;

void setupTTSScreen() {
  int x = 20;
  int y = 60;

  ttsPromptField = cp5.addTextfield("ttsPrompt")
    .setPosition(x, y)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("Hello, this is a test.")
    .setLabel("text");

  ttsVoiceList = cp5.addScrollableList("ttsVoice")
    .setPosition(x + 420, y)
    .setSize(100, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.DROPDOWN)
    .setLabel("voice");
  for (int i = 0; i < ttsVoices.length; i++) {
    ttsVoiceList.addItem(ttsVoices[i], i);
  }
  ttsVoiceList.setValue(0);
  ttsVoiceList.close();

  ttsGenerateButton = cp5.addButton("btnGenerateTTS")
    .setPosition(x, y + 50)
    .setLabel("generate");

  ttsPlayButton = cp5.addButton("btnReplayTTS")
    .setPosition(x + 80, y + 50)
    .setLabel("replay");

  ttsControllers.add(ttsPromptField);
  ttsControllers.add(ttsVoiceList);
  ttsControllers.add(ttsGenerateButton);
  ttsControllers.add(ttsPlayButton);
}

void drawTTSScreen() {
  fill(0);
  textAlign(LEFT, CENTER);
  text("Text-to-Speech", 100, 30);
  
  textAlign(LEFT, TOP);
  text(ttsBusy ? "working..." : "idle", 20, 140);
  if (ttsOutFile != null) {
    text("output: " + ttsOutFile, 20, 160);
  }
}

void btnGenerateTTS() {
  if (ttsBusy) return;
  String txt = ttsPromptField.getText();
  if (txt == null || txt.trim().length() == 0) {
    println("Enter text first.");
    return;
  }
  ttsVoiceIndex = (int) ttsVoiceList.getValue();
  ttsBusy = true;
  println("Generating TTS...");
  thread("generateTTS");
}

void btnReplayTTS() {
  if (ttsOutFile != null) playAudioFile(ttsOutFile);
}

void generateTTS() {
  try {
    JSONObject body = new JSONObject();
    body.setString("text", ttsPromptField.getText());
    body.setString("voice", ttsVoices[ttsVoiceIndex]);

    byte[] audio = httpPostJsonBytes(GATEWAY_BASE + "/tts", body.toString());
    ttsOutFile = saveWavToOutput(audio, "tts");
    println("TTS done. Playing...");
    playAudioFile(ttsOutFile);
  } catch (Exception e) {
    println("TTS error: " + e.getMessage());
  } finally {
    ttsBusy = false;
  }
}
