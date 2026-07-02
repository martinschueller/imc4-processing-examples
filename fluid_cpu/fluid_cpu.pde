// Fluid Particle Simulation - CPU (Default renderer)
// Demonstrates CPU-only rendering with thousands of particles

int numParticles = 20000;
Particle[] particles;
PVector gravity = new PVector(0, 0.1);

void setup() {
  size(800, 600);  // Default renderer (CPU only, no OpenGL)
  
  particles = new Particle[numParticles];
  for (int i = 0; i < numParticles; i++) {
    particles[i] = new Particle(random(width), random(height/2));
  }
}

void draw() {
  background(20);
  
  // Update and display particles
  for (Particle p : particles) {
    p.applyForce(gravity);
    p.update();
    p.edges();
    p.display();
  }
  
  // Mouse interaction - push particles away
  if (mousePressed) {
    for (Particle p : particles) {
      PVector mouse = new PVector(mouseX, mouseY);
      PVector dir = PVector.sub(p.pos, mouse);
      float d = dir.mag();
      if (d < 100) {
        dir.normalize();
        dir.mult(map(d, 0, 100, 5, 0));
        p.applyForce(dir);
      }
    }
  }
  
  // Display info
  fill(255);
  textAlign(LEFT, TOP);
  text("CPU Rendering (Default / Java2D)", 10, 10);
  text("Particles: " + numParticles, 10, 30);
  text("FPS: " + nf(frameRate, 0, 1), 10, 50);
  text("Click and drag to interact", 10, 80);
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
    vel.mult(0.99);  // friction
    pos.add(vel);
    acc.mult(0);
  }
  
  void edges() {
    if (pos.x < 0) { pos.x = 0; vel.x *= -0.5; }
    if (pos.x > width) { pos.x = width; vel.x *= -0.5; }
    if (pos.y < 0) { pos.y = 0; vel.y *= -0.5; }
    if (pos.y > height) { pos.y = height; vel.y *= -0.8; }
  }
  
  void display() {
    noStroke();
    fill(col);
    ellipse(pos.x, pos.y, size, size);
  }
}
