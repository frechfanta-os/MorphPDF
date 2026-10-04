/// Precise unit conversion utilities for ECMA-376 / ISO/IEC 29500 (OOXML) documents.
class OoxmlUnits {
  // Constants
  static const double pointsPerInch = 72.0;
  static const double twipsPerPoint = 20.0;
  static const double twipsPerInch = 1440.0;
  static const double emuPerPoint = 12700.0;
  static const double emuPerInch = 914400.0;
  static const double halfPointsPerPoint = 2.0;

  // Standard Page Dimensions in PDF Points (1/72 inch)
  static const double a4WidthPt = 595.28;
  static const double a4HeightPt = 841.89;
  static const double letterWidthPt = 612.0;
  static const double letterHeightPt = 792.0;
  static const double defaultMarginPt = 72.0; // 1 inch = 1440 twips

  /// Converts PDF points (1/72 inch) to Word twips (1/20 of a point).
  static int pointsToTwips(double pt) {
    return (pt * twipsPerPoint).round();
  }

  /// Converts Word twips to PDF points.
  static double twipsToPoints(int twips) {
    return twips / twipsPerPoint;
  }

  /// Converts PDF points to DrawingML English Metric Units (EMU).
  /// 1 pt = 12,700 EMU (1 inch = 914,400 EMU).
  static int pointsToEmu(double pt) {
    return (pt * emuPerPoint).round();
  }

  /// Converts EMU to PDF points.
  static double emuToPoints(int emu) {
    return emu / emuPerPoint;
  }

  /// Converts PDF points to OOXML font size in half-points.
  /// Example: 12 pt -> 24 half-points (`<w:sz w:val="24"/>`).
  static int pointsToHalfPoints(double pt) {
    final hp = (pt * halfPointsPerPoint).round();
    return hp > 0 ? hp : 24; // Default to 12 pt (24 hp) if non-positive
  }

  /// Converts half-points to PDF points.
  static double halfPointsToPoints(int halfPoints) {
    return halfPoints / halfPointsPerPoint;
  }
}
