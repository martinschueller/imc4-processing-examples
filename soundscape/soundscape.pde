import controlP5.*;
import java.net.*;
import java.io.*;
import javax.sound.sampled.*;

final String SOUNDSCAPE_BASE = "https://sound.imc4.medienkultur.eu";

ControlP5 cp5;
Textfield promptField, negativeField;
Slider secondsSlider, stepsSlider, cfgSlider;
Button generateButton, replayButton;
Textarea logArea;

String API_KEY = "";
volatile boolean busy = false;
volatile String outFile = null;
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
    .setText("gentle rain on a tin roof")
    .setLabel("prompt");

  negativeField = cp5.addTextfield("negative")
    .setPosition(20, 100)
    .setSize(400, 20)
    .setAutoClear(false)
    .setText("")
    .setLabel("negative");

  secondsSlider = cp5.addSlider("seconds")
    .setPosition(20, 150)
    .setSize(150, 15)
    .setRange(4, 47)
    .setValue(30)
    .setLabel("seconds");

  stepsSlider = cp5.addSlider("steps")
    .setPosition(20, 175)
    .setSize(150, 15)
    .setRange(10, 60)
    .setValue(40)
    .setLabel("steps");

  cfgSlider = cp5.addSlider("cfg")
    .setPosition(20, 200)
    .setSize(150, 15)
    .setRange(1, 15)
    .setValue(7)
    .setLabel("cfg");

  generateButton = cp5.addButton("btnGenerate")
    .setPosition(20, 250)
    .setLabel("generate");
  replayButton = cp5.addButton("btnReplay")
    .setPosition(100, 250)
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
  text("Soundscape Generation", 20, 30);
  textAlign(LEFT, TOP);
  text(busy ? "working..." : "idle", 20, 300);
  if (outFile != null) {
    text("output: " + outFile, 20, 320);
  }
}

void btnGenerate() {
  if (busy) return;
  if (promptField.getText().trim().length() == 0) {
    log("Enter a prompt first.");
    return;
  }
  busy = true;
  log("Generating soundscape...");
  thread("generateSoundscape");
}

void btnReplay() {
  if (outFile != null) playAudioFile(outFile);
}

void generateSoundscape() {
  try {
    JSONObject body = new JSONObject();
    body.setString("prompt", promptField.getText());
    body.setInt("seconds", (int) secondsSlider.getValue());
    body.setInt("steps", (int) stepsSlider.getValue());
    body.setFloat("cfg_scale", cfgSlider.getValue());
    if (negativeField.getText().trim().length() > 0) {
      body.setString("negative_prompt", negativeField.getText());
    }

    byte[] audio = httpPostJsonBytes(SOUNDSCAPE_BASE + "/generate", body.toString());
    outFile = saveWav(audio, "soundscape");
    log("Soundscape done. Playing...");
    playAudioFile(outFile);
  } catch (Exception e) {
    log("Soundscape error: " + e.getMessage());
  } finally {
    busy = false;
  }
}

void loadConfig() {
  API_KEY = loadEnvValue("API_KEY", "");
}

boolean isApiKeyConfigured() {
  return API_KEY != null && API_KEY.length() > 0 && !API_KEY.equals("YOUR_API_KEY_HERE");
}

String loadEnvValue(String key, String fallback) {
  File envFile = new File(sketchPath("../.env"));
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

byte[] httpPostJsonBytes(String urlStr, String jsonBody) throws IOException {
  HttpURLConnection conn = openConnection(urlStr, "POST", "application/json");
  conn.setDoOutput(true);
  byte[] bodyBytes = jsonBody.getBytes("UTF-8");
  OutputStream os = conn.getOutputStream();
  os.write(bodyBytes);
  os.close();
  return readResponse(conn);
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
  File outDir = new File(sketchPath("../output"));
  if (!outDir.exists()) outDir.mkdirs();
  String path = outDir.getAbsolutePath() + "/" + prefix + "_" + System.currentTimeMillis() + ".wav";
  saveBytes(path, wavBytes);
  return path;
}

void playAudioFile(String path) {
  try {
    if (currentClip != null && currentClip.isOpen()) {
      currentClip.stop();
      currentClip.close();
    }
    AudioInputStream ais = AudioSystem.getAudioInputStream(new File(path));
    currentClip = AudioSystem.getClip();
    openClip(currentClip, ais);
    currentClip.start();
  } catch (Exception e) {
    log("Playback error: " + e.getMessage());
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
