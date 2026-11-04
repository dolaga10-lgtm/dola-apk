import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workshop_models.dart';
import 'workshop_storage.dart';

/// معالج ومُشكّل النصوص العربية للـ PDF (Arabic Reshaper)
class ArabicReshaper {
  static const Map<int, List<int>> _arabicTable = {
    0x0621: [0xFE80, 0xFE80, 0xFE80, 0xFE80], // Hamza
    0x0622: [0xFE81, 0xFE82, 0xFE81, 0xFE82], // Alef with madda
    0x0623: [0xFE83, 0xFE84, 0xFE83, 0xFE84], // Alef with hamza above
    0x0624: [0xFE85, 0xFE86, 0xFE85, 0xFE86], // Waw with hamza
    0x0625: [0xFE87, 0xFE88, 0xFE87, 0xFE88], // Alef with hamza below
    0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // Yeh with hamza
    0x0627: [0xFE8D, 0xFE8E, 0xFE8D, 0xFE8E], // Alef
    0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // Beh
    0x0629: [0xFE93, 0xFE94, 0xFE93, 0xFE94], // Teh Marbuta
    0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // Teh
    0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // Theh
    0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // Jeem
    0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // Hah
    0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // Khah
    0x062F: [0xFEA9, 0xFEAA, 0xFEA9, 0xFEAA], // Dal
    0x0630: [0xFEAB, 0xFEAC, 0xFEAB, 0xFEAC], // Thal
    0x0631: [0xFEAD, 0xFEAE, 0xFEAD, 0xFEAE], // Reh
    0x0632: [0xFEAF, 0xFEB0, 0xFEAF, 0xFEB0], // Zain
    0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // Seen
    0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // Sheen
    0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // Sad
    0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // Dad
    0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // Tah
    0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // Zah
    0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // Ain
    0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // Ghain
    0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // Feh
    0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // Qaf
    0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC], // Kaf
    0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // Lam
    0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // Meem
    0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // Noon
    0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // Heh
    0x0648: [0xFEED, 0xFEEE, 0xFEED, 0xFEEE], // Waw
    0x0649: [0xFEEF, 0xFEF0, 0xFEEF, 0xFEF0], // Alef Maksura
    0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4], // Yeh
    0x067E: [0xFB56, 0xFB57, 0xFB58, 0xFB59], // Peh
    0x0686: [0xFB7A, 0xFB7B, 0xFB7C, 0xFB7D], // Tcheh
    0x06A4: [0xFB6A, 0xFB6B, 0xFB6C, 0xFB6D], // Veh
    0x06AF: [0xFB92, 0xFB93, 0xFB94, 0xFB95], // Gaf
  };

  static const Set<int> _nonConnectingNext = {
    0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0627, 0x062F, 0x0630, 0x0631, 0x0632, 0x0648, 0x0629,
    0xFEF5, 0xFEF6, 0xFEF7, 0xFEF8, 0xFEF9, 0xFEFA, 0xFEFB, 0xFEFC,
  };

  static bool _canConnectNext(int code) {
    return _arabicTable.containsKey(code) && !_nonConnectingNext.contains(code);
  }

  static bool _canConnectPrev(int code) {
    return _arabicTable.containsKey(code) && code != 0x0621;
  }

  static String reshape(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll('²', '2').replaceAll('³', '3');

    final codeUnits = text.codeUnits;
    final n = codeUnits.length;

    final List<int> intermediate = [];
    int i = 0;
    while (i < n) {
      if (i + 1 < n && codeUnits[i] == 0x0644) {
        final next = codeUnits[i + 1];
        List<int>? la;
        if (next == 0x0622) la = [0xFEF5, 0xFEF6];
        else if (next == 0x0623) la = [0xFEF7, 0xFEF8];
        else if (next == 0x0625) la = [0xFEF9, 0xFEFA];
        else if (next == 0x0627) la = [0xFEFB, 0xFEFC];

        if (la != null) {
          final bool prevConn = (i > 0 && _canConnectNext(codeUnits[i - 1]));
          intermediate.add(prevConn ? la[1] : la[0]);
          i += 2;
          continue;
        }
      }
      intermediate.add(codeUnits[i]);
      i++;
    }

    final m = intermediate.length;
    final List<int> resultCodes = [];

    for (int j = 0; j < m; j++) {
      final c = intermediate[j];
      final forms = _arabicTable[c];
      if (forms == null) {
        resultCodes.add(c);
        continue;
      }

      final bool prevConn = (j > 0 && _canConnectNext(intermediate[j - 1]));
      final bool nextConn = (j + 1 < m && _canConnectPrev(intermediate[j + 1]));

      if (prevConn && nextConn) {
        resultCodes.add(forms[3]);
      } else if (prevConn) {
        resultCodes.add(forms[1]);
      } else if (nextConn) {
        resultCodes.add(forms[2]);
      } else {
        resultCodes.add(forms[0]);
      }
    }

    return String.fromCharCodes(resultCodes);
  }
}

String ar(String text) => ArabicReshaper.reshape(text);

class PdfGeneratorService {
  static pw.Font? _arabicFont;
  static pw.Font? _rubikRegular;
  static pw.Font? _rubikBold;
  static pw.MemoryImage? _hafezLogoImage;

  static const PdfColor _themeTeal = PdfColor.fromInt(0xFF31869B);
  static const PdfColor _themeBlue = PdfColor.fromInt(0xFF538DD5);
  static const PdfColor _tableBorder = PdfColors.black;

  static Future<void> _ensureAssetsLoaded() async {
    if (_arabicFont == null) {
      try {
        final hacenData = await rootBundle.load('assets/fonts/Hacen_Tunisia.ttf');
        _arabicFont = pw.Font.ttf(hacenData);
      } catch (_) {}
    }
    if (_rubikRegular == null || _rubikBold == null) {
      try {
        final regData = await rootBundle.load('assets/fonts/Rubik-Regular.ttf');
        final boldData = await rootBundle.load('assets/fonts/Rubik-Bold.ttf');
        _rubikRegular = pw.Font.ttf(regData);
        _rubikBold = pw.Font.ttf(boldData);
      } catch (_) {}
    }
    if (_hafezLogoImage == null) {
      try {
        final logoBytes = await rootBundle.load('assets/images/hafez_logo.png');
        _hafezLogoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {
        try {
          final iconBytes = await rootBundle.load('assets/images/hafez_icon.png');
          _hafezLogoImage = pw.MemoryImage(iconBytes.buffer.asUint8List());
        } catch (_) {}
      }
    }
  }

  /// 1. توليد كشف عرض السعر المعماري المطابق تماماً لنموذج شركة حافظ المعتمد (أ. احمد ابو اليزيد.pdf)
  static Future<Uint8List> buildQuotationPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureAssetsLoaded();
    final pdf = pw.Document();
    final bool minOneM2 = storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalAreaAll = 0.0;
    int totalQuantityAll = 0;
    double grandTotalAll = 0.0;

    for (final it in client.items) {
      final double area = it.totalAreaM2(minOneM2: minOneM2);
      final double cost = it.calculateTotalCost(storage.getSectorById(it.sectorId), minOneM2: minOneM2);
      totalAreaAll += area;
      totalQuantityAll += it.quantity;
      grandTotalAll += cost;
    }

    final double netTotal = (grandTotalAll - client.discountAmount).clamp(0.0, double.infinity);
    final double finalQuotationTotal = (netTotal + client.archCost - client.depositAmount).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(792, 612), // Landscape Letter / A4
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont ?? _rubikRegular!,
          bold: _arabicFont ?? _rubikBold!,
          fontFallback: [_rubikRegular ?? _arabicFont!],
        ),
        build: (context) => [
          // رأس الصفحة المتطابق: لوجو حافظ في المنتصف، العميل يميناً، والمكان يساراً
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // المكان / العنوان (على اليسار في الترويسة)
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _themeTeal,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      ar('المكان /'),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      ar(client.clientAddress.isNotEmpty ? client.clientAddress : 'ابراج الروضه شارع ناصر'),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                    ),
                  ],
                ),
              ),

              // اللوجو المعتمد في المنتصف
              if (_hafezLogoImage != null)
                pw.Container(
                  width: 58,
                  height: 58,
                  child: pw.Image(_hafezLogoImage!, fit: pw.BoxFit.contain),
                )
              else
                pw.Text(
                  ar('شركة الحافظ'),
                  style: pw.TextStyle(color: _themeTeal, fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),

              // أسم العميل / (على اليمين في الترويسة)
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _themeTeal,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      ar('أسم العميل /'),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      ar(client.clientName.isNotEmpty ? client.clientName : 'أ. احمد ابو اليزيد'),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // الجدول الرئيسي ذو الـ 13 عموداً المتطابق بالملي
          pw.Table(
            border: pw.TableBorder.all(color: _tableBorder, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(26), // No.
              1: pw.FixedColumnWidth(55), // رسومات
              2: pw.FixedColumnWidth(44), // عرض
              3: pw.FixedColumnWidth(44), // طول
              4: pw.FixedColumnWidth(42), // متر مربع
              5: pw.FixedColumnWidth(85), // توصيف
              6: pw.FixedColumnWidth(40), // لون القطاع
              7: pw.FixedColumnWidth(75), // نوع الزجاج
              8: pw.FixedColumnWidth(44), // سعر المتر
              9: pw.FixedColumnWidth(52), // سعر الوحدة
              10: pw.FixedColumnWidth(26), // عدد
              11: pw.FixedColumnWidth(52), // اجمالي المتر المربع
              12: pw.FixedColumnWidth(62), // اجمالي السعر
            },
            children: [
              // صف عناوين الجدول
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _themeTeal),
                children: [
                  _buildHeaderCell('No.'),
                  _buildHeaderCell('رسومات'),
                  _buildHeaderCell('عرض'),
                  _buildHeaderCell('طول'),
                  _buildHeaderCell('متر مربع'),
                  _buildHeaderCell('توصيف'),
                  _buildHeaderCell('لون القطاع'),
                  _buildHeaderCell('نوع\nالزجاج'),
                  _buildHeaderCell('سعر المتر'),
                  _buildHeaderCell('سعر الوحدة'),
                  _buildHeaderCell('عدد'),
                  _buildHeaderCell('اجمالي المتر\nالمربع'),
                  _buildHeaderCell('اجمالي السعر'),
                ],
              ),

              // صفوف البيانات لكل شباك/باب
              ...List.generate(client.items.length, (i) {
                final item = client.items[i];
                final sector = storage.getSectorById(item.sectorId);
                final double singleArea = item.singleWindowAreaM2(minOneM2: minOneM2);
                final double totalArea = item.totalAreaM2(minOneM2: minOneM2);
                final double rowTotal = item.calculateTotalCost(sector, minOneM2: minOneM2);
                final double unitPrice = item.quantity > 0 ? (rowTotal / item.quantity) : rowTotal;

                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _buildTextCell('W${i + 1}', fontSize: 8.5),
                    _buildWindowSketchCell(item),
                    _buildTextCell('${item.widthCm.toStringAsFixed(0)} cm', fontSize: 8),
                    _buildTextCell('${item.heightCm.toStringAsFixed(0)} cm', fontSize: 8),
                    _buildTextCell(singleArea.toStringAsFixed(2), fontSize: 8.5, isBold: true),
                    _buildTextCell('${item.openType} ${item.sashCount} ضلفة\n${item.sectorName}', fontSize: 8),
                    _buildTextCell(item.sectorColor, fontSize: 8),
                    _buildTextCell(item.glassSummaryText, fontSize: 7.5),
                    _buildTextCell(item.sectorPricePerM2.toStringAsFixed(0), fontSize: 8),
                    _buildTextCell(_formatNumber(unitPrice), fontSize: 8.5, isBold: true),
                    _buildTextCell('${item.quantity}', fontSize: 8.5),
                    _buildTextCell(totalArea.toStringAsFixed(2), fontSize: 8.5, isBold: true),
                    _buildTextCell(_formatNumber(rowTotal), fontSize: 9, isBold: true),
                  ],
                );
              }),

              // صف التجميع السفلي للجدول
              pw.TableRow(
                children: [
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  _buildSummaryBadge('${totalQuantityAll}'),
                  _buildSummaryBadge('${totalAreaAll.toStringAsFixed(2)} m2'),
                  _buildSummaryBadge('${_formatNumber(grandTotalAll)} EGP'),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // القسم السفلي: بوكس العربون والدورانات على اليمين، والشروط والملاحظات على اليسار
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // الملاحظات وشروط التعاقد الرسمية
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      ar('وتفضلوا بقبول فائق الاحترام،،،'),
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF334155)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      ar('ملحوظة هامة : السعر لا يشمل النقل والمشال'),
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                    ),
                    pw.Text(
                      ar('نوع القطاع Emapen الحاصل على شهادة الايزو ISO 9001 + جميع الاكسسوارات تركية الصنع'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      ar('ضمان 20 سنة على القطاع + 5 أعوام على الاكسسوارات'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      ar('القطاعات كلها مدعمة بكاوتش مدمج بها وبحديد مجلفن سماكة 1.25 ملل من الداخل'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      ar('الاسعار غير شاملة الضريبة'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      ar('شروط التعاقد : عند التعاقد دفعة 60 % // عند التوريد دفعة 30 % // عند التسليم دفعة 10 %'),
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 16),

              // جدول الإجماليات (العربون، الدورانات، إجمالي المقايسة)
              pw.Container(
                width: 230,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _themeTeal, width: 1),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow(
                      label: 'يضاف للمقايسة قيمة : عربون',
                      value: client.depositAmount > 0 ? '${_formatNumber(client.depositAmount)} EGP' : '-',
                      bgColor: _themeBlue,
                    ),
                    _buildTotalRow(
                      label: 'يضاف للمقايسة قيمة : دورانات',
                      value: client.archCost > 0 ? '${_formatNumber(client.archCost)} EGP' : '-',
                      bgColor: _themeBlue,
                    ),
                    _buildTotalRow(
                      label: 'إجمالي المقايسة',
                      value: '${_formatNumber(finalQuotationTotal)} EGP',
                      bgColor: _themeTeal,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// 2. توليد كشف أمر التشغيل والطلبية الشامل للورشة وتقطيع الأعواد والألواح والزجاج
  static Future<Uint8List> buildCuttingListPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureAssetsLoaded();
    final pdf = pw.Document();

    final List<List<String>> partsCuttingRows = [];
    final List<List<String>> glassCuttingRows = [];

    for (int i = 0; i < client.items.length; i++) {
      final item = client.items[i];
      final sector = storage.getSectorById(item.sectorId);

      if (sector != null) {
        for (final part in sector.parts) {
          final double cutLen = part.calculatePieceLength(item.widthCm, item.heightCm, item.sashCount);
          final int totalPieces = part.calculateTotalPieces(item.sashCount) * item.quantity;

          partsCuttingRows.add([
            item.label,
            sector.name,
            part.name,
            part.role,
            '${cutLen.toStringAsFixed(1)} سم',
            '$totalPieces',
          ]);
        }
      }

      if (item.hasGlass) {
        final double gw = sector != null
            ? sector.calculateGlassWidthCm(item.widthCm, item.sashCount)
            : math.max(0.0, (item.widthCm / (item.sashCount > 0 ? item.sashCount : 1)) - 10.0);
        final double gh = sector != null
            ? sector.calculateGlassHeightCm(item.heightCm, item.sashCount)
            : math.max(0.0, item.heightCm - 18.0);
        final int panesPerWindow = item.sashCount * (item.isDoubleGlass ? 2 : 1);
        final int totalPanes = panesPerWindow * item.quantity;

        glassCuttingRows.add([
          item.label,
          item.glassSummaryText,
          '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
          '$totalPanes لوح',
          '${((gw / 100) * (gh / 100) * totalPanes).toStringAsFixed(2)} م2',
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(792, 612),
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont ?? _rubikRegular!,
          bold: _arabicFont ?? _rubikBold!,
          fontFallback: [_rubikRegular ?? _arabicFont!],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(ar('أمر تشغيل وطلبية الورشة - شركة الحافظ'), style: pw.TextStyle(color: _themeTeal, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (_hafezLogoImage != null)
                pw.Container(width: 48, height: 48, child: pw.Image(_hafezLogoImage!)),
              pw.Text(ar('العميل: ${client.clientName}'), style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Divider(thickness: 1, color: _themeTeal),
          pw.SizedBox(height: 6),

          pw.Text(ar('أولاً: تقطيع أجزاء القطاعات والأعواد (600 سم):'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [ar('الفتحة'), ar('القطاع'), ar('اسم الجزء'), ar('الفئة'), ar('طول القص'), ar('العدد')],
            data: partsCuttingRows.map((r) => r.map((c) => ar(c)).toList()).toList(),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: _themeTeal),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
          ),

          pw.SizedBox(height: 10),
          pw.Text(ar('ثانياً: تقطيع الزجاج والسبيسر:'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [ar('الفتحة'), ar('المواصفات'), ar('مقاس اللوح'), ar('الألواح'), ar('المساحة')],
            data: glassCuttingRows.map((r) => r.map((c) => ar(c)).toList()).toList(),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: _themeBlue),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // دوال بناء خلايا الجدول
  static pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        ar(text),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTextCell(String text, {double fontSize = 8, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        ar(text),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryBadge(String text) {
    return pw.Container(
      color: _themeTeal,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        ar(text),
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow({required String label, required String value, required PdfColor bgColor, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      color: bgColor,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            ar(label),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            ar(value),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: isBold ? 10 : 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // رسمة الشباك الكروكية الملونة داخل خلية جدول عرض السعر
  static pw.Widget _buildWindowSketchCell(ClientWindowItem item) {
    return pw.Container(
      width: 50,
      height: 38,
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.CustomPaint(
        size: const PdfPoint(46, 34),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final double w = size.x;
          final double h = size.y;

          // 1. إطار الحلق بلون القطاع
          final PdfColor frameColor = (item.sectorColor == 'أسود')
              ? const PdfColor.fromInt(0xFF1E293B)
              : ((item.sectorColor == 'بيج')
                  ? const PdfColor.fromInt(0xFFD7CCC8)
                  : const PdfColor.fromInt(0xFFE2E8F0));

          canvas.setFillColor(frameColor);
          canvas.drawRect(0, 0, w, h);
          canvas.fillPath();

          // حدود الحلق الخارجية
          canvas.setStrokeColor(const PdfColor.fromInt(0xFF64748B));
          canvas.setLineWidth(0.8);
          canvas.drawRect(0, 0, w, h);
          canvas.strokePath();

          // 2. زجاج الشباك بلون أزرق سماوي مضيء
          const double frameThick = 2.5;
          final double innerW = w - (frameThick * 2);
          final double innerH = h - (frameThick * 2);

          final int sashes = item.sashCount > 0 ? item.sashCount : 2;
          final double sashW = innerW / sashes;

          for (int s = 0; s < sashes; s++) {
            final double sx = frameThick + (s * sashW);
            final double sy = frameThick;

            // زجاج أزرق سماوي
            canvas.setFillColor(const PdfColor.fromInt(0xFF70CBE0));
            canvas.drawRect(sx + 0.8, sy + 0.8, sashW - 1.6, innerH - 1.6);
            canvas.fillPath();

            // برواز الضلفة
            canvas.setStrokeColor(const PdfColor.fromInt(0xFFFFFFFF));
            canvas.setLineWidth(0.8);
            canvas.drawRect(sx + 0.8, sy + 0.8, sashW - 1.6, innerH - 1.6);
            canvas.strokePath();

            // لمعة الزجاج
            canvas.setStrokeColor(const PdfColor.fromInt(0xFFE0F2FE));
            canvas.setLineWidth(0.6);
            canvas.drawLine(sx + 2, sy + 8, sx + 8, sy + 2);
            canvas.strokePath();

            // مؤشر الفتح
            if (item.openType.contains('مفصلي') || item.openType.contains('قلاب')) {
              canvas.setStrokeColor(const PdfColor.fromInt(0xFF0369A1));
              canvas.setLineWidth(0.5);
              if (s % 2 == 0) {
                canvas.drawLine(sx + 1, sy + 1, sx + sashW - 1, sy + (innerH / 2));
                canvas.drawLine(sx + sashW - 1, sy + (innerH / 2), sx + 1, sy + innerH - 1);
              } else {
                canvas.drawLine(sx + sashW - 1, sy + 1, sx + 1, sy + (innerH / 2));
                canvas.drawLine(sx + 1, sy + (innerH / 2), sx + sashW - 1, sy + innerH - 1);
              }
              canvas.strokePath();
            }
          }
        },
      ),
    );
  }

  static String _formatNumber(double val) {
    final int intVal = val.round();
    final String s = intVal.toString();
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        sb.write(',');
      }
      sb.write(s[i]);
    }
    return sb.toString();
  }

  // دوال التوافق
  static Future<File> savePdfToDevice({required Uint8List bytes, required String filename}) async {
    Directory? targetDir;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        targetDir = downloadDir;
      }
    }
    targetDir ??= await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<File> savePdfToDeviceStorage({required Uint8List bytes, required String fileName}) =>
      savePdfToDevice(bytes: bytes, filename: fileName);

  static Future<void> printOrSharePdf({required Uint8List bytes, required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> previewPdfBytes(Uint8List bytes, String fileName) =>
      printOrSharePdf(bytes: bytes, filename: fileName);

  static Future<Uint8List> buildOrderAndCuttingPdfBytes({required ClientRecord client, required WorkshopStorage storage}) =>
      buildCuttingListPdfBytes(client: client, storage: storage);

  static Future<void> generateAndShareBothPdfs({required ClientRecord client, required WorkshopStorage storage}) async {
    final quoteBytes = await buildQuotationPdfBytes(client: client, storage: storage);
    final orderBytes = await buildCuttingListPdfBytes(client: client, storage: storage);
    final f1 = await savePdfToDevice(bytes: quoteBytes, filename: 'عرض_سعر_شركة_الحافظ_${client.clientName}.pdf');
    final f2 = await savePdfToDevice(bytes: orderBytes, filename: 'كشف_طلبية_شركة_الحافظ_${client.clientName}.pdf');
    await Share.shareXFiles([XFile(f1.path), XFile(f2.path)], text: 'عرض سعر وطلبية العميل: ${client.clientName}');
  }
}
