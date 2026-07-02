// Minimal multi-line text input box (ControlP5 Textfield doesn't support newlines)
class TextField {
  float x, y, w, h;
  StringBuilder content;
  String placeholder;
  String label;
  boolean focused = false;
  boolean multiline;
  color accent;

  TextField(float x, float y, float w, float h, String label, String placeholder, String initial, boolean multiline, color accent) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.placeholder = placeholder;
    this.content = new StringBuilder(initial == null ? "" : initial);
    this.multiline = multiline;
    this.accent = accent;
  }

  String getText() {
    return content.toString();
  }

  void setText(String s) {
    content = new StringBuilder(s == null ? "" : s);
  }

  boolean contains(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void handleClick(float mx, float my) {
    focused = contains(mx, my);
  }

  void handleKey() {
    if (!focused) return;

    if (key == BACKSPACE) {
      if (content.length() > 0) content.deleteCharAt(content.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      if (multiline) content.append('\n');
      else focused = false;
    } else if (key != CODED && key >= 32 && key != 127) {
      content.append(key);
    }
  }

  void display() {
    if (label != null && label.length() > 0) {
      fill(80);
      textAlign(LEFT, BOTTOM);
      text(label, x, y - 4);
    }

    fill(255);
    stroke(focused ? accent : color(100));
    strokeWeight(1);
    rect(x, y, w, h);
    noStroke();

    textAlign(LEFT, TOP);
    float pad = 6;
    float innerW = w - 2 * pad;

    boolean showPlaceholder = content.length() == 0 && !focused;
    if (showPlaceholder) {
      fill(150);
      text(placeholder, x + pad, y + pad, innerW, h - 2 * pad);
      return;
    }

    fill(0);
    ArrayList<String> lines = wrapText(content.toString(), innerW);
    float lineH = 14;
    float ty = y + pad;
    int maxLines = (int) ((h - 2 * pad) / lineH);
    int start = max(0, lines.size() - maxLines);
    for (int i = start; i < lines.size(); i++) {
      text(lines.get(i), x + pad, ty);
      ty += lineH;
    }

    if (focused && frameCount % 60 < 30) {
      String lastLine = lines.size() > 0 ? lines.get(lines.size() - 1) : "";
      float caretX = x + pad + textWidth(lastLine);
      float caretY = y + pad + lineH * (lines.size() - 1 - start);
      stroke(accent);
      line(caretX, caretY, caretX, caretY + 12);
      noStroke();
    }
  }

  ArrayList<String> wrapText(String s, float maxWidth) {
    ArrayList<String> result = new ArrayList<String>();
    String[] paragraphs = s.split("\n", -1);
    for (String para : paragraphs) {
      if (para.length() == 0) {
        result.add("");
        continue;
      }
      String[] words = para.split(" ");
      StringBuilder line = new StringBuilder();
      for (String word : words) {
        String candidate = line.length() == 0 ? word : line + " " + word;
        if (textWidth(candidate) > maxWidth && line.length() > 0) {
          result.add(line.toString());
          line = new StringBuilder(word);
        } else {
          line = new StringBuilder(candidate);
        }
      }
      result.add(line.toString());
    }
    return result;
  }
}
