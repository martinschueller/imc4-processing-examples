// Home screen

Button homeSTTButton, homeTTSButton, homeSoundscapeButton, homeMusicButton;

void setupHomeScreen() {
  int x = 20;
  int y = 60;
  int gap = 30;

  homeSTTButton = cp5.addButton("btnGoSTT")
    .setPosition(x, y)
    .setLabel("speech-to-text");

  homeTTSButton = cp5.addButton("btnGoTTS")
    .setPosition(x, y + gap)
    .setLabel("text-to-speech");

  homeSoundscapeButton = cp5.addButton("btnGoSoundscape")
    .setPosition(x, y + gap * 2)
    .setLabel("soundscape");

  homeMusicButton = cp5.addButton("btnGoMusic")
    .setPosition(x, y + gap * 3)
    .setLabel("music");

  homeControllers.add(homeSTTButton);
  homeControllers.add(homeTTSButton);
  homeControllers.add(homeSoundscapeButton);
  homeControllers.add(homeMusicButton);
}

void drawHomeScreen() {
  fill(0);
  textAlign(LEFT, TOP);
  text("Voice & Soundscape Stack", 20, 20);
  
  boolean keyMissing = !isApiKeyConfigured();
  fill(keyMissing ? color(180, 0, 0) : color(0, 100, 0));
  textAlign(LEFT, BOTTOM);
  text(keyMissing ? "API key missing - set in .env" : "API key configured", 20, height - 10);
}

void btnGoSTT() { goToScreen(SCREEN_STT); }
void btnGoTTS() { goToScreen(SCREEN_TTS); }
void btnGoSoundscape() { goToScreen(SCREEN_SOUNDSCAPE); }
void btnGoMusic() { goToScreen(SCREEN_MUSIC); }
