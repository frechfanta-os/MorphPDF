# MorphPDF ProGuard / R8 Rules

# Preserve ONNX Runtime JNI native bindings and entry points
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Preserve Flutter engine entry points
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Preserve MorphPDF OCR bridge classes
-keep class com.ghdinteractivestudio.morphpdf.ocr.** { *; }
