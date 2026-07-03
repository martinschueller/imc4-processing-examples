# Fluid Simulation - CPU (Default / Java2D)

This sketch uses the **default renderer**, which runs entirely on the CPU.

## How to run

1. Open `../imc4_processing_examples/imc4_processing_examples.pde` in Processing.
2. Run the launcher.
3. Click **fluid CPU** to open the simulation in a new window.
4. Use the **particles** slider (ControlP5) to change particle count (2000-50000).
5. Open **fluid GPU** from the same launcher to compare side by side.

You can also open `fluid_cpu.pde` directly in Processing.

## Expected results

With 20000 particles:
- **CPU (default)**: typically 10-30 FPS (varies by machine)
- **GPU (P2D)**: typically 60+ FPS

## The difference

```java
size(800, 600);        // CPU - uses Java2D software rendering
size(800, 600, P2D);   // GPU - uses OpenGL shaders
```

The CPU draws shapes one at a time. The GPU can process thousands in parallel.

## Try it

- Drag the particles slider and watch FPS change
- Click and drag to interact with the particles

Implementation code: `fluid_cpu.pde`
