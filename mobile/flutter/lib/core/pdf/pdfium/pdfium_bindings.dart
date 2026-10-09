import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Native function typedefs
typedef FpdfInitLibraryNative = Void Function(Pointer<Void> config);
typedef FpdfInitLibraryDart = void Function(Pointer<Void> config);

typedef FpdfDestroyLibraryNative = Void Function();
typedef FpdfDestroyLibraryDart = void Function();

typedef FpdfLoadDocumentNative = Pointer<Void> Function(Pointer<Utf8> filePath, Pointer<Utf8> password);
typedef FpdfLoadDocumentDart = Pointer<Void> Function(Pointer<Utf8> filePath, Pointer<Utf8> password);

typedef FpdfCloseDocumentNative = Void Function(Pointer<Void> document);
typedef FpdfCloseDocumentDart = void Function(Pointer<Void> document);

typedef FpdfGetPageCountNative = Int32 Function(Pointer<Void> document);
typedef FpdfGetPageCountDart = int Function(Pointer<Void> document);

typedef FpdfLoadPageNative = Pointer<Void> Function(Pointer<Void> document, Int32 pageIndex);
typedef FpdfLoadPageDart = Pointer<Void> Function(Pointer<Void> document, int pageIndex);

typedef FpdfClosePageNative = Void Function(Pointer<Void> page);
typedef FpdfClosePageDart = void Function(Pointer<Void> page);

typedef FpdfGetPageWidthFNative = Float Function(Pointer<Void> page);
typedef FpdfGetPageWidthFDart = double Function(Pointer<Void> page);

typedef FpdfGetPageHeightFNative = Float Function(Pointer<Void> page);
typedef FpdfGetPageHeightFDart = double Function(Pointer<Void> page);

typedef FpdfBitmapCreateExNative = Pointer<Void> Function(Int32 width, Int32 height, Int32 format, Pointer<Void> firstScan, Int32 stride);
typedef FpdfBitmapCreateExDart = Pointer<Void> Function(int width, int height, int format, Pointer<Void> firstScan, int stride);

typedef FpdfBitmapFillRectNative = Void Function(Pointer<Void> bitmap, Int32 left, Int32 top, Int32 width, Int32 height, UnsignedLong color);
typedef FpdfBitmapFillRectDart = void Function(Pointer<Void> bitmap, int left, int top, int width, int height, int color);

typedef FpdfRenderPageBitmapNative = Void Function(Pointer<Void> bitmap, Pointer<Void> page, Int32 startX, Int32 startY, Int32 sizeX, Int32 sizeY, Int32 rotate, Int32 flags);
typedef FpdfRenderPageBitmapDart = void Function(Pointer<Void> bitmap, Pointer<Void> page, int startX, int startY, int sizeX, int sizeY, int rotate, int flags);

typedef FpdfBitmapGetBufferNative = Pointer<Uint8> Function(Pointer<Void> bitmap);
typedef FpdfBitmapGetBufferDart = Pointer<Uint8> Function(Pointer<Void> bitmap);

typedef FpdfBitmapDestroyNative = Void Function(Pointer<Void> bitmap);
typedef FpdfBitmapDestroyDart = void Function(Pointer<Void> bitmap);

typedef FpdfTextLoadPageNative = Pointer<Void> Function(Pointer<Void> page);
typedef FpdfTextLoadPageDart = Pointer<Void> Function(Pointer<Void> page);

typedef FpdfTextClosePageNative = Void Function(Pointer<Void> textPage);
typedef FpdfTextClosePageDart = void Function(Pointer<Void> textPage);

typedef FpdfTextCountCharsNative = Int32 Function(Pointer<Void> textPage);
typedef FpdfTextCountCharsDart = int Function(Pointer<Void> textPage);

typedef FpdfTextGetTextNative = Int32 Function(Pointer<Void> textPage, Int32 startIndex, Int32 count, Pointer<Uint16> result);
typedef FpdfTextGetTextDart = int Function(Pointer<Void> textPage, int startIndex, int count, Pointer<Uint16> result);

typedef FpdfTextGetCharBoxNative = Int32 Function(Pointer<Void> textPage, Int32 index, Pointer<Double> left, Pointer<Double> right, Pointer<Double> bottom, Pointer<Double> top);
typedef FpdfTextGetCharBoxDart = int Function(Pointer<Void> textPage, int index, Pointer<Double> left, Pointer<Double> right, Pointer<Double> bottom, Pointer<Double> top);

typedef FpdfTextGetFontSizeNative = Double Function(Pointer<Void> textPage, Int32 index);
typedef FpdfTextGetFontSizeDart = double Function(Pointer<Void> textPage, int index);

typedef FpdfGetLastErrorNative = UnsignedLong Function();
typedef FpdfGetLastErrorDart = int Function();

/// Native FFI bindings to Google PDFium C library.
class PdfiumBindings {
  final DynamicLibrary dynamicLibrary;

  late final FpdfInitLibraryDart initLibrary;
  late final FpdfDestroyLibraryDart destroyLibrary;
  late final FpdfLoadDocumentDart loadDocument;
  late final FpdfCloseDocumentDart closeDocument;
  late final FpdfGetPageCountDart getPageCount;
  late final FpdfLoadPageDart loadPage;
  late final FpdfClosePageDart closePage;
  late final FpdfGetPageWidthFDart getPageWidth;
  late final FpdfGetPageHeightFDart getPageHeight;
  late final FpdfBitmapCreateExDart bitmapCreateEx;
  late final FpdfBitmapFillRectDart bitmapFillRect;
  late final FpdfRenderPageBitmapDart renderPageBitmap;
  late final FpdfBitmapGetBufferDart bitmapGetBuffer;
  late final FpdfBitmapDestroyDart bitmapDestroy;
  late final FpdfTextLoadPageDart textLoadPage;
  late final FpdfTextClosePageDart textClosePage;
  late final FpdfTextCountCharsDart textCountChars;
  late final FpdfTextGetTextDart textGetText;
  late final FpdfTextGetCharBoxDart textGetCharBox;
  late final FpdfTextGetFontSizeDart textGetFontSize;
  late final FpdfGetLastErrorDart getLastError;

  PdfiumBindings(this.dynamicLibrary) {
    initLibrary = dynamicLibrary.lookupFunction<FpdfInitLibraryNative, FpdfInitLibraryDart>('FPDF_InitLibraryWithConfig');
    destroyLibrary = dynamicLibrary.lookupFunction<FpdfDestroyLibraryNative, FpdfDestroyLibraryDart>('FPDF_DestroyLibrary');
    loadDocument = dynamicLibrary.lookupFunction<FpdfLoadDocumentNative, FpdfLoadDocumentDart>('FPDF_LoadDocument');
    closeDocument = dynamicLibrary.lookupFunction<FpdfCloseDocumentNative, FpdfCloseDocumentDart>('FPDF_CloseDocument');
    getPageCount = dynamicLibrary.lookupFunction<FpdfGetPageCountNative, FpdfGetPageCountDart>('FPDF_GetPageCount');
    loadPage = dynamicLibrary.lookupFunction<FpdfLoadPageNative, FpdfLoadPageDart>('FPDF_LoadPage');
    closePage = dynamicLibrary.lookupFunction<FpdfClosePageNative, FpdfClosePageDart>('FPDF_ClosePage');
    getPageWidth = dynamicLibrary.lookupFunction<FpdfGetPageWidthFNative, FpdfGetPageWidthFDart>('FPDF_GetPageWidthF');
    getPageHeight = dynamicLibrary.lookupFunction<FpdfGetPageHeightFNative, FpdfGetPageHeightFDart>('FPDF_GetPageHeightF');
    bitmapCreateEx = dynamicLibrary.lookupFunction<FpdfBitmapCreateExNative, FpdfBitmapCreateExDart>('FPDFBitmap_CreateEx');
    bitmapFillRect = dynamicLibrary.lookupFunction<FpdfBitmapFillRectNative, FpdfBitmapFillRectDart>('FPDFBitmap_FillRect');
    renderPageBitmap = dynamicLibrary.lookupFunction<FpdfRenderPageBitmapNative, FpdfRenderPageBitmapDart>('FPDF_RenderPageBitmap');
    bitmapGetBuffer = dynamicLibrary.lookupFunction<FpdfBitmapGetBufferNative, FpdfBitmapGetBufferDart>('FPDFBitmap_GetBuffer');
    bitmapDestroy = dynamicLibrary.lookupFunction<FpdfBitmapDestroyNative, FpdfBitmapDestroyDart>('FPDFBitmap_Destroy');
    textLoadPage = dynamicLibrary.lookupFunction<FpdfTextLoadPageNative, FpdfTextLoadPageDart>('FPDFText_LoadPage');
    textClosePage = dynamicLibrary.lookupFunction<FpdfTextClosePageNative, FpdfTextClosePageDart>('FPDFText_ClosePage');
    textCountChars = dynamicLibrary.lookupFunction<FpdfTextCountCharsNative, FpdfTextCountCharsDart>('FPDFText_CountChars');
    textGetText = dynamicLibrary.lookupFunction<FpdfTextGetTextNative, FpdfTextGetTextDart>('FPDFText_GetText');
    textGetCharBox = dynamicLibrary.lookupFunction<FpdfTextGetCharBoxNative, FpdfTextGetCharBoxDart>('FPDFText_GetCharBox');
    textGetFontSize = dynamicLibrary.lookupFunction<FpdfTextGetFontSizeNative, FpdfTextGetFontSizeDart>('FPDFText_GetFontSize');
    getLastError = dynamicLibrary.lookupFunction<FpdfGetLastErrorNative, FpdfGetLastErrorDart>('FPDF_GetLastError');
  }
}

/// Official PDFium error codes returned by FPDF_GetLastError.
abstract class PdfiumErrorCodes {
  /// No error.
  static const int success = 0;
  /// Unknown error.
  static const int unknown = 1;
  /// File not found or could not be opened.
  static const int fileNotFound = 2;
  /// File not in PDF format or corrupted.
  static const int formatError = 3;
  /// Password required or incorrect password.
  static const int passwordRequired = 4;
  /// Unsupported security scheme.
  static const int securityUnsupported = 5;
  /// Page not found or content error.
  static const int pageError = 6;
  /// Load XFA error.
  static const int xfaLoadError = 7;
  /// Layout XFA error.
  static const int xfaLayoutError = 8;
}
