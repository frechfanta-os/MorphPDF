# MorphPDF — Production OCR Runtime Specification
## PaddleOCR + ONNX Runtime Mobile on Android

This document outlines the architecture, execution pipeline, and operational contracts of the production OCR runtime for MorphPDF.

---

## 1. Executive Summary & Design Principles

- **Primary OCR Engine**: PaddleOCR (`ch_PP-OCRv4_det`, `arabic_PP-OCRv3_rec`, `en_PP-OCRv4_rec`).
- **Inference Runtime**: Microsoft ONNX Runtime Mobile (`com.microsoft.onnxruntime:onnxruntime-android:1.17.0`) via native Android Kotlin bridge (`PaddleOcrBridge`).
- **Secondary Engine**: Google ML Kit Text Recognition V2 (optional Latin/CJK fallback, preserved via `MlKitEngineMock`).
- **Platform Architecture**: Android-first, local-first.
- **Strict Offline Guarantee**: All inference runs 100% on-device. Under no circumstances are document images transmitted over the network (prohibited from uploading to OpenRouter, Cloudflare R2, or external vision APIs).

---

## 2. Model Architecture & Pipeline Specifications

```
Input PDF Page (PDFium rasterized @ 150-300 DPI)
         │
         ▼
[Dimension Guard: Max 4096 × 4096 px]
         │
         ▼
[Preprocessing & Bitmap Normalization]
         │
         ▼
[PaddleOCR Text Detection: ch_PP-OCRv4_det] ──► Text region bounding polygons
         │
         ▼
[Text Direction Classifier: ch_ppocr_mobile_v2.0_cls] (if angle tilt > 15°)
         │
         ▼
[PaddleOCR Text Recognition]
  ├── Arabic scripts: arabic_PP-OCRv3_rec (vocab: arabic_dict.txt)
  └── Latin/English scripts: en_PP-OCRv4_rec (vocab: en_dict.txt)
         │
         ▼
[Dart BiDi Normalization: BidiNormalizer] ──► Logical Unicode ordering (spatial boxes preserved)
         │
         ▼
[Coordinate Projection: OcrCoordinateMapper] ──► PDF Point Space (CoordinateConverter.pixelRectToPdfRect)
         │
         ▼
MorphPDF DocumentModel (Searchable & Selectable Text Overlay)
```

### Models Matrix

| Role | Model Identifier | Architecture | Inputs / Shapes | Output |
| :--- | :--- | :--- | :--- | :--- |
| **Detection** | `ch_PP-OCRv4_det` | DBNet / MobileNetV3 | `[1, 3, H, W]` (multiples of 32) | Probability heatmaps `[1, 1, H, W]` |
| **Classifier** | `ch_ppocr_mobile_v2.0_cls` | MobileNetV3 | `[1, 3, 48, 192]` | Direction classes (0° / 180°) |
| **Arabic Recognition** | `arabic_PP-OCRv3_rec` | SVTR / LCNet | `[1, 3, 48, W]` | Character sequence probabilities (`arabic_dict.txt`) |
| **Latin Recognition** | `en_PP-OCRv4_rec` | SVTR / LCNet | `[1, 3, 48, W]` | Character sequence probabilities (`en_dict.txt`) |

---

## 3. Native Kotlin Bridge & MethodChannel Protocol

The native bridge is implemented in `com.ghdinteractivestudio.morphpdf.ocr.PaddleOcrBridge`.

- **Channel Identifier**: `com.ghdinteractivestudio.morphpdf/ocr`

### Supported Calls

1. `init`
   - Pre-allocates ONNX Runtime environment and checks model asset paths.
   - Returns `true` on success or throws `OCR_INIT_FAILED`.

2. `recognizePage`
   - **Arguments**:
     - `imagePath` (`String`): Absolute path to the page bitmap file.
     - `pageIndex` (`Int`): 1-based page index.
     - `mode` (`String`): `"auto"`, `"arabic"`, or `"latin"`.
     - `maxDimension` (`Int`): Hard limit (default: 4096 px).
   - **Behavior**:
     - Pre-flight checks file existence and decodes bounds with `inJustDecodeBounds = true`.
     - Throws `OCR_IMAGE_TOO_LARGE` if $W > 4096$ or $H > 4096$.
     - Runs inference on dedicated background thread.
     - Recycles bitmap memory in `finally` blocks.
     - Returns structured map with bounding boxes, lines, words, polygon points, and execution metrics.

3. `cancel`
   - Atomically flips cancellation flag (`AtomicBoolean`). In-flight inference halts at the next iteration boundary.

4. `dispose`
   - Releases active ONNX Runtime sessions and resets internal states.

---

## 4. Execution Contracts & Concurrency Constraints

1. **Sequential Page Processing ($N=1$)**:
   - ONNX Runtime sessions consume significant RAM during activation.
   - Flutter's `OcrService.processDocument` enforces strict serial execution: page $i+1$ begins only after page $i$ finishes and clears memory.
   - Concurrent multi-page execution in ONNX Runtime is strictly forbidden.

2. **Dimension Constraints**:
   - Maximum allowable image dimension is 4096 px along width or height.
   - Images exceeding this limit immediately throw `OcrImageTooLargeException` prior to bitmap memory allocation.

3. **Cancellation Guarantees**:
   - `OcrCancellationToken` is checked before page invocation, during bridge execution, and before spatial projection.
   - Throwing `OcrCancelledException` terminates the operation with zero data corruption.

4. **Progress Feedback**:
   - `OcrProgress` provides `currentPage`, `totalPages`, `fraction` ($0.0 \dots 1.0$), and human-readable status messages for interactive UI widgets.

---

## 5. Arabic & BiDi Text Handling

- **Visual vs. Logical Ordering**: CTC decoding from PaddleOCR yields characters in visual scanning order.
- **Normalization Rule**: MorphPDF applies `BidiNormalizer.normalizePage()` without character-flipping destruction or polygon warping.
- **Bilingual Documents**: Mixed Arabic, French, English, and numbers retain proper semantic flow while bounding boxes accurately correspond to physical pixels.

---

## 6. Coordinate Conversion & Document Integration

- OCR coordinates are generated in image raster pixels (relative to top-left origin).
- `OcrCoordinateMapper` utilizes `CoordinateConverter.pixelRectToPdfRect` to transform coordinates to standard PDF points (relative to bottom-left origin, 72 pt/inch).
- Rotations of 0°, 90°, 180°, and 270° are mathematically mapped to guarantee perfect text alignment for search and copy-paste overlays in `DocumentModel`.
