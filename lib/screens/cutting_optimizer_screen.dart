import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/workshop_storage.dart';

class CuttingOptimizerScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const CuttingOptimizerScreen({super.key, required this.storage});

  @override
  State<CuttingOptimizerScreen> createState() => _CuttingOptimizerScreenState();
}

class _CuttingOptimizerScreenState extends State<CuttingOptimizerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1D Bar Cutting State
  final _stockBarCtrl = TextEditingController(text: '600');
  final _kerfMmCtrl = TextEditingController(text: '4');
  final _pieceLenCtrl = TextEditingController();
  final _pieceQtyCtrl = TextEditingController(text: '2');
  final List<Map<String, num>> _barRequests = [
    {'length': 180.0, 'qty': 4},
    {'length': 131.8, 'qty': 4},
    {'length': 91.5, 'qty': 4},
  ];

  // 2D Board Cutting State
  final _boardWCtrl = TextEditingController(text: '244');
  final _boardHCtrl = TextEditingController(text: '122');
  final _panelWCtrl = TextEditingController();
  final _panelHCtrl = TextEditingController();
  final _panelQtyCtrl = TextEditingController(text: '2');
  final List<Map<String, num>> _panelRequests = [
    {'w': 72.0, 'h': 58.0, 'qty': 4},
    {'w': 60.0, 'h': 58.0, 'qty': 2},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stockBarCtrl.text = widget
        .storage.pricingSettings.defaultStockBarLengthCm
        .toStringAsFixed(0);
    _kerfMmCtrl.text =
        widget.storage.pricingSettings.defaultSawKerfMm.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final double stockLen = double.tryParse(_stockBarCtrl.text) ?? 600.0;
    final double kerfMm = double.tryParse(_kerfMmCtrl.text) ?? 4.0;

    final List<double> expandedPieces = [];
    for (final req in _barRequests) {
      final double l = (req['length'] ?? 0).toDouble();
      final int q = (req['qty'] ?? 0).toInt();
      for (int i = 0; i < q; i++) {
        expandedPieces.add(l);
      }
    }

    final barPlans = WorkshopStorage.optimize1DBars(
      requiredPiecesCm: expandedPieces,
      stockLengthCm: stockLen,
      sawKerfMm: kerfMm,
    );

    return Column(
      children: [
        Container(
          color: const Color(0xFF1E293B),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: const [
              Tab(
                icon: Icon(Icons.straighten),
                text: 'تقسيم الأعواد (600 سم)',
              ),
              Tab(
                icon: Icon(Icons.grid_view),
                text: 'تقسيم الألواح (الخشب والفايبر)',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. تقسيم الأعواد
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إعدادات العود القياسي وسُمك صينية المنشار:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _stockBarCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'طول العود الافتراضي (سم)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _kerfMmCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'سُمك صينية المنشار (مم)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _pieceLenCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'طول القطعة المطلوبة (سم)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _pieceQtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'العدد',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF15803D),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                  ),
                                  onPressed: () {
                                    final l = double.tryParse(
                                            _pieceLenCtrl.text.trim()) ??
                                        0.0;
                                    final q = int.tryParse(
                                            _pieceQtyCtrl.text.trim()) ??
                                        1;
                                    if (l > 0 && l <= stockLen && q > 0) {
                                      setState(() {
                                        _barRequests
                                            .add({'length': l, 'qty': q});
                                        _pieceLenCtrl.clear();
                                      });
                                    }
                                  },
                                  child: const Text('إضافة'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children:
                                  List.generate(_barRequests.length, (index) {
                                final r = _barRequests[index];
                                return InputChip(
                                  label: Text(
                                      '${r['length']} سم × ${r['qty']} قطعة'),
                                  onDeleted: () => setState(
                                      () => _barRequests.removeAt(index)),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نتيجة تقسيم الأعواد: إجمالي ${barPlans.length} عود (بطول ${stockLen.toStringAsFixed(0)} سم)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...barPlans.map((plan) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'العود رقم #${plan.barNumber}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      'المستخدم: ${plan.usedLengthCm} سم | الفضلة (الهالك): ${plan.wasteLengthCm} سم',
                                      style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'القطع المقصوصة من هذا العود: [ ${plan.cutsCm.map((e) => "${e.toStringAsFixed(1)} سم").join("  +  ")} ]',
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),

              // 2. تقسيم الألواح (الخشب والفايبر والكلادينج)
              _build2DBoardsOptimizer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build2DBoardsOptimizer() {
    final double bW = double.tryParse(_boardWCtrl.text) ?? 244.0;
    final double bH = double.tryParse(_boardHCtrl.text) ?? 122.0;
    final double boardAreaM2 = (bW / 100.0) * (bH / 100.0);

    double totalPanelsAreaM2 = 0.0;
    int totalPanelsCount = 0;
    for (final p in _panelRequests) {
      final double w = (p['w'] ?? 0).toDouble();
      final double h = (p['h'] ?? 0).toDouble();
      final int q = (p['qty'] ?? 0).toInt();
      totalPanelsAreaM2 += ((w / 100.0) * (h / 100.0)) * q;
      totalPanelsCount += q;
    }

    final double rawBoards =
        boardAreaM2 > 0 ? (totalPanelsAreaM2 / (boardAreaM2 * 0.88)) : 0.0;
    final int fullBoardsNeeded = rawBoards.ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مقاس اللوح القياسي (خشب 18 مم: 244×122 سم أو فايبر/كلادينج: 280×130 سم):',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _boardWCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'طول اللوح القياسي (سم)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _boardHCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'عرض اللوح القياسي (سم)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _panelWCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'طول القطعة (سم)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _panelHCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'عرض القطعة (سم)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _panelQtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'العدد',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final w =
                              double.tryParse(_panelWCtrl.text.trim()) ?? 0.0;
                          final h =
                              double.tryParse(_panelHCtrl.text.trim()) ?? 0.0;
                          final q =
                              int.tryParse(_panelQtyCtrl.text.trim()) ?? 1;
                          if (w > 0 && h > 0 && q > 0) {
                            setState(() {
                              _panelRequests.add({'w': w, 'h': h, 'qty': q});
                              _panelWCtrl.clear();
                              _panelHCtrl.clear();
                            });
                          }
                        },
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: List.generate(_panelRequests.length, (idx) {
                      final p = _panelRequests[idx];
                      return InputChip(
                        label: Text(
                            '${p['w']}×${p['h']} سم (العدد: ${p['qty']})'),
                        onDeleted: () =>
                            setState(() => _panelRequests.removeAt(idx)),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF0FDF4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي القطع المضافة: $totalPanelsCount قطعة (إجمالي المساحة الصافية: ${totalPanelsAreaM2.toStringAsFixed(2)} م²)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'عدد الألواح المطلوب شراؤها (بمقاس ${bW.toStringAsFixed(0)}×${bH.toStringAsFixed(0)} سم شاملة نسبة الهالك): $fullBoardsNeeded لوح (${rawBoards.toStringAsFixed(2)} لوح)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
