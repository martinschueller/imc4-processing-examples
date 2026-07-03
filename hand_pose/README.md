# OpenCV Hand Catch

An OpenCV-for-Processing webcam example where falling balls are caught by the detected hand region.

This is contour/blob tracking, not MediaPipe skeletal hand landmarks. It thresholds the webcam image, finds the largest contour, and treats that contour's bounding box as the hand.

## Requirements

- Processing 4.x
- Video library
- OpenCV for Processing
- ControlP5

Install libraries via **Sketch > Import Library > Add Library**.

## How to Run

Open `hand_pose.pde` directly in Processing, or launch it from `../imc4_processing_examples/imc4_processing_examples.pde`.

Use the sliders to tune detection:

- `threshold` changes the brightness cutoff for the OpenCV mask.
- `min hand area` ignores small blobs/noise.
- `mask` toggles the threshold overlay.

Tip: Put your hand against a high-contrast background and tune the threshold until the hand is the largest visible blob.
