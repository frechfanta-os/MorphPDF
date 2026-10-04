/// Generates valid ECMA-376 word/numbering.xml for bullet and numbered lists.
class OoxmlNumbering {
  /// Generates the complete word/numbering.xml document.
  static String generateNumberingXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <!-- Abstract num 1: Standard bullet list -->
  <w:abstractNum w:abstractNumId="1">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:lvlText w:val="•"/>
      <w:lvlJc w:val="left"/>
      <w:pPr>
        <w:ind w:left="720" w:hanging="360"/>
      </w:pPr>
      <w:rPr>
        <w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/>
      </w:rPr>
    </w:lvl>
  </w:abstractNum>

  <!-- Abstract num 2: Standard decimal numbered list (1., 2., 3.) -->
  <w:abstractNum w:abstractNumId="2">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="decimal"/>
      <w:lvlText w:val="%1."/>
      <w:lvlJc w:val="left"/>
      <w:pPr>
        <w:ind w:left="720" w:hanging="360"/>
      </w:pPr>
    </w:lvl>
  </w:abstractNum>

  <!-- Abstract num 3: Alphabetical numbered list (a), b), c)) -->
  <w:abstractNum w:abstractNumId="3">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="lowerLetter"/>
      <w:lvlText w:val="%1)"/>
      <w:lvlJc w:val="left"/>
      <w:pPr>
        <w:ind w:left="720" w:hanging="360"/>
      </w:pPr>
    </w:lvl>
  </w:abstractNum>

  <!-- Abstract num 4: Arabic RTL numbered list -->
  <w:abstractNum w:abstractNumId="4">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="decimal"/>
      <w:lvlText w:val="%1."/>
      <w:lvlJc w:val="right"/>
      <w:pPr>
        <w:ind w:right="720" w:hanging="360"/>
      </w:pPr>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Traditional Arabic"/>
        <w:rtl/>
      </w:rPr>
    </w:lvl>
  </w:abstractNum>

  <!-- Concrete num 1: Bullet list instance -->
  <w:num w:numId="1">
    <w:abstractNumId w:val="1"/>
  </w:num>

  <!-- Concrete num 2: Decimal ordered list instance -->
  <w:num w:numId="2">
    <w:abstractNumId w:val="2"/>
  </w:num>

  <!-- Concrete num 3: Letter ordered list instance -->
  <w:num w:numId="3">
    <w:abstractNumId w:val="3"/>
  </w:num>

  <!-- Concrete num 4: Arabic RTL ordered list instance -->
  <w:num w:numId="4">
    <w:abstractNumId w:val="4"/>
  </w:num>
</w:numbering>''';
  }
}
