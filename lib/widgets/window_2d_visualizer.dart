import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ويدجت رسم هندسي احترافي يحاكي شاشة معاينة وتصميم الفتحات المعمارية بالكامل
/// تدعم: الثابت العلوي، الثابت السفلي، الثابت يمين/شمال، فتحة الشفاط الدائرية والمربعة،
/// وأنظمة الفتح (جرار 2، 3، 4 درف، مفصلي يمين/شمال/داخل/خارج، قلاب، ثابت)،
/// مع خطوط الأبعاد المعمارية، نوع البار، عواكس الزجاج، وشبكات الجورجيا.
class Window2DVisualizer extends StatelessWidget {
  final double widthCm;
  final double heightCm;
  final String unitType; // شباك | باب | مطبخ
  final String openType; // جرار | مفصلي | قلاب | ثابت
  final int sashCount; // 1, 2, 3, 4
  final String barType; // بار عادي | بار مقلوب | بدون بار
  final String openDirection; // يمين للداخل | شمال للداخل | يمين للخارج | شمال للخارج | جرار يمين | جرار شمال

  // التكوين المعماري المتقدم (الثوابت والشفاط)
  final bool hasTopFixed;
  final double topFixedHeightCm;
  final bool hasBottomFixed;
  final double bottomFixedHeightCm;
  final bool hasRightFixed;
  final double rightFixedWidthCm;
  final bool hasLeftFixed;
  final double leftFixedWidthCm;
  final bool hasExhaustFan;
  final String exhaustFanShape; // دائري | مربع
  final double exhaustFanDiameterCm;
  final String exhaustFanPosition; // في الثابت العلوي | في الدرفة يمين | في الدرفة شمال

  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;
  final double height;

  const Window2DVisualizer({
    super.key,
    required this.widthCm,
    required this.heightCm,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.sashCount = 2,
    this.barType = 'بار عادي',
    this.openDirection = 'يمين للداخل',
    this.hasTopFixed = false,
    this.topFixedHeightCm = 40.0,
    this.hasBottomFixed = false,
    this.bottomFixedHeightCm = 40.0,
    this.hasRightFixed = false,
    this.rightFixedWidthCm = 40.0,
    this.hasLeftFixed = false,
    this.leftFixedWidthCm = 40.0,
    this.hasExhaustFan = false,
    this.exhaustFanShape = 'دائري',
    this.exhaustFanDiameterCm = 25.0,
    this.exhaustFanPosition = 'في الثابت العلوي',
    this.hasGlass = true,
    this.isDoubleGlass = false,
    this.hasGeorgian = false,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // خلفية المخطط الهندسي (Blueprint Dark Slate)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            // شبكة رسم هندسي معماري (CAD Blueprint Grid)
            CustomPaint(
              size: Size.infinite,
              painter: ArchitecturalGridPainter(),
            ),

            // شاشة الرسم المعماري للفتحة بمكوناتها
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: CustomPaint(
                size: Size.infinite,
                painter: ArchitecturalWindowPainter(
                  widthCm: widthCm,
                  heightCm: heightCm,
                  unitType: unitType,
                  openType: openType,
                  sashCount: sashCount,
                  barType: barType,
                  openDirection: openDirection,
                  hasTopFixed: hasTopFixed,
                  topFixedHeightCm: topFixedHeightCm,
                  hasBottomFixed: hasBottomFixed,
                  bottomFixedHeightCm: bottomFixedHeightCm,
                  hasRightFixed: hasRightFixed,
                  rightFixedWidthCm: rightFixedWidthCm,
                  hasLeftFixed: hasLeftFixed,
                  leftFixedWidthCm: leftFixedWidthCm,
                  hasExhaustFan: hasExhaustFan,
                  exhaustFanShape: exhaustFanShape,
                  exhaustFanDiameterCm: exhaustFanDiameterCm,
                  exhaustFanPosition: exhaustFanPosition,
                  hasGlass: hasGlass,
                  isDoubleGlass: isDoubleGlass,
                  hasGeorgian: hasGeorgian,
                ),
              ),
            ),

            // شريط علوي يوضح نوع الفتحة والخصائص المعمارية
            Positioned(
              top: 6,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                ),
                child: Text(
                  _buildStatusBadge(),
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // شريط سفلي للأبعاد الكلية والمساحة
            Positioned(
              bottom: 6,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                ),
                child: Text(
                  '${widthCm.toStringAsFixed(1)} × ${heightCm.toStringAsFixed(1)} سم  |  ${((widthCm / 100) * (heightCm / 100)).toStringAsFixed(2)} م²',
                  style: const TextStyle(
                    color: Color(0xFFBAE6FD),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildStatusBadge() {
    final List<String> tags = [];
    tags.add(unitType);
    if (openType == 'ثابت') {
      tags.add('ثابت بالكامل');
    } else {
      tags.add('$openType $sashCount درفة');
    }
    if (hasTopFixed) tags.add('ثابت علوي');
    if (hasBottomFixed) tags.add('ثابت سفلي');
    if (hasRightFixed || hasLeftFixed) tags.add('ثابت جانبي');
    if (hasExhaustFan) tags.add('فتحة شفاط');
    return tags.join(' • ');
  }
}

/// رسم شبكة الـ CAD Blueprint
class ArchitecturalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.6)
      ..strokeWidth = 0.5;

    const double step = 15.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// الرسام المعماري الدقيق (ArchitecturalWindowPainter)
class ArchitecturalWindowPainter extends CustomPainter {
  final double widthCm;
  final double heightCm;
  final String unitType;
  final String openType;
  final int sashCount;
  final String barType;
  final String openDirection;
  final bool hasTopFixed;
  final double topFixedHeightCm;
  final bool hasBottomFixed;
  final double bottomFixedHeightCm;
  final bool hasRightFixed;
  final double rightFixedWidthCm;
  final bool hasLeftFixed;
  final double leftFixedWidthCm;
  final bool hasExhaustFan;
  final String exhaustFanShape;
  final double exhaustFanDiameterCm;
  final String exhaustFanPosition;
  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;

  ArchitecturalWindowPainter({
    required this.widthCm,
    required this.heightCm,
    required this.unitType,
    required this.openType,
    required this.sashCount,
    required this.barType,
    required this.openDirection,
    required this.hasTopFixed,
    required this.topFixedHeightCm,
    required this.hasBottomFixed,
    required this.bottomFixedHeightCm,
    required this.hasRightFixed,
    required this.rightFixedWidthCm,
    required this.hasLeftFixed,
    required this.leftFixedWidthCm,
    required this.hasExhaustFan,
    required this.exhaustFanShape,
    required this.exhaustFanDiameterCm,
    required this.exhaustFanPosition,
    required this.hasGlass,
    required this.isDoubleGlass,
    required this.hasGeorgian,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double safeW = math.max(10.0, widthCm);
    final double safeH = math.max(10.0, heightCm);
    final double aspect = safeW / safeH;

    double drawW = size.width;
    double drawH = drawW / aspect;

    if (drawH > size.height) {
      drawH = size.height;
      drawW = drawH * aspect;
    }

    final double startX = (size.width - drawW) / 2;
    final double startY = (size.height - drawH) / 2;
    final Rect frameRect = Rect.fromLTWH(startX, startY, drawW, drawH);

    // 1. رسم البار الخارجي (بار عادي / مقلوب)
    if (barType != 'بدون بار') {
      final double barThick = math.min(8.0, drawW * 0.045);
      final barPaint = Paint()
        ..color = barType == 'بار مقلوب'
            ? const Color(0xFF78350F)
            : const Color(0xFF92400E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = barThick;

      canvas.drawRect(frameRect.inflate(barThick / 2), barPaint);

      final miterPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 1.0;
      canvas.drawLine(frameRect.topLeft, frameRect.topLeft.translate(-barThick, -barThick), miterPaint);
      canvas.drawLine(frameRect.topRight, frameRect.topRight.translate(barThick, -barThick), miterPaint);
      canvas.drawLine(frameRect.bottomLeft, frameRect.bottomLeft.translate(-barThick, barThick), miterPaint);
      canvas.drawLine(frameRect.bottomRight, frameRect.bottomRight.translate(barThick, barThick), miterPaint);
    }

    // 2. الحلق الأساسي الخارجي (Outer Frame)
    final double frameProfileW = math.min(10.0, drawW * 0.05);
    final outerFramePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameProfileW;

    canvas.drawRect(frameRect, outerFramePaint);

    final innerRect = frameRect.deflate(frameProfileW / 2);

    // 3. تقسيم الفتحة إلى أجزاء: علوي، سفلي، يمين، شمال، والوسط المتحرك
    final double scaleX = innerRect.width / safeW;
    final double scaleY = innerRect.height / safeH;

    final double topFixedH = hasTopFixed ? math.min(topFixedHeightCm * scaleY, innerRect.height * 0.45) : 0.0;
    final double bottomFixedH = hasBottomFixed ? math.min(bottomFixedHeightCm * scaleY, innerRect.height * 0.45) : 0.0;
    final double leftFixedW = hasLeftFixed ? math.min(leftFixedWidthCm * scaleX, innerRect.width * 0.45) : 0.0;
    final double rightFixedW = hasRightFixed ? math.min(rightFixedWidthCm * scaleX, innerRect.width * 0.45) : 0.0;

    final double midY = innerRect.top + topFixedH;
    final double midH = innerRect.height - topFixedH - bottomFixedH;
    final double midX = innerRect.left + leftFixedW;
    final double midW = innerRect.width - leftFixedW - rightFixedW;

    final transomPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // أ) رسم الثابت العلوي إن وجد
    if (hasTopFixed && topFixedH > 0) {
      final Rect topRect = Rect.fromLTWH(innerRect.left, innerRect.top, innerRect.width, topFixedH);
      _drawFixedPanel(canvas, topRect, 'ثابت علوي', isTopTransom: true);
      canvas.drawLine(Offset(innerRect.left, midY), Offset(innerRect.right, midY), transomPaint);
    }

    // ب) رسم الثابت السفلي إن وجد
    if (hasBottomFixed && bottomFixedH > 0) {
      final double botY = innerRect.bottom - bottomFixedH;
      final Rect botRect = Rect.fromLTWH(innerRect.left, botY, innerRect.width, bottomFixedH);
      _drawFixedPanel(canvas, botRect, 'ثابت سفلي', isTopTransom: false);
      canvas.drawLine(Offset(innerRect.left, botY), Offset(innerRect.right, botY), transomPaint);
    }

    // ج) رسم الثابت الأيسر إن وجد
    if (hasLeftFixed && leftFixedW > 0) {
      final Rect leftRect = Rect.fromLTWH(innerRect.left, midY, leftFixedW, midH);
      _drawFixedPanel(canvas, leftRect, 'ثابت شمال', isTopTransom: false);
      canvas.drawLine(Offset(midX, midY), Offset(midX, midY + midH), transomPaint);
    }

    // د) رسم الثابت الأيمن إن وجد
    if (hasRightFixed && rightFixedW > 0) {
      final double rightX = innerRect.right - rightFixedW;
      final Rect rightRect = Rect.fromLTWH(rightX, midY, rightFixedW, midH);
      _drawFixedPanel(canvas, rightRect, 'ثابت يمين', isTopTransom: false);
      canvas.drawLine(Offset(rightX, midY), Offset(rightX, midY + midH), transomPaint);
    }

    // هـ) رسم الجزء الرئيسي المتحرك (أو الثابت إذا كانت الفتحة بالكامل ثابتة)
    final Rect mainOpeningRect = Rect.fromLTWH(midX, midY, midW, midH);
    if (openType == 'ثابت') {
      _drawFixedPanel(canvas, mainOpeningRect, 'ثابت رئيسي', isTopTransom: false);
    } else {
      _drawOperableSashes(canvas, mainOpeningRect);
    }

    // 4. رسم فتحة الشفاط (Exhaust Fan) إن وجدت
    if (hasExhaustFan) {
      _drawExhaustFan(canvas, innerRect, topFixedH, midX, midY, midW, midH, scaleX, scaleY);
    }

    // 5. رسم خطوط الأبعاد المعمارية (Dimension Lines)
    _drawDimensionLines(canvas, frameRect, drawW, drawH, startX, startY);
  }

  void _drawFixedPanel(Canvas canvas, Rect r, String label, {required bool isTopTransom}) {
    if (r.width <= 2 || r.height <= 2) return;

    // لون زجاج الثابت
    final glassPaint = Paint()
      ..color = isDoubleGlass
          ? const Color(0xFF0284C7).withOpacity(0.35)
          : const Color(0xFF38BDF8).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(r, glassPaint);

    // باكتة الزجاج (Glass Bead)
    final beadPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(r.deflate(2.0), beadPaint);

    // جورجيا بالثابت
    if (hasGeorgian) {
      _drawGeorgianGrid(canvas, r.deflate(3.0));
    }

    // لمعة الزجاج المعمارية
    _drawGlassReflections(canvas, r.deflate(4.0));
  }

  void _drawOperableSashes(Canvas canvas, Rect r) {
    if (r.width <= 4 || r.height <= 4) return;

    final int count = math.max(1, sashCount);
    final double sashW = r.width / count;
    final double sashProfileThick = math.min(7.0, sashW * 0.12);

    for (int i = 0; i < count; i++) {
      final double sx = r.left + (i * sashW);
      final Rect sashRect = Rect.fromLTWH(sx, r.top, sashW, r.height);

      // لون زجاج الدرفة
      final glassPaint = Paint()
        ..color = isDoubleGlass
            ? const Color(0xFF0369A1).withOpacity(0.40)
            : const Color(0xFF0EA5E9).withOpacity(0.30)
        ..style = PaintingStyle.fill;
      canvas.drawRect(sashRect, glassPaint);

      // إطار الدرفة (Sash Frame Profile)
      final sashProfilePaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sashProfileThick;
      canvas.drawRect(sashRect.deflate(sashProfileThick / 2), sashProfilePaint);

      final Rect innerSashGlass = sashRect.deflate(sashProfileThick);

      // جورجيا داخل الدرفة
      if (hasGeorgian) {
        _drawGeorgianGrid(canvas, innerSashGlass);
      }

      // عواكس الزجاج
      _drawGlassReflections(canvas, innerSashGlass);

      // خطوط ومؤشرات الحركة (جرار / مفصلي / قلاب)
      _drawMovementIndicators(canvas, sashRect, i, count);

      // مقبض الفتح (Handle)
      _drawHandle(canvas, sashRect, i, count);
    }
  }

  void _drawGeorgianGrid(Canvas canvas, Rect r) {
    if (r.width < 15 || r.height < 15) return;
    final geoPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.85) // جورجيا ذهبي
      ..strokeWidth = 1.0;

    // خطوط طولية وعرضية مقسمة لـ 4 أرباع
    final double midX = r.center.dx;
    final double midY = r.center.dy;
    canvas.drawLine(Offset(r.left + 2, midY), Offset(r.right - 2, midY), geoPaint);
    canvas.drawLine(Offset(midX, r.top + 2), Offset(midX, r.bottom - 2), geoPaint);
  }

  void _drawGlassReflections(Canvas canvas, Rect r) {
    if (r.width < 20 || r.height < 20) return;
    final refPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.2;

    final double step = math.min(r.width, r.height) * 0.35;
    canvas.drawLine(
      Offset(r.left + 5, r.top + step),
      Offset(r.left + step, r.top + 5),
      refPaint,
    );
    canvas.drawLine(
      Offset(r.left + 12, r.top + step + 6),
      Offset(r.left + step + 6, r.top + 12),
      refPaint,
    );
  }

  void _drawMovementIndicators(Canvas canvas, Rect sashRect, int index, int totalCount) {
    final motionPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (openType.contains('مفصلي') || openType.contains('قلاب')) {
      // مثلث المفصلي الكروكي المعتمد دولياً في الرسومات المعمارية
      final Path path = Path();
      if (openDirection.contains('شمال')) {
        // مفصلات على اليسار والمقبض يمين
        path.moveTo(sashRect.left + 2, sashRect.top + 2);
        path.lineTo(sashRect.right - 2, sashRect.center.dy);
        path.lineTo(sashRect.left + 2, sashRect.bottom - 2);
      } else {
        // مفصلات على اليمين والمقبض يسار
        path.moveTo(sashRect.right - 2, sashRect.top + 2);
        path.lineTo(sashRect.left + 2, sashRect.center.dy);
        path.lineTo(sashRect.right - 2, sashRect.bottom - 2);
      }
      canvas.drawPath(path, motionPaint);
    } else if (openType.contains('جرار')) {
      // سهم حركة الجرار الأفقي
      final double arrowY = sashRect.center.dy;
      final double arrowLen = math.min(16.0, sashRect.width * 0.4);
      final double dir = (index % 2 == 0) ? 1.0 : -1.0;
      final double cx = sashRect.center.dx;

      canvas.drawLine(
        Offset(cx - (arrowLen / 2 * dir), arrowY),
        Offset(cx + (arrowLen / 2 * dir), arrowY),
        motionPaint,
      );
      // رأس السهم
      canvas.drawLine(
        Offset(cx + (arrowLen / 2 * dir), arrowY),
        Offset(cx + ((arrowLen / 2 - 4) * dir), arrowY - 3),
        motionPaint,
      );
      canvas.drawLine(
        Offset(cx + (arrowLen / 2 * dir), arrowY),
        Offset(cx + ((arrowLen / 2 - 4) * dir), arrowY + 3),
        motionPaint,
      );
    }
  }

  void _drawHandle(Canvas canvas, Rect sashRect, int index, int totalCount) {
    final handlePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    final double hH = math.min(18.0, sashRect.height * 0.15);
    final double hW = 3.5;
    double hX;

    if (openType.contains('مفصلي')) {
      hX = openDirection.contains('شمال') ? sashRect.right - 7 : sashRect.left + 5;
    } else {
      hX = (index % 2 == 0) ? sashRect.right - 7 : sashRect.left + 5;
    }

    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(hX, sashRect.center.dy), width: hW, height: hH),
      const Radius.circular(2),
    );
    canvas.drawRRect(handleRect, handlePaint);
  }

  void _drawExhaustFan(
    Canvas canvas,
    Rect innerRect,
    double topFixedH,
    double midX,
    double midY,
    double midW,
    double midH,
    double scaleX,
    double scaleY,
  ) {
    Offset fanCenter;
    double fanSize = math.min(32.0, (exhaustFanDiameterCm * scaleX) * 0.8);

    if (hasTopFixed && exhaustFanPosition.contains('الثابت')) {
      fanCenter = Offset(innerRect.center.dx, innerRect.top + (topFixedH / 2));
      fanSize = math.min(fanSize, topFixedH * 0.8);
    } else if (exhaustFanPosition.contains('شمال')) {
      fanCenter = Offset(midX + (midW * 0.25), midY + (midH * 0.35));
    } else {
      fanCenter = Offset(midX + (midW * 0.75), midY + (midH * 0.35));
    }

    final fanBasePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final fanBorderPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (exhaustFanShape == 'مربع') {
      final Rect fanRect = Rect.fromCenter(center: fanCenter, width: fanSize, height: fanSize);
      canvas.drawRect(fanRect, fanBasePaint);
      canvas.drawRect(fanRect, fanBorderPaint);
      // ريش الشفاط
      final bladePaint = Paint()
        ..color = const Color(0xFFFCA5A5)
        ..strokeWidth = 1.0;
      canvas.drawLine(fanRect.topLeft, fanRect.bottomRight, bladePaint);
      canvas.drawLine(fanRect.topRight, fanRect.bottomLeft, bladePaint);
    } else {
      // دائري
      final double radius = fanSize / 2;
      canvas.drawCircle(fanCenter, radius, fanBasePaint);
      canvas.drawCircle(fanCenter, radius, fanBorderPaint);

      // ريش الشفاط الدائرية
      final bladePaint = Paint()
        ..color = const Color(0xFFFCA5A5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(fanCenter, radius * 0.35, bladePaint);
      for (int a = 0; a < 4; a++) {
        final double rad = (a * 45) * (math.pi / 180);
        canvas.drawLine(
          fanCenter.translate(math.cos(rad) * radius * 0.35, math.sin(rad) * radius * 0.35),
          fanCenter.translate(math.cos(rad) * radius * 0.9, math.sin(rad) * radius * 0.9),
          bladePaint,
        );
      }
    }
  }

  void _drawDimensionLines(Canvas canvas, Rect frameRect, double drawW, double drawH, double startX, double startY) {
    final dimPaint = Paint()
      ..color = const Color(0xFF38BDF8) // خط الأبعاد السماوي
      ..strokeWidth = 1.0;

    // خط البعد العرضي (أعلى الفتحة)
    final double dimY = frameRect.top - 10;
    canvas.drawLine(Offset(frameRect.left, dimY), Offset(frameRect.right, dimY), dimPaint);
    canvas.drawLine(Offset(frameRect.left, dimY - 4), Offset(frameRect.left, dimY + 4), dimPaint);
    canvas.drawLine(Offset(frameRect.right, dimY - 4), Offset(frameRect.right, dimY + 4), dimPaint);

    // خط البعد الطولي (يسار الفتحة)
    final double dimX = frameRect.left - 10;
    canvas.drawLine(Offset(dimX, frameRect.top), Offset(dimX, frameRect.bottom), dimPaint);
    canvas.drawLine(Offset(dimX - 4, frameRect.top), Offset(dimX + 4, frameRect.top), dimPaint);
    canvas.drawLine(Offset(dimX - 4, frameRect.bottom), Offset(dimX + 4, frameRect.bottom), dimPaint);
  }

  @override
  bool shouldRepaint(covariant ArchitecturalWindowPainter oldDelegate) {
    return oldDelegate.widthCm != widthCm ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.sashCount != sashCount ||
        oldDelegate.openType != openType ||
        oldDelegate.barType != barType ||
        oldDelegate.hasTopFixed != hasTopFixed ||
        oldDelegate.hasBottomFixed != hasBottomFixed ||
        oldDelegate.hasRightFixed != hasRightFixed ||
        oldDelegate.hasLeftFixed != hasLeftFixed ||
        oldDelegate.hasExhaustFan != hasExhaustFan ||
        oldDelegate.hasGlass != hasGlass ||
        oldDelegate.isDoubleGlass != isDoubleGlass ||
        oldDelegate.hasGeorgian != hasGeorgian;
  }
}
