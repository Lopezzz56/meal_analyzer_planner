import 'package:flutter/material.dart';
import 'package:meal_analyzer_planner/screens/history/nutrition tracking/Nutrition_detail_page.dart';
import 'package:meal_analyzer_planner/services/db_service.dart';


class NutritionSummaryScreen extends StatefulWidget {
  const NutritionSummaryScreen({super.key});

  @override
  State<NutritionSummaryScreen> createState() => _NutritionSummaryScreenState();
}

class _NutritionSummaryScreenState extends State<NutritionSummaryScreen> {
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final plans = await DBService().getNutritionPlans();
    setState(() {
      _meals = plans;
      _isLoading = false;
    });
  }

  Map<String, dynamic> _calculateTotals(List<Map<String, dynamic>> meals) {
    num calories = 0;
    num protein = 0;
    num carbs = 0;
    num fat = 0;

    for (var meal in meals) {
      final result = meal['result'];
      final totals = result['totals'] ?? {};
      calories += totals['calories'] ?? 0;
      protein += totals['protein'] ?? 0;
      carbs += totals['carbs'] ?? 0;
      fat += totals['fat'] ?? 0;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Summary"),
        backgroundColor: colors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? Center(
                  child: Text(
                    "No meal plans yet",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Summaries",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._meals.map((meal) {
                        final totals = meal['result']['totals'] ?? {};
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NutritionDetailPage(plan: meal['result']),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              title: Text(
                                meal['createdAt'].toString().split('T')[0],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Calories: ${totals['calories'] ?? '-'} kcal | "
                                  "Protein: ${totals['protein'] ?? '-'} g | "
                                  "Carbs: ${totals['carbs'] ?? '-'} g | "
                                  "Fat: ${totals['fat'] ?? '-'} g",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      Text(
                        "Weekly Summary",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: colors.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Builder(builder: (_) {
                            final weekTotals = _calculateTotals(_meals);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Calories",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${weekTotals['calories']} kcal",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Macros",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Protein: ${weekTotals['protein']} g | "
                                  "Carbs: ${weekTotals['carbs']} g | "
                                  "Fat: ${weekTotals['fat']} g",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
