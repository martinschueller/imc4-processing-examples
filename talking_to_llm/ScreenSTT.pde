// Speech-to-Text screen

Button sttRecordButton, sttTranscribeButton, sttReplayButton;
Textarea sttTranscriptArea;

volatile boolean sttIsRecording = false;
volatile boolean sttBusy = false;
volatile byte[] sttRecordedWav = null;
long sttRecordStartMs = 0;

void setupSTTScreen() {
  int x = 20;
  int y = 60;

  sttRecordButton = cp5.addButton("btnRecordSTT")
    .setPosition(x, y)
    .setLabel("record");

  sttTranscribeButton = cp5.addButton("btnTranscribeSTT")
    .setPosition(x + 80, y)
    .setLabel("transcribe");

  sttReplayButton = cp5.addButton("btnReplaySTT")
    .setPosition(x + 170, y)
    .setLabel("replay");

  sttTranscriptArea = cp5.addTextarea("sttTranscript")
    .setPosition(x, y + 60)
    .setSize(400, 100)
    .setLineHeight(14)
    .setColor(color(0))
    .setColorBackground(color(255))
    .setText("(record, then transcribe)");

  sttControllers.add(sttRecordButton);
  sttControllers.add(sttTranscribeButton);
  sttControllers.add(sttReplayButton);
}

void drawSTTScreen() {
  fill(0);
  textAlign(LEFT, CENTER);
  text("Speech-to-Text", 100, 30);
  
  sttRecordButton.setLabel(sttIsRecording ? "stop" : "record");
  sttTranscribeButton.setLabel(sttBusy ? "working..." : "transcribe");

  if (sttIsRecording) {
    float secs = (millis() - sttRecordStartMs) / 1000.0;
    text("recording: " + nf(secs, 0, 1) + "s", 260, 64);
  }
}

void btnRecordSTT() {
  if (sttBusy) return;
  if (!sttIsRecording) {
    if (startRecording()) {
      sttIsRecording = true;
      sttRecordStartMs = millis();
      sttTranscriptArea.setText("(recording...)");
      println("Recording started.");
    }
  } else {
    sttIsRecording = false;
    byte[] wav = stopRecording();
    sttRecordedWav = wav;
    println(wav != null ? "Recording stopped." : "Recording failed.");
  }
}

void btnTranscribeSTT() {
  if (sttBusy || sttRecordedWav == null || sttIsRecording) return;
  sttBusy = true;
  println("Transcribing...");
  thread("transcribeRecording");
}

void btnReplaySTT() {
  if (sttRecordedWav != null) playAudioBytes(sttRecordedWav);
}

void transcribeRecording() {
  try {
    byte[] result = httpPostMultipartFile(GATEWAY_BASE + "/stt", "file", "recording.wav", sttRecordedWav);
    String json = new String(result, "UTF-8");
    String text;
    try {
      JSONObject obj = parseJSONObject(json);
      text = obj != null && obj.hasKey("text") ? obj.getString("text") : json;
    } catch (Exception parseErr) {
      text = json;
    }
    sttTranscriptArea.setText(text);
    println("Transcription done.");
  } catch (Exception e) {
    println("STT error: " + e.getMessage());
  } finally {
    sttBusy = false;
  }
}
