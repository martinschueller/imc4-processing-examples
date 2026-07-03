import controlP5.*;

ControlP5 cp5;
Slider particleSlider;
FluidSimulation sim;

void settings() {
  size(800, 600, P2D);
}

void setup() {
  cp5 = new ControlP5(this);
  sim = new FluidSimulation();

  particleSlider = cp5.addSlider("particleCount")
    .setPosition(10, 100)
    .setSize(200, 15)
    .setRange(2000, 50000)
    .setValue(20000)
    .setNumberOfTickMarks(10)
    .setLabel("particles");

  sim.setParticleCount((int) particleSlider.getValue(), width, height);
}

void draw() {
  background(20);
  sim.update(width, height, mousePressed, mouseX, mouseY);
  sim.display();

  fill(255);
  textAlign(LEFT, TOP);
  text("GPU Rendering (P2D / OpenGL)", 10, 10);
  text("Particles: " + sim.numParticles, 10, 30);
  text("FPS: " + nf(frameRate, 0, 1), 10, 50);
  text("Click and drag to interact", 10, 130);
}

void particleCount(float value) {
  sim.setParticleCount((int) value, width, height);
}

class Particle {
  PVector pos, vel, acc;
  float size;
  color col;

  Particle(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D().mult(random(1, 3));
    acc = new PVector(0, 0);
    size = random(3, 8);
    col = color(random(100, 200), random(150, 255), 255, 150);
  }

  void applyForce(PVector force) {
    acc.add(force);
  }

  void update() {
    vel.add(acc);
    vel.mult(0.99);
    pos.add(vel);
    acc.mult(0);
  }

  void edges(float w, float h) {
    if (pos.x < 0) { pos.x = 0; vel.x *= -0.5; }
    if (pos.x > w) { pos.x = w; vel.x *= -0.5; }
    if (pos.y < 0) { pos.y = 0; vel.y *= -0.5; }
    if (pos.y > h) { pos.y = h; vel.y *= -0.8; }
  }

  void display() {
    noStroke();
    fill(col);
    ellipse(pos.x, pos.y, size, size);
  }
}

class FluidSimulation {
  Particle[] particles;
  int numParticles;
  PVector gravity = new PVector(0, 0.1);

  void setParticleCount(int count, float w, float h) {
    count = max(100, count);
    if (particles == null || count != numParticles) {
      Particle[] next = new Particle[count];
      int copy = particles != null ? min(particles.length, count) : 0;
      for (int i = 0; i < copy; i++) {
        next[i] = particles[i];
      }
      for (int i = copy; i < count; i++) {
        next[i] = new Particle(random(w), random(h / 2));
      }
      particles = next;
      numParticles = count;
    }
  }

  void update(float w, float h, boolean mouseDown, float mx, float my) {
    for (int i = 0; i < numParticles; i++) {
      Particle p = particles[i];
      p.applyForce(gravity);
      p.update();
      p.edges(w, h);
    }

    if (mouseDown) {
      PVector mouse = new PVector(mx, my);
      for (int i = 0; i < numParticles; i++) {
        Particle p = particles[i];
        PVector dir = PVector.sub(p.pos, mouse);
        float d = dir.mag();
        if (d < 100) {
          dir.normalize();
          dir.mult(map(d, 0, 100, 5, 0));
          p.applyForce(dir);
        }
      }
    }
  }

  void display() {
    for (int i = 0; i < numParticles; i++) {
      particles[i].display();
    }
  }
}
