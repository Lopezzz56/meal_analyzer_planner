import 'dart:io';
import 'package:flutter/material.dart';

class MealDetailPage extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealDetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // === Extract Text from Gemini Analysis ===
final resultData = meal['result'] ?? {};
final text = resultData['analysis'] ?? "";

    // Meal Name
    final mealName = RegExp(r"\*\*Meal Name:\*\*\s*(.+)")
            .firstMatch(text)
            ?.group(1) ??
        "Unknown Meal";

    // Description
    final description = RegExp(r"\*\*Description:\*\*([\s\S]+?)\*\*Nutrition")
            .firstMatch(text)
            ?.group(1)
            ?.trim()
            .replaceAll(RegExp(r"\*\*"), "") ??
        "";

    // ✅ Nutrition Regex fix: allow optional "* " before label
    final allowedNutrients = ["calories", "protein", "carbohydrates", "fat", "fiber"];
    final nutritionMatches = RegExp(r"\*?\s*\*\*(.+?):\*\*\s*([^\n]+)")
        .allMatches(text)
        .map((m) => MapEntry(m.group(1)!.trim(), m.group(2)!.trim()))
        .where((entry) => allowedNutrients.contains(entry.key.toLowerCase()))
        .toList();

    // Ingredients
    final ingredientsSection =
        RegExp(r"\*\*Ingredients.*\*\*([\s\S]+)").firstMatch(text)?.group(1) ?? "";
    final ingredients = ingredientsSection
        .split("\n")
        .where((line) => line.trim().startsWith("*"))
        .map((line) => line.replaceAll("*", "").trim())
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(mealName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal['imagePath'] != null && File(meal['imagePath']).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(meal['imagePath']),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Meal Name
            Text(mealName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            // Calories Highlight
            if (nutritionMatches.any((e) => e.key.toLowerCase() == "calories"))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "🔥 Calories: ${nutritionMatches.firstWhere((e) => e.key.toLowerCase() == "calories").value}",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Nutrition Breakdown
            if (nutritionMatches.length > 1) ...[
              Text("Nutrition Breakdown",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: nutritionMatches
                    .where((e) => e.key.toLowerCase() != "calories")
                    .map((e) => _nutCard(theme, e.key, e.value))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Description
            if (description.isNotEmpty) ...[
              Text("Description",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 20),
            ],

            // Ingredients
            if (ingredients.isNotEmpty) ...[
              Text("Ingredients",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...ingredients.map(
                (ing) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Text(ing, style: theme.textTheme.bodyMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

 Widget _nutCard(ThemeData theme, String label, String value) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall,
            maxLines: 3, // Limit to 3 lines
            overflow: TextOverflow.ellipsis, // Show "..." if it overflows
          ),
        ],
      ),
    ),
  );
}

}
