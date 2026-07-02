// Music screen

Textfield musicPromptField;
TextField musicLyricsField;
Toggle musicInstrumentalToggle;
Slider musicDurationSlider;
Button musicGenerateButton, musicPlayButton;

volatile boolean musicBusy = false;
volatile String musicOutFile = null;
volatile String musicStatus = "";

void setupMusicScreen() {
  int x = 20;
  int y = 60;

  musicPromptField = cp5.addTextfield("musicPrompt")
    .setPosition(x, y)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("upbeat synthwave, driving bassline")
    .setLabel("style");

  musicLyricsField = new TextField(x, y + 50, 300, 80, "lyrics",
    "[verse]\nyour lyrics here\n[chorus]\n...", "[inst]", false, color(0, 116, 217));

  musicInstrumentalToggle = cp5.addToggle("musicInstrumentalToggle")
    .setPosition(x + 320, y + 50)
    .setSize(40, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setLabel("instrumental");

  musicDurationSlider = cp5.addSlider("musicDuration")
    .setPosition(x, y + 150)
    .setSize(150, 15)
    .setRange(10, 120)
    .setValue(30)
    .setLabel("duration");

  musicGenerateButton = cp5.addButton("btnGenerateMusic")
    .setPosition(x, y + 190)
    .setLabel("generate");

  musicPlayButton = cp5.addButton("btnReplayMusic")
    .setPosition(x + 80, y + 190)
    .setLabel("replay");

  musicControllers.add(musicPromptField);
  musicControllers.add(musicInstrumentalToggle);
  musicControllers.add(musicDurationSlider);
  musicControllers.add(musicGenerateButton);
  musicControllers.add(musicPlayButton);
}

void drawMusicScreen() {
  fill(0);
  textAlign(LEFT, CENTER);
  text("Music Generation", 100, 30);
  textAlign(LEFT, TOP);

  boolean instrumental = isInstrumental();

  if (!instrumental) {
    musicLyricsField.display();
  } else {
    fill(150);
    rect(musicLyricsField.x, musicLyricsField.y, musicLyricsField.w, musicLyricsField.h);
    fill(80);
    textAlign(LEFT, TOP);
    text("lyrics disabled (instrumental)", musicLyricsField.x + 4, musicLyricsField.y + 4);
  }

  fill(0);
  textAlign(LEFT, TOP);
  text(musicBusy ? musicStatus : "idle", 20, 280);
  if (musicOutFile != null) {
    text("output: " + musicOutFile, 20, 300);
  }
}

boolean isInstrumental() {
  return musicInstrumentalToggle.getState();
}

void musicMousePressed() {
  if (!isInstrumental()) {
    musicLyricsField.handleClick(mouseX, mouseY);
  } else {
    musicLyricsField.focused = false;
  }
}

void musicKeyPressed() {
  if (!isInstrumental()) {
    musicLyricsField.handleKey();
  }
}

void btnGenerateMusic() {
  if (musicBusy) return;
  if (musicPromptField.getText().trim().length() == 0) {
    println("Enter a prompt first.");
    return;
  }
  musicBusy = true;
  musicStatus = "submitting...";
  println("Submitting music task...");
  thread("generateMusic");
}

void btnReplayMusic() {
  if (musicOutFile != null) playAudioFile(musicOutFile);
}

void generateMusic() {
  try {
    JSONObject body = new JSONObject();
    body.setString("prompt", musicPromptField.getText());
    body.setString("lyrics", isInstrumental() ? "[inst]" : musicLyricsField.getText());
    body.setInt("audio_duration", (int) musicDurationSlider.getValue());
    body.setInt("inference_steps", 8);
    body.setString("audio_format", "wav");

    String submitResp = httpPostJsonString(MUSIC_BASE + "/release_task", body.toString());
    JSONObject submitObj = parseJSONObject(submitResp);
    String taskId = submitObj.getJSONObject("data").getString("task_id");
    println("Task: " + taskId);

    String filePath = null;
    int attempts = 0;
    int maxAttempts = 120;
    while (filePath == null && attempts < maxAttempts) {
      Thread.sleep(5000);
      attempts++;
      musicStatus = "rendering... (" + attempts + "/" + maxAttempts + ")";

      JSONArray idArr = new JSONArray();
      idArr.append(taskId);
      JSONObject pollBody = new JSONObject();
      pollBody.setJSONArray("task_id_list", idArr);

      String pollResp = httpPostJsonString(MUSIC_BASE + "/query_result", pollBody.toString());
      JSONObject pollObj = parseJSONObject(pollResp);
      JSONArray dataArr = pollObj.getJSONArray("data");
      JSONObject first = dataArr.getJSONObject(0);
      int status = first.getInt("status");

      if (status == 1) {
        JSONArray resultArr = parseJSONArray(first.getString("result"));
        JSONObject resultObj = resultArr.getJSONObject(0);
        filePath = resultObj.getString("file");
      } else if (status < 0) {
        throw new Exception("Task failed (status " + status + ")");
      }
    }

    if (filePath == null) {
      throw new Exception("Timed out.");
    }

    musicStatus = "downloading...";
    byte[] audio = httpGetBytes(MUSIC_BASE + filePath);
    musicOutFile = saveWavToOutput(audio, "music");
    musicStatus = "done";
    println("Music done. Playing...");
    playAudioFile(musicOutFile);
  } catch (Exception e) {
    musicStatus = "error";
    println("Music error: " + e.getMessage());
  } finally {
    musicBusy = false;
  }
}
