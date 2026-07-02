// Voice & Soundscape Stack — Processing + ControlP5 demo

import controlP5.*;
import java.net.*;
import java.io.*;
import java.util.*;
import javax.sound.sampled.*;

// Endpoints
final String GATEWAY_BASE    = "https://voice.imc4.medienkultur.eu";
final String MUSIC_BASE      = "https://music.imc4.medienkultur.eu";
final String SOUNDSCAPE_BASE = "https://sound.imc4.medienkultur.eu";

ControlP5 cp5;

final int SCREEN_HOME       = 0;
final int SCREEN_TTS        = 1;
final int SCREEN_STT        = 2;
final int SCREEN_SOUNDSCAPE = 3;
final int SCREEN_MUSIC      = 4;

int currentScreen = SCREEN_HOME;

ArrayList<Controller> homeControllers       = new ArrayList<Controller>();
ArrayList<Controller> ttsControllers        = new ArrayList<Controller>();
ArrayList<Controller> sttControllers        = new ArrayList<Controller>();
ArrayList<Controller> soundscapeControllers = new ArrayList<Controller>();
ArrayList<Controller> musicControllers      = new ArrayList<Controller>();

Textarea logArea;
Println logConsole;
Button backButton;

void setup() {
  loadConfig();
  size(600, 500);
  
  cp5 = new ControlP5(this);

  backButton = cp5.addButton("btnBack")
    .setPosition(20, 20)
    .setLabel("back");

  logArea = cp5.addTextarea("log")
    .setPosition(20, 380)
    .setSize(560, 100)
    .setLineHeight(14)
    .setColor(color(0))
    .setColorBackground(color(255));
  logConsole = cp5.addConsole(logArea);

  setupHomeScreen();
  setupTTSScreen();
  setupSTTScreen();
  setupSoundscapeScreen();
  setupMusicScreen();

  applyScreenVisibility();
  println("Ready.");
}

void draw() {
  background(200);

  switch (currentScreen) {
    case SCREEN_HOME:       drawHomeScreen();       break;
    case SCREEN_TTS:        drawTTSScreen();        break;
    case SCREEN_STT:        drawSTTScreen();        break;
    case SCREEN_SOUNDSCAPE: drawSoundscapeScreen(); break;
    case SCREEN_MUSIC:      drawMusicScreen();      break;
  }
}

void goToScreen(int screen) {
  currentScreen = screen;
  applyScreenVisibility();
}

void btnBack() {
  goToScreen(SCREEN_HOME);
}

void applyScreenVisibility() {
  hideAll(homeControllers);
  hideAll(ttsControllers);
  hideAll(sttControllers);
  hideAll(soundscapeControllers);
  hideAll(musicControllers);

  switch (currentScreen) {
    case SCREEN_HOME:       showAll(homeControllers);       break;
    case SCREEN_TTS:        showAll(ttsControllers);        break;
    case SCREEN_STT:        showAll(sttControllers);        break;
    case SCREEN_SOUNDSCAPE: showAll(soundscapeControllers); break;
    case SCREEN_MUSIC:      showAll(musicControllers);      break;
  }

  if (currentScreen == SCREEN_HOME) {
    backButton.hide();
    logArea.hide();
  } else {
    backButton.show();
    logArea.show();
  }

  if (currentScreen == SCREEN_STT) {
    sttTranscriptArea.show();
  } else {
    sttTranscriptArea.hide();
  }
}

void hideAll(ArrayList<Controller> list) {
  for (Controller c : list) c.hide();
}

void showAll(ArrayList<Controller> list) {
  for (Controller c : list) c.show();
}

void mousePressed() {
  if (currentScreen == SCREEN_MUSIC) {
    musicMousePressed();
  }
}

void keyPressed() {
  if (currentScreen == SCREEN_MUSIC) {
    musicKeyPressed();
  }
}
