import 'dart:io';
import 'package:flutter/material.dart';
import 'package:meal_analyzer_planner/screens/history/meal%20analysis/meal_detail_page.dart';
import '../../../services/db_service.dart';

class MealDetailedHistory extends StatelessWidget {
  const MealDetailedHistory({super.key});

  Widget buildImage(String? path) {
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Detailed Meal History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBService().getMealAnalyses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final meals = snapshot.data ?? [];
          if (meals.isEmpty) {
            return const Center(child: Text("No meal history found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              String mealName = "Unknown Meal";

              // === Extract Text ===
              final analysisRaw = meal['result']?.toString() ?? "";
              final text = analysisRaw;

              // Meal Name
              final match = RegExp(r"\*\*Meal Name:\*\*\s*(.+)").firstMatch(text);
              if (match != null) {
                mealName = match.group(1)?.trim() ?? "Unknown Meal";
              }

              // === Nutrition Preview ===
              final nutritionMatches = RegExp(r"\*?\s*\*\*(.+?):\*\*\s*([^\n]+)")
                  .allMatches(text)
                  .map((m) => MapEntry(m.group(1)!.trim(), m.group(2)!.trim()))
                  .toList();

              // Format createdAt
              String dateStr = "";
              if (meal['createdAt'] != null) {
                final date = DateTime.tryParse(meal['createdAt']);
                if (date != null) {
                  dateStr = "${date.day} ${_monthName(date.month)}, ${date.year}";
                } else {
                  dateStr = meal['createdAt'];
                }
              }

              return Dismissible(
                key: Key(meal['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) async {
                  await DBService().deleteMeal(meal['id']);
                  meals.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Meal deleted")),
                  );
                },
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealDetailPage(meal: meal),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: buildImage(meal['imagePath']),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mealName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateStr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
  
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to convert month number to short name
  String _monthName(int month) {
    const months = [
      '', // placeholder
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
