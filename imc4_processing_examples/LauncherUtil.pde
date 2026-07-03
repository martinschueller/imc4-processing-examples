import controlP5.*;
import java.io.File;

ControlP5 cp5;
String statusMessage = "Ready.";

void setupLauncher() {
  cp5 = new ControlP5(this);

  int x = 20;
  int y = 55;
  int w = 190;
  int h = 24;
  int gap = 31;

  cp5.addButton("btnLaunchSTT")
    .setPosition(x, y)
    .setSize(w, h)
    .setLabel("speech-to-text");
  cp5.addButton("btnLaunchTTS")
    .setPosition(x, y + gap)
    .setSize(w, h)
    .setLabel("text-to-speech");
  cp5.addButton("btnLaunchSoundscape")
    .setPosition(x, y + gap * 2)
    .setSize(w, h)
    .setLabel("soundscape");
  cp5.addButton("btnLaunchMusic")
    .setPosition(x, y + gap * 3)
    .setSize(w, h)
    .setLabel("music");
  cp5.addButton("btnLaunchFluidCpu")
    .setPosition(x, y + gap * 4)
    .setSize(w, h)
    .setLabel("fluid CPU");
  cp5.addButton("btnLaunchFluidGpu")
    .setPosition(x, y + gap * 5)
    .setSize(w, h)
    .setLabel("fluid GPU");

  println("Launcher ready - pick a sketch to open in a new process.");
}

void drawLauncher() {
  background(220);
  fill(0);
  textAlign(LEFT, TOP);
  text("IMC4 Processing Examples", 20, 20);

  fill(80);
  text("Each button launches an independent Processing sketch.", 20, 38);

  fill(40);
  text(statusMessage, 20, height - 28, width - 40, 20);
}

void btnLaunchSTT() {
  launchSketchFolder("stt");
}

void btnLaunchTTS() {
  launchSketchFolder("tts");
}

void btnLaunchSoundscape() {
  launchSketchFolder("soundscape");
}

void btnLaunchMusic() {
  launchSketchFolder("music");
}

void btnLaunchFluidCpu() {
  launchSketchFolder("fluid_cpu");
}

void btnLaunchFluidGpu() {
  launchSketchFolder("fluid_gpu");
}

void launchSketchFolder(String folderName) {
  File folder = new File(sketchPath("../" + folderName));
  if (!folder.exists()) {
    statusMessage = "Missing sketch folder: " + folderName;
    println(statusMessage);
    return;
  }

  String folderPath = folder.getAbsolutePath();
  String[] command = processingJavaCommand(folderPath);

  try {
    exec(command);
    statusMessage = "Launched: " + folderName;
    println(statusMessage);
  } catch (Exception e) {
    statusMessage = "Could not launch " + folderName + ". Check processing-java path.";
    println(statusMessage);
    println(e.getMessage());
  }
}

String[] processingJavaCommand(String folderPath) {
  String[] candidates = {
    "/usr/local/bin/processing-java",
    "/opt/homebrew/bin/processing-java"
  };

  for (int i = 0; i < candidates.length; i++) {
    if (new File(candidates[i]).exists()) {
      return new String[] {
        candidates[i],
        "--sketch=" + folderPath,
        "--run"
      };
    }
  }

  String processingApp = "/Applications/Processing.app/Contents/MacOS/Processing";
  if (new File(processingApp).exists()) {
    return new String[] {
      processingApp,
      "cli",
      "--sketch=" + folderPath,
      "--run"
    };
  }

  return new String[] {
    "/bin/zsh",
    "-lc",
    "processing-java --sketch=" + shellQuote(folderPath) + " --run"
  };
}

String shellQuote(String value) {
  return "'" + value.replace("'", "'\\''") + "'";
}
