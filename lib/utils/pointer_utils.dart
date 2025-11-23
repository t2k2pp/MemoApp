import 'package:flutter/gestures.dart';

/// Utility class for detecting pointer device types
class PointerUtils {
  /// Check if the pointer event is from a stylus/pen
  static bool isStylus(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus;
  }

  /// Check if the pointer event is from touch (finger)
  static bool isTouch(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch;
  }

  /// Check if the pointer event is from a mouse
  static bool isMouse(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse;
  }

  /// Check if the device should trigger drawing
  /// (stylus or mouse always draw, touch depends on mode)
  static bool shouldDraw(PointerEvent event, bool touchDrawingEnabled) {
    if (isStylus(event) || isMouse(event)) {
      return true;
    }
    if (isTouch(event)) {
      return touchDrawingEnabled;
    }
    return false;
  }
}
