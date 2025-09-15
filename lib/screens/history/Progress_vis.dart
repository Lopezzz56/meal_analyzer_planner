import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../services/db_service.dart';
import 'package:intl/intl.dart';

class ProgressVisualisation extends StatefulWidget {
  const ProgressVisualisation({super.key});

  @override
  State<ProgressVisualisation> createState() => _ProgressVisualisationState();
}

class _ProgressVisualisationState extends State<ProgressVisualisation> {
  List<DailyNutrition> nutritionData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

Future<void> _loadNutritionData() async {
  final meals = await DBService().getMealAnalyses();
  final plans = await DBService().getNutritionPlans();

  // Use DateTime as key instead of String
  final Map<DateTime, DailyNutrition> dailyTotals = {};

  void processEntry(Map<String, dynamic> entry, {required bool isPlan}) {
    final result = entry['result'] ?? {};
    final totals = isPlan ? result['totals'] ?? {} : result['totals'] ?? {};

    final rawDate = entry['createdAt']?.toString() ?? '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return;

    // normalize to just the day
// final hour = DateTime(parsed.year, parsed.month, parsed.day, parsed.hour);
final dateKey = DateTime(parsed.year, parsed.month, parsed.day);

    final calories = (totals['calories'] ?? 0).toDouble();
    final protein = (totals['protein'] ?? 0).toDouble();
    final carbs   = (totals['carbs'] ?? 0).toDouble();
    final fat     = (totals['fat'] ?? 0).toDouble();

if (!dailyTotals.containsKey(dateKey)) {
  dailyTotals[dateKey] = DailyNutrition(
    date: dateKey,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
} else {
  final existing = dailyTotals[dateKey]!;
  dailyTotals[dateKey] = DailyNutrition(
    date: existing.date,
    calories: existing.calories + calories,
    protein: existing.protein + protein,
    carbs: existing.carbs + carbs,
    fat: existing.fat + fat,
  );
}

  }

  // Process plans and meals
  for (var plan in plans) {
    processEntry(plan, isPlan: true);
  }
  for (var meal in meals) {
    processEntry(meal, isPlan: false);
  }

  final data = dailyTotals.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  setState(() {
    nutritionData = data;
    _isLoading = false;
  });

  // Debug final dataset
  print("📊 nutritionData length: ${nutritionData.length}");
  for (var d in nutritionData) {
    print("  -> ${d.date}: ${d.calories} kcal, P:${d.protein}, C:${d.carbs}, F:${d.fat}");
  }
}


  // Helper: try to extract totals from free-form text
  Map<String, dynamic> _parseTotalsFromText(String text) {
    final lower = text.toLowerCase();

    double? calories = _extractNumberAfterKeywords(lower, ['calories', 'calorie', 'kcal']);
    double? protein  = _extractNumberAfterKeywords(lower, ['protein']);
    double? carbs    = _extractNumberAfterKeywords(lower, ['carbs', 'carbohydrates', 'carb']);
    double? fat      = _extractNumberAfterKeywords(lower, ['fat', 'fats']);

    final map = <String, dynamic>{};
    if (calories != null) map['calories'] = calories;
    if (protein  != null) map['protein']  = protein;
    if (carbs    != null) map['carbs']    = carbs;
    if (fat      != null) map['fat']      = fat;
    return map;
  }

  // find the first numeric token near any of the keywords
  double? _extractNumberAfterKeywords(String lowerText, List<String> keywords) {
    for (var key in keywords) {
      final idx = lowerText.indexOf(key);
      if (idx != -1) {
        // take a snippet after the keyword where numbers are likely to appear
        final start = idx;
        final end = min(lowerText.length, idx + 120);
        final snippet = lowerText.substring(start, end);

        // search for the first number pattern (handles 150, 150.5, 150-200, "1 50" etc.)
        final numMatch = RegExp(r'(\d{1,4}(?:[ \.,\-]\d{1,4})?(?:\.\d+)?)').firstMatch(snippet);
        if (numMatch != null) {
          String raw = numMatch.group(1)!;
          // remove spaces and commas in broken formatting like "1 50" -> "150"
          raw = raw.replaceAll(RegExp(r'[ ,]'), '');
          // if it's a range like "150-200", take the first number
          if (raw.contains('-')) raw = raw.split('-').first;
          // normalize comma decimal
          raw = raw.replaceAll(',', '.');
          final val = double.tryParse(raw);
          if (val != null) return val;
        }
      }
    }
    return null;
  }

  double _toDoubleSafe(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      // attempt to extract number from string
      final m = RegExp(r'(\d{1,4}(?:[ \.,\-]\d{1,4})?(?:\.\d+)?)').firstMatch(v);
      if (m != null) {
        var raw = m.group(1)!.replaceAll(RegExp(r'[ ,]'), '').replaceAll(',', '.');
        final val = double.tryParse(raw);
        if (val != null) return val;
      }
      return 0;
    }
    return 0;
  }

  // Totals across all days
  num get totalCalories => nutritionData.fold(0, (sum, d) => sum + d.calories);
  num get totalProtein  => nutritionData.fold(0, (sum, d) => sum + d.protein);
  num get totalCarbs    => nutritionData.fold(0, (sum, d) => sum + d.carbs);
  num get totalFat      => nutritionData.fold(0, (sum, d) => sum + d.fat);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress Visualisation"),
        backgroundColor: const Color.fromARGB(255, 102, 187, 181),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : nutritionData.isEmpty
              ? const Center(child: Text("No nutrition data available."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTotalsCard(),
                      const SizedBox(height: 24),
                      const Text("Macro Distribution (Last Day)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildPieChart(nutritionData.last),
                      const SizedBox(height: 24),
                      const Text("Calories Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildCaloriesLineChart(),
                      const SizedBox(height: 24),
                      const Text("Macros Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildMacrosLineChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Total Intake", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem("Calories", totalCalories.toStringAsFixed(0)),
                _buildTotalItem("Protein", "${totalProtein.toStringAsFixed(0)} g"),
                _buildTotalItem("Carbs", "${totalCarbs.toStringAsFixed(0)} g"),
                _buildTotalItem("Fat", "${totalFat.toStringAsFixed(0)} g"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildPieChart(DailyNutrition day) {
    final macroData = [
      MacroData('Protein', day.protein),
      MacroData('Carbs', day.carbs),
      MacroData('Fat', day.fat),
    ];
    return SfCircularChart(
      legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
      series: <PieSeries<MacroData, String>>[
        PieSeries<MacroData, String>(
          dataSource: macroData,
          xValueMapper: (d, _) => d.macro,
          yValueMapper: (d, _) => d.value,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

Widget _buildCaloriesLineChart() {
  return SfCartesianChart(
    primaryXAxis: DateTimeAxis(
      intervalType: DateTimeIntervalType.hours, // ⬅️ now hours instead of days
      dateFormat: DateFormat.Hm(), // shows like 10:00, 11:00
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      minimum: nutritionData.isNotEmpty ? nutritionData.first.date : null,
      maximum: nutritionData.isNotEmpty ? nutritionData.last.date : null,
    ),

    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Calories')),
    tooltipBehavior: TooltipBehavior(enable: true),
    series: <CartesianSeries<DailyNutrition, DateTime>>[
      LineSeries<DailyNutrition, DateTime>(
        dataSource: nutritionData,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.calories,
        name: 'Calories',
        color: Colors.red,
        markerSettings: const MarkerSettings(isVisible: true),
      ),
    ],
  );
}


Widget _buildMacrosLineChart() {
  return SfCartesianChart(
    primaryXAxis: DateTimeAxis(
      intervalType: DateTimeIntervalType.days,
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      minimum: nutritionData.isNotEmpty ? nutritionData.first.date : null,
      maximum: nutritionData.isNotEmpty ? nutritionData.last.date : null,
    ),
    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Grams')),
    tooltipBehavior: TooltipBehavior(enable: true),
    legend: Legend(isVisible: true),
    series: <CartesianSeries<DailyNutrition, DateTime>>[
      LineSeries<DailyNutrition, DateTime>(
        dataSource: nutritionData,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.protein,
        name: 'Protein',
        color: Colors.blue,
      ),
      LineSeries<DailyNutrition, DateTime>(
        dataSource: nutritionData,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.carbs,
        name: 'Carbs',
        color: Colors.orange,
      ),
      LineSeries<DailyNutrition, DateTime>(
        dataSource: nutritionData,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.fat,
        name: 'Fat',
        color: Colors.green,
      ),
    ],
  );
}

}

// Models
class DailyNutrition {
  final DateTime date;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  DailyNutrition({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class MacroData {
  final String macro;
  final num value;
  MacroData(this.macro, this.value);
}
