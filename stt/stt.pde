import controlP5.*;
import java.net.*;
import java.io.*;
import javax.sound.sampled.*;

final String GATEWAY_BASE = "https://voice.imc4.medienkultur.eu";
final float RECORD_SAMPLE_RATE = 16000f;

ControlP5 cp5;
Button recordButton, transcribeButton, replayButton;
Textarea transcriptArea, logArea;

String API_KEY = "";
TargetDataLine micLine;
ByteArrayOutputStream recordBuffer;
Thread recordThread;
volatile boolean recording = false;
volatile boolean busy = false;
volatile byte[] recordedWav = null;
long recordStartMs = 0;
Clip currentClip;

void settings() {
  size(600, 500);
}

void setup() {
  loadConfig();
  cp5 = new ControlP5(this);

  recordButton = cp5.addButton("btnRecord")
    .setPosition(20, 60)
    .setLabel("record");
  transcribeButton = cp5.addButton("btnTranscribe")
    .setPosition(100, 60)
    .setLabel("transcribe");
  replayButton = cp5.addButton("btnReplay")
    .setPosition(205, 60)
    .setLabel("replay");

  transcriptArea = cp5.addTextarea("transcript")
    .setPosition(20, 120)
    .setSize(400, 120)
    .setLineHeight(14)
    .setColor(color(0))
    .setColorBackground(color(255))
    .setText("(record, then transcribe)");

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
  text("Speech-to-Text", 20, 30);

  recordButton.setLabel(recording ? "stop" : "record");
  transcribeButton.setLabel(busy ? "working..." : "transcribe");

  if (recording) {
    float secs = (millis() - recordStartMs) / 1000.0;
    textAlign(LEFT, TOP);
    text("recording: " + nf(secs, 0, 1) + "s", 300, 64);
  }
}

void btnRecord() {
  if (busy) return;
  if (!recording) {
    if (startRecording()) {
      recording = true;
      recordStartMs = millis();
      transcriptArea.setText("(recording...)");
      log("Recording started.");
    }
  } else {
    recordedWav = stopRecording();
    log(recordedWav != null ? "Recording stopped." : "Recording failed.");
  }
}

void btnTranscribe() {
  if (busy || recording || recordedWav == null) return;
  busy = true;
  log("Transcribing...");
  thread("transcribeRecording");
}

void btnReplay() {
  if (recordedWav != null) playAudioBytes(recordedWav);
}

void transcribeRecording() {
  try {
    byte[] result = httpPostMultipartFile(GATEWAY_BASE + "/stt", "file", "recording.wav", recordedWav);
    String json = new String(result, "UTF-8");
    String text;
    try {
      JSONObject obj = parseJSONObject(json);
      text = obj != null && obj.hasKey("text") ? obj.getString("text") : json;
    } catch (Exception parseErr) {
      text = json;
    }
    transcriptArea.setText(text);
    log("Transcription done.");
  } catch (Exception e) {
    log("STT error: " + e.getMessage());
  } finally {
    busy = false;
  }
}

boolean startRecording() {
  try {
    AudioFormat format = new AudioFormat(RECORD_SAMPLE_RATE, 16, 1, true, false);
    DataLine.Info info = new DataLine.Info(TargetDataLine.class, format);
    if (!AudioSystem.isLineSupported(info)) {
      log("No microphone line available.");
      return false;
    }
    micLine = (TargetDataLine) AudioSystem.getLine(info);
    openLine(micLine, format);
    micLine.start();
    recordBuffer = new ByteArrayOutputStream();

    recordThread = new Thread(new Runnable() {
      public void run() {
        byte[] buf = new byte[4096];
        while (recording) {
          int n = micLine.read(buf, 0, buf.length);
          if (n > 0) recordBuffer.write(buf, 0, n);
        }
      }
    });
    recording = true;
    recordThread.start();
    return true;
  } catch (Exception e) {
    log("Mic error: " + e.getMessage());
    return false;
  }
}

byte[] stopRecording() {
  recording = false;
  try {
    if (recordThread != null) recordThread.join(1000);
  } catch (InterruptedException e) {
    // ignore
  }
  if (micLine != null) {
    micLine.stop();
    micLine.close();
  }
  byte[] pcm = recordBuffer != null ? recordBuffer.toByteArray() : new byte[0];
  try {
    return pcmToWav(pcm, RECORD_SAMPLE_RATE, 16, 1);
  } catch (IOException e) {
    log("WAV encode error: " + e.getMessage());
    return null;
  }
}

byte[] pcmToWav(byte[] pcm, float sampleRate, int bits, int channels) throws IOException {
  AudioFormat format = new AudioFormat(sampleRate, bits, channels, true, false);
  ByteArrayInputStream bais = new ByteArrayInputStream(pcm);
  AudioInputStream ais = new AudioInputStream(bais, format, pcm.length / format.getFrameSize());
  ByteArrayOutputStream out = new ByteArrayOutputStream();
  AudioSystem.write(ais, AudioFileFormat.Type.WAVE, out);
  ais.close();
  return out.toByteArray();
}

void playAudioBytes(byte[] wavBytes) {
  try {
    stopPlayback();
    AudioInputStream ais = AudioSystem.getAudioInputStream(new ByteArrayInputStream(wavBytes));
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

void openLine(TargetDataLine line, AudioFormat fmt) throws LineUnavailableException {
  try {
    java.lang.reflect.Method method = TargetDataLine.class.getMethod("open", AudioFormat.class);
    method.invoke(line, fmt);
  } catch (java.lang.reflect.InvocationTargetException e) {
    Throwable cause = e.getCause();
    if (cause instanceof LineUnavailableException) throw (LineUnavailableException) cause;
    throw new RuntimeException(cause);
  } catch (Exception e) {
    throw new RuntimeException(e);
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

byte[] httpPostMultipartFile(String urlStr, String fieldName, String fileName, byte[] fileBytes) throws IOException {
  String boundary = "----ProcessingBoundary" + System.currentTimeMillis();
  HttpURLConnection conn = openConnection(urlStr, "POST", "multipart/form-data; boundary=" + boundary);
  conn.setDoOutput(true);

  ByteArrayOutputStream body = new ByteArrayOutputStream();
  String prefix = "--" + boundary + "\r\n" +
    "Content-Disposition: form-data; name=\"" + fieldName + "\"; filename=\"" + fileName + "\"\r\n" +
    "Content-Type: audio/wav\r\n\r\n";
  body.write(prefix.getBytes("UTF-8"));
  body.write(fileBytes);
  body.write(("\r\n--" + boundary + "--\r\n").getBytes("UTF-8"));
  byte[] bodyBytes = body.toByteArray();

  conn.setRequestProperty("Content-Length", String.valueOf(bodyBytes.length));
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

void log(String message) {
  println(message);
  if (logArea != null) logArea.append(message + "\n");
}
