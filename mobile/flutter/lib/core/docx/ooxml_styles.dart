/// Generates valid OOXML styles.xml and settings.xml documents conforming to ECMA-376.
class OoxmlStyles {
  /// Generates word/styles.xml defining Normal, Headings, and default fonts.
  static String generateStylesXml({
    String defaultLatinFont = 'Calibri',
    String defaultArabicFont = 'Traditional Arabic',
  }) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="$defaultLatinFont" w:hAnsi="$defaultLatinFont" w:eastAsia="SimSun" w:cs="$defaultArabicFont"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="26"/>
        <w:lang w:val="fr-FR" w:eastAsia="zh-CN" w:bidi="ar-SA"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="160" w:line="240" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>

  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="240" w:after="120"/>
    </w:pPr>
    <w:rPr>
      <w:b/>
      <w:bCs/>
      <w:color w:val="1F497D"/>
      <w:sz w:val="32"/>
      <w:szCs w:val="34"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="180" w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:b/>
      <w:bCs/>
      <w:color w:val="2E74B5"/>
      <w:sz w:val="26"/>
      <w:szCs w:val="28"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="120" w:after="60"/>
    </w:pPr>
    <w:rPr>
      <w:b/>
      <w:bCs/>
      <w:color w:val="595959"/>
      <w:sz w:val="24"/>
      <w:szCs w:val="26"/>
    </w:rPr>
  </w:style>

  <w:style w:type="table" w:default="1" w:styleId="TableNormal">
    <w:name w:val="Normal Table"/>
    <w:tblPr>
      <w:tblCellMar>
        <w:top w:w="120" w:type="dxa"/>
        <w:left w:w="160" w:type="dxa"/>
        <w:bottom w:w="120" w:type="dxa"/>
        <w:right w:w="160" w:type="dxa"/>
      </w:tblCellMar>
    </w:tblPr>
  </w:style>
</w:styles>''';
  }

  /// Generates word/settings.xml with compatibility settings.
  static String generateSettingsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:zoom w:percent="100"/>
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
  <w:compat>
    <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
  </w:compat>
</w:settings>''';
  }
}
