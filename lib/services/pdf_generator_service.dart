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

  static pw.Widget _buildHafezHeader({
    required String title,
    required String docDate,
    required ClientRecord client,
    required PricingSettings settings,
    PdfColor bannerColor = const PdfColor.fromInt(0xFF1B110A),
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bannerColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (_hafezLogoImage != null)
                pw.Container(
                  width: 52,
                  height: 52,
                  margin: const pw.EdgeInsets.only(left: 10),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(_hafezLogoImage!, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    ar(settings.companyName.isNotEmpty ? settings.companyName : 'شركة الحافظ'),
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFFFDE68A),
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    ar('للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية'),
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFFFEF2F2),
                      fontSize: 8.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    ar(title),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                ar('العميل: ${client.clientName}'),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (client.clientPhone.isNotEmpty)
                pw.Text(
                  ar('الهاتف: ${client.clientPhone}'),
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                ),
              pw.Text(
                ar('التاريخ: $docDate'),
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<Uint8List> buildQuotationPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureAssetsLoaded();
    final pdf = pw.Document();
    final bool minOneM2 = storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalSectorsCost = 0.0;
    double totalGlassAndSpacerCost = 0.0;
    double totalGeorgianCost = 0.0;
    double totalAreaAll = 0.0;

    for (final item in client.items) {
      final sector = storage.getSectorById(item.sectorId);
      final double area = item.totalAreaM2(minOneM2: minOneM2);
      final double secCost = item.calculateSectorCost(minOneM2: minOneM2);
      final double glCost = item.calculateGlassAndSpacerCost(sector, minOneM2: minOneM2);
      final double geoCost = item.calculateGeorgianCost();

      totalAreaAll += area;
      totalSectorsCost += secCost;
      totalGlassAndSpacerCost += glCost;
      totalGeorgianCost += geoCost;
    }

    final double grandSubTotal = totalSectorsCost + totalGlassAndSpacerCost + totalGeorgianCost;
    final double netTotal = (grandSubTotal - client.discountAmount).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont ?? _rubikRegular!,
          bold: _arabicFont ?? _rubikBold!,
          fontFallback: [_rubikRegular ?? _arabicFont!],
        ),
        build: (context) => [
          _buildHafezHeader(
            title: 'كشف عرض سعر مقايسة معتمد بالرسم الهندسي والمواصفات',
            docDate: client.createdAt,
            client: client,
            settings: storage.pricingSettings,
            bannerColor: const PdfColor.fromInt(0xFF1B110A),
          ),
          pw.SizedBox(height: 12),

          ...List.generate(client.items.length, (i) {
            final item = client.items[i];
            final sector = storage.getSectorById(item.sectorId);
            final double area = item.totalAreaM2(minOneM2: minOneM2);
            final double singleArea = item.singleWindowAreaM2(minOneM2: minOneM2);
            final double secCost = item.calculateSectorCost(minOneM2: minOneM2);
            final double glCost = item.calculateGlassAndSpacerCost(sector, minOneM2: minOneM2);
            final double geoCost = item.calculateGeorgianCost();
            final double rowTotal = secCost + glCost + geoCost;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // رسم كروكي معماري بالثوابت والشفاط
                  pw.Container(
                    width: 76,
                    height: 64,
                    margin: const pw.EdgeInsets.only(left: 10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F172A),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFD97706), width: 1),
                    ),
                    child: pw.Center(
                      child: pw.CustomPaint(
                        size: const PdfPoint(60, 48),
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          _drawPdfArchitecturalSchema(
                            canvas,
                            size,
                            item,
                          );
                        },
                      ),
                    ),
                  ),

                  // تفاصيل الفتحة والمواصفات المعمارية
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              ar('${i + 1}. ${item.label} (${item.unitType} - ${item.openType})'),
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                            pw.Text(
                              ar('العدد: ${item.quantity}'),
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ar('القطاع: ${item.sectorName} (${item.barType} - فتح ${item.openDirection})'),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF475569)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ar('التكوين المعماري: ${item.configurationSummary}'),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFB45309)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ar('المقاس: ${item.widthCm.toStringAsFixed(1)} × ${item.heightCm.toStringAsFixed(1)} سم  |  مساحة الوحدة: ${singleArea.toStringAsFixed(2)} م2  |  الإجمالي: ${area.toStringAsFixed(2)} م2'),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF1E293B)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ar('مواصفات الزجاج: ${item.glassSummaryText}'),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),

                  // تفاصيل الأسعار
                  pw.Container(
                    width: 105,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF3C7),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B), width: 0.6),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          ar('متر القطاع: ${item.sectorPricePerM2.toStringAsFixed(0)} ج.م'),
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF78350F)),
                        ),
                        pw.Text(
                          ar('سعر الألومنيوم: ${secCost.toStringAsFixed(0)} ج.م'),
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF78350F)),
                        ),
                        if (glCost > 0)
                          pw.Text(
                            ar('الزجاج والسبيسر: ${glCost.toStringAsFixed(0)} ج.م'),
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF1D4ED8)),
                          ),
                        if (geoCost > 0)
                          pw.Text(
                            ar('الجورجيا: ${geoCost.toStringAsFixed(0)} ج.م'),
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFFB45309)),
                          ),
                        pw.Divider(height: 4, thickness: 0.5, color: const PdfColor.fromInt(0xFFD97706)),
                        pw.Text(
                          ar('الإجمالي: ${rowTotal.toStringAsFixed(0)} ج.م'),
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 10),

          // الملخص المالي
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF1E293B),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      ar('إجمالي عدد الفتحات: ${client.items.fold(0, (sum, it) => sum + it.quantity)} وحدة'),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                    ),
                    pw.Text(
                      ar('إجمالي المساحة بالمتر المربع: ${totalAreaAll.toStringAsFixed(2)} م2'),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                    ),
                    if (client.discountAmount > 0)
                      pw.Text(
                        ar('الخصم الممنوح: -${client.discountAmount.toStringAsFixed(0)} ج.م'),
                        style: const pw.TextStyle(color: PdfColor.fromInt(0xFFFCA5A5), fontSize: 9),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      ar('إجمالي المقايسة قبل الخصم: ${grandSubTotal.toStringAsFixed(0)} ج.م'),
                      style: const pw.TextStyle(color: PdfColor.fromInt(0xFFCBD5E1), fontSize: 9),
                    ),
                    pw.Text(
                      ar('الصافي المطلوب: ${netTotal.toStringAsFixed(0)} ج.م'),
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFFFDE68A),
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
          pw.Text(
            ar('ملاحظات وشروط التوريد والتركيب:'),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            ar(storage.pricingSettings.termsAndConditions.isNotEmpty
                ? storage.pricingSettings.termsAndConditions
                : 'الأسعار تشمل التوريد والتركيب والإكسسوارات الإيطالية الأصلية والضمان المعتمد من شركة الحافظ.'),
            style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF64748B)),
          ),
          if (client.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              ar('ملاحظات خاصة بالعميل: ${client.notes}'),
              style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF0F172A)),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

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

        if (item.hasTopFixed) {
          glassCuttingRows.add([
            '${item.label} (ثابت علوي)',
            'لوح زجاج ثابت علوي',
            '${item.widthCm.toStringAsFixed(1)} × ${item.topFixedHeightCm.toStringAsFixed(1)} سم',
            '${item.quantity} لوح',
            '${((item.widthCm / 100) * (item.topFixedHeightCm / 100) * item.quantity).toStringAsFixed(2)} م2',
          ]);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont ?? _rubikRegular!,
          bold: _arabicFont ?? _rubikBold!,
          fontFallback: [_rubikRegular ?? _arabicFont!],
        ),
        build: (context) => [
          _buildHafezHeader(
            title: 'كشف أمر التشغيل والطلبية الشامل للورشة وتقطيع الأعواد',
            docDate: client.createdAt,
            client: client,
            settings: storage.pricingSettings,
            bannerColor: const PdfColor.fromInt(0xFF14532D),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            ar('أولاً: كشف تخصيم وتقطيع أجزاء القطاعات (الحلق، الضلف، السكاكين، والمكملات):'),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              ar('الفتحة / البند'),
              ar('القطاع'),
              ar('اسم الجزء'),
              ar('الفئة'),
              ar('طول القص الصافي'),
              ar('العدد'),
            ],
            data: partsCuttingRows.map((r) => r.map((c) => ar(c)).toList()).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF15803D),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),

          pw.SizedBox(height: 16),
          pw.Text(
            ar('ثانياً: كشف مقاسات تقطيع الزجاج والسبيسر (شامل الثوابت):'),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              ar('الفتحة'),
              ar('نوع ومواصفات الزجاج'),
              ar('مقاس اللوح الصافي (عرض × ارتفاع)'),
              ar('عدد الألواح'),
              ar('إجمالي المساحة'),
            ],
            data: glassCuttingRows.map((r) => r.map((c) => ar(c)).toList()).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1D4ED8),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),

          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF1F5F9),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF94A3B8), width: 0.6),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  ar('توقيع مسؤول الورشة: .......................................'),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.Text(
                  ar('توقيع مسؤول التسليم والجودة: .......................................'),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// رسم كروكي معماري بالثوابت والشفاط داخل صفحة الـ PDF
  static void _drawPdfArchitecturalSchema(
    PdfGraphics canvas,
    PdfPoint size,
    ClientWindowItem item,
  ) {
    final double w = size.x;
    final double h = size.y;

    canvas.setFillColor(const PdfColor.fromInt(0xFF1E293B));
    canvas.drawRect(0, 0, w, h);
    canvas.fillPath();

    final double barThick = item.barType == 'بدون بار' ? 1.0 : (item.barType == 'بار مقلوب' ? 3.5 : 2.5);
    canvas.setStrokeColor(const PdfColor.fromInt(0xFFD97706));
    canvas.setLineWidth(barThick);
    canvas.drawRect(barThick / 2, barThick / 2, w - barThick, h - barThick);
    canvas.strokePath();

    final double innerW = w - (barThick * 2);
    final double innerH = h - (barThick * 2);

    final double topFixedH = item.hasTopFixed ? innerH * 0.28 : 0.0;
    final double botFixedH = item.hasBottomFixed ? innerH * 0.22 : 0.0;
    final double leftFixedW = item.hasLeftFixed ? innerW * 0.25 : 0.0;
    final double rightFixedW = item.hasRightFixed ? innerW * 0.25 : 0.0;

    final double midY = barThick + topFixedH;
    final double midH = innerH - topFixedH - botFixedH;
    final double midX = barThick + leftFixedW;
    final double midW = innerW - leftFixedW - rightFixedW;

    // ثوابت
    canvas.setFillColor(const PdfColor.fromInt(0xFF0284C7));
    if (item.hasTopFixed) {
      canvas.drawRect(barThick, barThick, innerW, topFixedH);
      canvas.fillPath();
    }
    if (item.hasBottomFixed) {
      canvas.drawRect(barThick, barThick + innerH - botFixedH, innerW, botFixedH);
      canvas.fillPath();
    }
    if (item.hasLeftFixed) {
      canvas.drawRect(barThick, midY, leftFixedW, midH);
      canvas.fillPath();
    }
    if (item.hasRightFixed) {
      canvas.drawRect(barThick + innerW - rightFixedW, midY, rightFixedW, midH);
      canvas.fillPath();
    }

    // درف رئيسية
    final int sashes = item.sashCount > 0 ? item.sashCount : 2;
    final double sashW = midW / sashes;

    for (int i = 0; i < sashes; i++) {
      final double sx = midX + (i * sashW);
      canvas.setFillColor(item.isDoubleGlass ? const PdfColor.fromInt(0xFF0369A1) : const PdfColor.fromInt(0xFF0EA5E9));
      canvas.drawRect(sx + 0.8, midY + 0.8, sashW - 1.6, midH - 1.6);
      canvas.fillPath();

      canvas.setStrokeColor(const PdfColor.fromInt(0xFFFFFFFF));
      canvas.setLineWidth(0.8);
      canvas.drawRect(sx + 0.8, midY + 0.8, sashW - 1.6, midH - 1.6);
      canvas.strokePath();

      // حركة
      if (item.openType.contains('مفصلي') || item.openType.contains('قلاب')) {
        canvas.setStrokeColor(const PdfColor.fromInt(0xFFFDE68A));
        canvas.setLineWidth(0.6);
        if (i % 2 == 0) {
          canvas.drawLine(sx + 1, midY + 1, sx + sashW - 1, midY + (midH / 2));
          canvas.drawLine(sx + sashW - 1, midY + (midH / 2), sx + 1, midY + midH - 1);
        } else {
          canvas.drawLine(sx + sashW - 1, midY + 1, sx + 1, midY + (midH / 2));
          canvas.drawLine(sx + 1, midY + (midH / 2), sx + sashW - 1, midY + midH - 1);
        }
        canvas.strokePath();
      }
    }

    // شفاط
    if (item.hasExhaustFan) {
      canvas.setFillColor(const PdfColor.fromInt(0xFFEF4444));
      if (item.hasTopFixed) {
        canvas.drawEllipse(barThick + (innerW / 2), barThick + (topFixedH / 2), topFixedH * 0.35, topFixedH * 0.35);
      } else {
        canvas.drawEllipse(midX + (midW * 0.75), midY + (midH * 0.35), midH * 0.22, midH * 0.22);
      }
      canvas.fillPath();
    }
  }

  static Future<File> savePdfToDevice({
    required Uint8List bytes,
    required String filename,
  }) async {
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

  static Future<void> printOrSharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// دوال التوافق مع الشاشات السابقة
  static Future<File> savePdfToDeviceStorage({required Uint8List bytes, required String fileName}) =>
      savePdfToDevice(bytes: bytes, filename: fileName);

  static Future<void> previewPdfBytes(Uint8List bytes, String fileName) =>
      printOrSharePdf(bytes: bytes, filename: fileName);

  static Future<Uint8List> buildOrderAndCuttingPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) => buildCuttingListPdfBytes(client: client, storage: storage);

  static Future<void> generateAndShareBothPdfs({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    final quoteBytes = await buildQuotationPdfBytes(client: client, storage: storage);
    final orderBytes = await buildCuttingListPdfBytes(client: client, storage: storage);
    final f1 = await savePdfToDevice(bytes: quoteBytes, filename: 'عرض_سعر_شركة_الحافظ_${client.clientName}.pdf');
    final f2 = await savePdfToDevice(bytes: orderBytes, filename: 'كشف_طلبية_شركة_الحافظ_${client.clientName}.pdf');
    await Share.shareXFiles([XFile(f1.path), XFile(f2.path)], text: 'عرض سعر وطلبية العميل: ${client.clientName}');
  }
}
