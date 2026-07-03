import controlP5.*;
import java.net.*;
import java.io.*;
import javax.sound.sampled.*;

final String MUSIC_BASE = "https://music.imc4.medienkultur.eu";

ControlP5 cp5;
Textfield promptField;
TextField lyricsField;
Toggle instrumentalToggle;
Slider durationSlider;
Button generateButton, replayButton;
Textarea logArea;

String API_KEY = "";
volatile boolean busy = false;
volatile String outFile = null;
volatile String status = "";
Clip currentClip;

void settings() {
  size(600, 500);
}

void setup() {
  loadConfig();
  cp5 = new ControlP5(this);

  promptField = cp5.addTextfield("prompt")
    .setPosition(20, 60)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("upbeat synthwave, driving bassline")
    .setLabel("style");

  lyricsField = new TextField(20, 110, 300, 80, "lyrics",
    "[verse]\nyour lyrics here\n[chorus]\n...", "[inst]", false, color(0, 116, 217));

  instrumentalToggle = cp5.addToggle("instrumental")
    .setPosition(340, 110)
    .setSize(40, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setLabel("instrumental");

  durationSlider = cp5.addSlider("duration")
    .setPosition(20, 220)
    .setSize(150, 15)
    .setRange(10, 120)
    .setValue(30)
    .setLabel("duration");

  generateButton = cp5.addButton("btnGenerate")
    .setPosition(20, 260)
    .setLabel("generate");
  replayButton = cp5.addButton("btnReplay")
    .setPosition(100, 260)
    .setLabel("replay");

  logArea = cp5.addTextarea("log")
    .setPosition(20, 380)
    .setSize(560, 100)
    .setLineHeight(14)
    .setColor(color(0))
    .setColorBackground(color(255));
}

void draw() {
  background(200);
  fill(0);
  textAlign(LEFT, CENTER);
  text("Music Generation", 20, 30);

  boolean instrumental = instrumentalToggle.getState();
  if (!instrumental) {
    lyricsField.display();
  } else {
    fill(150);
    rect(lyricsField.x, lyricsField.y, lyricsField.w, lyricsField.h);
    fill(80);
    textAlign(LEFT, TOP);
    text("lyrics disabled (instrumental)", lyricsField.x + 4, lyricsField.y + 4);
  }

  fill(0);
  textAlign(LEFT, TOP);
  text(busy ? status : "idle", 20, 300);
  if (outFile != null) {
    text("output: " + outFile, 20, 320);
  }
}

void mousePressed() {
  if (!instrumentalToggle.getState()) {
    lyricsField.handleClick(mouseX, mouseY);
  } else {
    lyricsField.focused = false;
  }
}

void keyPressed() {
  if (!instrumentalToggle.getState()) {
    lyricsField.handleKey(key);
  }
}

void btnGenerate() {
  if (busy) return;
  if (promptField.getText().trim().length() == 0) {
    log("Enter a prompt first.");
    return;
  }
  busy = true;
  status = "submitting...";
  log("Submitting music task...");
  thread("generateMusic");
}

void btnReplay() {
  if (outFile != null) playAudioFile(outFile);
}

void generateMusic() {
  try {
    JSONObject body = new JSONObject();
    body.setString("prompt", promptField.getText());
    body.setString("lyrics", instrumentalToggle.getState() ? "[inst]" : lyricsField.getText());
    body.setInt("audio_duration", (int) durationSlider.getValue());
    body.setInt("inference_steps", 8);
    body.setString("audio_format", "wav");

    String submitResp = httpPostJsonString(MUSIC_BASE + "/release_task", body.toString());
    JSONObject submitObj = parseJSONObject(submitResp);
    String taskId = submitObj.getJSONObject("data").getString("task_id");
    log("Task: " + taskId);

    String filePath = null;
    int attempts = 0;
    int maxAttempts = 120;
    while (filePath == null && attempts < maxAttempts) {
      Thread.sleep(5000);
      attempts++;
      status = "rendering... (" + attempts + "/" + maxAttempts + ")";

      JSONArray idArr = new JSONArray();
      idArr.append(taskId);
      JSONObject pollBody = new JSONObject();
      pollBody.setJSONArray("task_id_list", idArr);

      String pollResp = httpPostJsonString(MUSIC_BASE + "/query_result", pollBody.toString());
      JSONObject pollObj = parseJSONObject(pollResp);
      JSONArray dataArr = pollObj.getJSONArray("data");
      JSONObject first = dataArr.getJSONObject(0);
      int remoteStatus = first.getInt("status");

      if (remoteStatus == 1) {
        JSONArray resultArr = parseJSONArray(first.getString("result"));
        JSONObject resultObj = resultArr.getJSONObject(0);
        filePath = resultObj.getString("file");
      } else if (remoteStatus < 0) {
        throw new Exception("Task failed (status " + remoteStatus + ")");
      }
    }

    if (filePath == null) {
      throw new Exception("Timed out.");
    }

    status = "downloading...";
    byte[] audio = httpGetBytes(MUSIC_BASE + filePath);
    outFile = saveWav(audio, "music");
    status = "done";
    log("Music done. Playing...");
    playAudioFile(outFile);
  } catch (Exception e) {
    status = "error";
    log("Music error: " + e.getMessage());
  } finally {
    busy = false;
  }
}

class TextField {
  float x, y, w, h;
  StringBuilder content;
  String placeholder;
  String label;
  boolean focused = false;
  boolean multiline;
  color accent;

  TextField(float x, float y, float w, float h, String label, String placeholder, String initial, boolean multiline, color accent) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.placeholder = placeholder;
    this.content = new StringBuilder(initial == null ? "" : initial);
    this.multiline = multiline;
    this.accent = accent;
  }

  String getText() {
    return content.toString();
  }

  boolean contains(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void handleClick(float mx, float my) {
    focused = contains(mx, my);
  }

  void handleKey(char k) {
    if (!focused) return;
    if (k == BACKSPACE) {
      if (content.length() > 0) content.deleteCharAt(content.length() - 1);
    } else if (k == ENTER || k == RETURN) {
      if (multiline) content.append('\n');
      else focused = false;
    } else if (k != CODED && k >= 32 && k != 127) {
      content.append(k);
    }
  }

  void display() {
    if (label != null && label.length() > 0) {
      fill(80);
      textAlign(LEFT, BOTTOM);
      text(label, x, y - 4);
    }
    fill(255);
    stroke(focused ? accent : color(100));
    strokeWeight(1);
    rect(x, y, w, h);
    noStroke();

    textAlign(LEFT, TOP);
    float pad = 6;
    boolean showPlaceholder = content.length() == 0 && !focused;
    if (showPlaceholder) {
      fill(150);
      text(placeholder, x + pad, y + pad, w - 2 * pad, h - 2 * pad);
      return;
    }
    fill(0);
    text(content.toString(), x + pad, y + pad, w - 2 * pad, h - 2 * pad);
  }
}

void loadConfig() {
  API_KEY = loadEnvValue("API_KEY", "");
}

boolean isApiKeyConfigured() {
  return API_KEY != null && API_KEY.length() > 0 && !API_KEY.equals("YOUR_API_KEY_HERE");
}

String loadEnvValue(String key, String fallback) {
  File envFile = new File(sketchPath("../talking_to_llm/.env"));
  if (!envFile.exists()) return fallback;
  BufferedReader reader = null;
  try {
    reader = new BufferedReader(new FileReader(envFile));
    String line;
    while ((line = reader.readLine()) != null) {
      line = line.trim();
      if (line.length() == 0 || line.startsWith("#")) continue;
      int eq = line.indexOf('=');
      if (eq <= 0) continue;
      String envKey = line.substring(0, eq).trim();
      String value = line.substring(eq + 1).trim();
      if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length() - 1);
      }
      if (envKey.equals(key)) return value;
    }
  } catch (IOException e) {
    log("WARN: could not read .env - " + e.getMessage());
  } finally {
    if (reader != null) {
      try { reader.close(); } catch (IOException ignored) {}
    }
  }
  return fallback;
}

HttpURLConnection openConnection(String urlStr, String method, String contentType) throws IOException {
  URL url = new URL(urlStr);
  HttpURLConnection conn = (HttpURLConnection) url.openConnection();
  conn.setRequestMethod(method);
  conn.setConnectTimeout(20000);
  conn.setReadTimeout(600000);
  if (contentType != null) conn.setRequestProperty("Content-Type", contentType);
  if (isApiKeyConfigured()) conn.setRequestProperty("Authorization", "Bearer " + API_KEY);
  return conn;
}

byte[] httpGetBytes(String urlStr) throws IOException {
  HttpURLConnection conn = openConnection(urlStr, "GET", null);
  return readResponse(conn);
}

String httpPostJsonString(String urlStr, String jsonBody) throws IOException {
  HttpURLConnection conn = openConnection(urlStr, "POST", "application/json");
  conn.setDoOutput(true);
  byte[] bodyBytes = jsonBody.getBytes("UTF-8");
  OutputStream os = conn.getOutputStream();
  os.write(bodyBytes);
  os.close();
  return new String(readResponse(conn), "UTF-8");
}

byte[] readResponse(HttpURLConnection conn) throws IOException {
  int code = conn.getResponseCode();
  InputStream is = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();
  byte[] result = is != null ? readAllBytes(is) : new byte[0];
  if (is != null) is.close();
  if (code < 200 || code >= 300) throw new IOException("HTTP " + code + ": " + new String(result, "UTF-8"));
  return result;
}

byte[] readAllBytes(InputStream is) throws IOException {
  ByteArrayOutputStream buffer = new ByteArrayOutputStream();
  byte[] chunk = new byte[8192];
  int n;
  while ((n = is.read(chunk)) != -1) buffer.write(chunk, 0, n);
  return buffer.toByteArray();
}

String saveWav(byte[] wavBytes, String prefix) {
  File outDir = new File(sketchPath("../talking_to_llm/output"));
  if (!outDir.exists()) outDir.mkdirs();
  String path = outDir.getAbsolutePath() + "/" + prefix + "_" + System.currentTimeMillis() + ".wav";
  saveBytes(path, wavBytes);
  return path;
}

void playAudioFile(String path) {
  try {
    stopPlayback();
    AudioInputStream ais = AudioSystem.getAudioInputStream(new File(path));
    currentClip = AudioSystem.getClip();
    openClip(currentClip, ais);
    currentClip.start();
  } catch (Exception e) {
    log("Playback error: " + e.getMessage());
  }
}

void stopPlayback() {
  if (currentClip != null && currentClip.isOpen()) {
    currentClip.stop();
    currentClip.close();
  }
}

void openClip(Clip clip, AudioInputStream ais) throws LineUnavailableException, IOException {
  try {
    java.lang.reflect.Method method = Clip.class.getMethod("open", AudioInputStream.class);
    method.invoke(clip, ais);
  } catch (java.lang.reflect.InvocationTargetException e) {
    Throwable cause = e.getCause();
    if (cause instanceof LineUnavailableException) throw (LineUnavailableException) cause;
    if (cause instanceof IOException) throw (IOException) cause;
    throw new RuntimeException(cause);
  } catch (Exception e) {
    throw new RuntimeException(e);
  }
}

void log(String message) {
  println(message);
  if (logArea != null) logArea.append(message + "\n");
}
