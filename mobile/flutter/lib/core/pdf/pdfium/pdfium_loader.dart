import 'dart:ffi';
import 'dart:io';
import 'pdfium_bindings.dart';

/// Dynamically locates and loads the native libpdfium.so library.
class PdfiumLoader {
  static PdfiumBindings? _cachedBindings;
  static bool _attemptedLoad = false;
  static bool _isAvailable = false;
  static String? _loadError;

  /// Whether real native PDFium library was found and loaded successfully.
  static bool get isAvailable {
    _ensureInitialized();
    return _isAvailable;
  }

  /// Returns the native PDFium bindings if available, otherwise null.
  static PdfiumBindings? get bindings {
    _ensureInitialized();
    return _cachedBindings;
  }

  /// Diagnostic error message if native dynamic library loading failed.
  static String? get loadError {
    _ensureInitialized();
    return _loadError;
  }

  static void _ensureInitialized() {
    if (_attemptedLoad) return;
    _attemptedLoad = true;

    try {
      DynamicLibrary lib;
      if (Platform.isAndroid) {
        // Standard Android location packaged in APK / jniLibs / system
        lib = DynamicLibrary.open('libpdfium.so');
      } else if (Platform.isLinux) {
        // Local Linux or test environment
        lib = DynamicLibrary.open('libpdfium.so');
      } else {
        lib = DynamicLibrary.process();
      }

      _cachedBindings = PdfiumBindings(lib);
      // Initialize PDFium library
      _cachedBindings!.initLibrary(nullptr);
      _isAvailable = true;
      _loadError = null;
    } catch (e) {
      // libpdfium.so not present in current test environment / host OS
      _cachedBindings = null;
      _isAvailable = false;
      _loadError = e.toString();
    }
  }

  /// Forces reset (useful in test suites to mock availability)
  static void resetForTesting({PdfiumBindings? mockBindings}) {
    _cachedBindings = mockBindings;
    _isAvailable = mockBindings != null;
    _attemptedLoad = true;
    _loadError = null;
  }
}
