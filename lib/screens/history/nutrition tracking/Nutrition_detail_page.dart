import 'package:flutter/material.dart';

class NutritionDetailPage extends StatelessWidget {
  final Map<String, dynamic> plan;

  const NutritionDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Details"),
        backgroundColor: colors.primary, // 👈 themed
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildPlanView(context, plan),
      ),
    );
  }

  Widget _buildMealCard(
      BuildContext context, String title, Map<String, dynamic> meal, Color color, IconData icon) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              meal["title"] ?? "No name",
              style: textTheme.titleMedium,
            ),
            if (meal["description"] != null) ...[
              const SizedBox(height: 4),
              Text(
                meal["description"],
                style: textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              "Calories: ${meal["calories"] ?? '-'} kcal\n"
              "Protein: ${meal["protein"] ?? '-'} g | "
              "Carbs: ${meal["carbs"] ?? '-'} g | "
              "Fat: ${meal["fat"] ?? '-'} g",
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView(BuildContext context, Map<String, dynamic> plan) {
    final meals = plan["plan"] as Map<String, dynamic>? ?? {};
    final totals = plan["totals"] as Map<String, dynamic>? ?? {};
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMealCard(
            context, "Breakfast", meals["breakfast"] ?? {}, Colors.orange, Icons.free_breakfast),
        _buildMealCard(
            context, "Lunch", meals["lunch"] ?? {}, Colors.green, Icons.lunch_dining),
        _buildMealCard(
            context, "Dinner", meals["dinner"] ?? {}, Colors.blue, Icons.dinner_dining),
        _buildMealCard(
            context, "Snacks", meals["snacks"] ?? {}, Colors.purple, Icons.fastfood),
        const SizedBox(height: 20),
        Card(
          color: colors.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Daily Totals",
                    style: textTheme.titleMedium?.copyWith(color: colors.primary)),
                const SizedBox(height: 8),
                Text(
                  "Calories: ${totals["calories"] ?? '-'} kcal\n"
                  "Protein: ${totals["protein"] ?? '-'} g | "
                  "Carbs: ${totals["carbs"] ?? '-'} g | "
                  "Fat: ${totals["fat"] ?? '-'} g",
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
