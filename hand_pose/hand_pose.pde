import controlP5.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import java.util.ArrayList;

Capture camera;
OpenCV opencv;
ControlP5 cp5;
Slider thresholdSlider, minAreaSlider;
Toggle showMaskToggle;

PImage mirroredFrame;
ArrayList<Ball> balls = new ArrayList<Ball>();
Rectangle handBounds = null;

int score = 0;
int missed = 0;
int spawnEveryFrames = 45;
String statusMessage = "Waiting for camera...";

void settings() {
  size(960, 720);
}

void setup() {
  surface.setTitle("OpenCV Hand Catch");

  cp5 = new ControlP5(this);
  thresholdSlider = cp5.addSlider("thresholdValue")
    .setPosition(20, 510)
    .setSize(220, 18)
    .setRange(0, 255)
    .setValue(90)
    .setLabel("threshold");

  minAreaSlider = cp5.addSlider("minArea")
    .setPosition(20, 540)
    .setSize(220, 18)
    .setRange(500, 30000)
    .setValue(5000)
    .setLabel("min hand area");

  showMaskToggle = cp5.addToggle("showMask")
    .setPosition(20, 575)
    .setSize(48, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setLabel("mask");

  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    statusMessage = "No camera found.";
    println(statusMessage);
    return;
  }

  camera = new Capture(this, 640, 480);
  camera.start();
  opencv = new OpenCV(this, 640, 480);
  mirroredFrame = createImage(640, 480, RGB);
  statusMessage = "Show your hand as the largest bright/dark blob; tune threshold.";
}

void draw() {
  background(25);

  if (camera != null && camera.available()) {
    camera.read();
    mirrorCameraFrame();
    updateHandDetection();
  }

  drawCameraPanel();
  updateBalls();
  drawBalls();
  drawGamePanel();
  drawHud();
}

void mirrorCameraFrame() {
  camera.loadPixels();
  mirroredFrame.loadPixels();
  for (int y = 0; y < camera.height; y++) {
    for (int x = 0; x < camera.width; x++) {
      int src = y * camera.width + x;
      int dst = y * camera.width + (camera.width - 1 - x);
      mirroredFrame.pixels[dst] = camera.pixels[src];
    }
  }
  mirroredFrame.updatePixels();
}

void updateHandDetection() {
  opencv.loadImage(mirroredFrame);
  opencv.gray();
  opencv.threshold((int) thresholdSlider.getValue());

  ArrayList<Contour> contours = opencv.findContours();
  handBounds = largestContourBounds(contours, minAreaSlider.getValue());
}

Rectangle largestContourBounds(ArrayList<Contour> contours, float minArea) {
  Rectangle best = null;
  float bestArea = minArea;

  for (Contour contour : contours) {
    Rectangle box = contour.getBoundingBox();
    float area = box.width * box.height;
    if (area > bestArea) {
      best = box;
      bestArea = area;
    }
  }

  return best;
}

void drawCameraPanel() {
  pushMatrix();
  translate(20, 20);
  imageMode(CORNER);

  if (mirroredFrame != null) {
    image(mirroredFrame, 0, 0, 640, 480);
  } else {
    fill(40);
    rect(0, 0, 640, 480);
  }

  if (showMaskToggle.getState() && opencv != null) {
    tint(255, 110);
    image(opencv.getOutput(), 0, 0, 640, 480);
    noTint();
  }

  noFill();
  strokeWeight(3);
  if (handBounds != null) {
    stroke(0, 255, 150);
    rect(handBounds.x, handBounds.y, handBounds.width, handBounds.height);
    fill(0, 255, 150);
    noStroke();
    ellipse(handBounds.x + handBounds.width / 2, handBounds.y + handBounds.height / 2, 10, 10);
  }

  noFill();
  stroke(255);
  strokeWeight(1);
  rect(0, 0, 640, 480);
  popMatrix();
}

void updateBalls() {
  if (frameCount % spawnEveryFrames == 0) {
    balls.add(new Ball(random(30, 610), -20));
  }

  for (int i = balls.size() - 1; i >= 0; i--) {
    Ball ball = balls.get(i);
    ball.update();

    if (handBounds != null && ball.hits(handBounds)) {
      balls.remove(i);
      score++;
      continue;
    }

    if (ball.y - ball.r > 480) {
      balls.remove(i);
      missed++;
    }
  }
}

void drawGamePanel() {
  noStroke();
  fill(15);
  rect(690, 20, 250, 660);

  fill(255);
  textAlign(LEFT, TOP);
  textSize(18);
  text("Catch the Balls", 710, 42);

  textSize(12);
  fill(200);
  text("Move your hand in the camera view.\nBalls are caught when they overlap\nthe detected hand box.", 710, 75);

  fill(170);
  text("Balls fall over the camera panel.", 710, 120);
}

void drawBalls() {
  for (Ball ball : balls) {
    ball.display();
  }
}

void drawHud() {
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  text("Score: " + score, 710, 150);
  text("Missed: " + missed, 710, 170);
  text("Tracked: " + (handBounds != null ? "yes" : "no"), 710, 190);

  textSize(12);
  fill(210);
  text(statusMessage, 20, 615, 620, 80);
  text("Tip: Put your hand against a contrasting background, then tune threshold/min area.", 20, 690);
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    balls.clear();
    score = 0;
    missed = 0;
  }
}

class Ball {
  float x, y, r, speed;
  color c;

  Ball(float x, float y) {
    this.x = x;
    this.y = y;
    r = random(10, 22);
    speed = random(2.5, 6.5);
    c = color(random(160, 255), random(80, 220), random(80, 255));
  }

  void update() {
    y += speed;
  }

  boolean hits(Rectangle hand) {
    float closestX = constrain(x, hand.x, hand.x + hand.width);
    float closestY = constrain(y, hand.y, hand.y + hand.height);
    float dx = x - closestX;
    float dy = y - closestY;
    return dx * dx + dy * dy < r * r;
  }

  void display() {
    noStroke();
    fill(c);
    ellipse(x + 20, y + 20, r * 2, r * 2);
  }
}
