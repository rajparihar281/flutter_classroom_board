# Flutter Classroom Board

**Flutter Classroom Board** is a versatile, interactive whiteboard application designed for educational and creative purposes. Built with Flutter, it features an infinite canvas, a suite of drawing and manipulation tools, and a variety of background templates suitable for classroom environments.

## Features

### 🎨 Core Drawing & Editing
* **Infinite Canvas:** Zoom in/out and pan freely across a virtually limitless workspace.
* **Drawing Tools:**
    * **Pen:** Freehand drawing with adjustable stroke width and colors.
    * **Eraser:** precise eraser that works on both freehand drawings and shapes.
    * **Shapes:** Create perfect Rectangles and Ellipses.
    * **Text:** Add text notes with formatting options (Bold, Italic, Underline) and adjustable font sizes.
* **Object Library:** Quickly insert emojis and mathematical symbols (e.g., ∑, ∫, π).

### 🛠 Tools & Manipulation
* **Selection Mode:** Select, move, resize, and rotate any object or drawing on the board.
* **Layer Management:** Bring items to the front or send them to the back.
* **Clipboard Operations:** Duplicate or delete selected items.
* **History:** Robust Undo/Redo functionality to manage your workflow.

### 📐 Classroom Backgrounds
Switch between various background styles tailored for different subjects:
* **Plain Colors:** White, Black, Dark Green, Blue, Dark Grey.
* **Grids & Graphs:** Inch Graph, CM Graph, Math Squares.
* **Writing Lines:** Single, Double, Triple, and Quadruple line patterns (standard and wide variants).
* **Music:** Five-line staff pattern.

### 📱 User Interface
* **Floating Toolbar:** A collapsible toolbar that can be shifted to the left or right side of the screen for ergonomics.
* **Properties Bar:** Context-sensitive settings for changing colors and tool sizes (Pen/Eraser size).
* **Zoom Controls:** On-screen slider and buttons for precise zoom control.

## Getting Started

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.18.0 or later)
* Dart SDK (Version 3.8.1 or later)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/flutter_classroom_board.git](https://github.com/your-username/flutter_classroom_board.git)
    cd flutter_classroom_board
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Usage Guide

* **Pan/Zoom:** Use two fingers to pinch-to-zoom or pan across the canvas. Alternatively, select the **Pan** tool to move with one finger.
* **Edit Text:** Double-tap on any text item to enter edit mode.
* **Transform Objects:** Select an object to see its bounding box.
    * Drag the **bottom-right handle** to resize.
    * Drag the **top handle** to rotate.
* **Context Menu:** Select an item to reveal options for Deleting, Duplicating, or changing Layer order.

## Tech Stack & Dependencies

* **Framework:** [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
* **Key Packages:**
    * `flutter_colorpicker`: ^1.0.0
    * `cupertino_icons`: ^1.0.8

## Project Structure

* `lib/main.dart`: Contains the core logic, including the `BoardItem` models, `CustomPainter` classes for rendering, and the main `HomeScreen` widget.
* `android/`: Android-specific configuration files.
* `web/`: Web configuration and icons.
