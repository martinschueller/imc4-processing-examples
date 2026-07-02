// ---------------------------------------------------------------------------
// Microphone recording + WAV playback using plain javax.sound.sampled.
//
// Note: TargetDataLine/Clip.open(...) are invoked via reflection below.
// Calling ".open(" directly on a line/clip object trips up the Processing
// preprocessor (it misparses it as a method/parameter declaration), so we
// sidestep that by never writing the literal token sequence "identifier.open(".
// ---------------------------------------------------------------------------

Clip currentClip;

TargetDataLine micLine;
ByteArrayOutputStream recordBuffer;
volatile boolean recording = false;
Thread recordThread;

final float RECORD_SAMPLE_RATE = 16000f;

boolean startRecording() {
  try {
    AudioFormat format = new AudioFormat(RECORD_SAMPLE_RATE, 16, 1, true, false);
    DataLine.Info info = new DataLine.Info(TargetDataLine.class, format);
    if (!AudioSystem.isLineSupported(info)) {
      println("No microphone line available.");
      return false;
    }
    micLine = (TargetDataLine) AudioSystem.getLine(info);
    openLine(micLine, format);
    micLine.start();
    recordBuffer = new ByteArrayOutputStream();
    recording = true;

    recordThread = new Thread(new Runnable() {
      public void run() {
        byte[] buf = new byte[4096];
        while (recording) {
          int n = micLine.read(buf, 0, buf.length);
          if (n > 0) recordBuffer.write(buf, 0, n);
        }
      }
    });
    recordThread.start();
    return true;
  } catch (LineUnavailableException e) {
    println("Mic error: " + e.getMessage());
    return false;
  }
}

// Returns the recorded audio as WAV bytes.
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
    println("WAV encode error: " + e.getMessage());
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

void playAudioFile(String path) {
  try {
    stopPlayback();
    File f = new File(path);
    AudioInputStream ais = AudioSystem.getAudioInputStream(f);
    currentClip = AudioSystem.getClip();
    openClip(currentClip, ais);
    currentClip.start();
  } catch (Exception e) {
    println("Playback error: " + e.getMessage());
  }
}

void playAudioBytes(byte[] wavBytes) {
  try {
    stopPlayback();
    AudioInputStream ais = AudioSystem.getAudioInputStream(new ByteArrayInputStream(wavBytes));
    currentClip = AudioSystem.getClip();
    openClip(currentClip, ais);
    currentClip.start();
  } catch (Exception e) {
    println("Playback error: " + e.getMessage());
  }
}

void openLine(TargetDataLine line, AudioFormat fmt) throws LineUnavailableException {
  try {
    java.lang.reflect.Method m = TargetDataLine.class.getMethod("open", AudioFormat.class);
    m.invoke(line, fmt);
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
    java.lang.reflect.Method m = Clip.class.getMethod("open", AudioInputStream.class);
    m.invoke(clip, ais);
  } catch (java.lang.reflect.InvocationTargetException e) {
    Throwable cause = e.getCause();
    if (cause instanceof LineUnavailableException) throw (LineUnavailableException) cause;
    if (cause instanceof IOException) throw (IOException) cause;
    throw new RuntimeException(cause);
  } catch (NoSuchMethodException | IllegalAccessException e) {
    throw new RuntimeException(e);
  }
}

void stopPlayback() {
  if (currentClip != null && currentClip.isOpen()) {
    currentClip.stop();
    currentClip.close();
  }
}

String saveWavToOutput(byte[] wavBytes, String prefix) {
  String outPath = sketchPath("output/" + prefix + "_" + System.currentTimeMillis() + ".wav");
  saveBytes(outPath, wavBytes);
  return outPath;
}
