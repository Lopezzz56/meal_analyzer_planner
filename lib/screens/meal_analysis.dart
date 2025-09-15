import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meal_analyzer_planner/services/db_service.dart';
import '../services/gemini_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController; // Controller for device camera
  bool _isLoading = false; // Indicates loading state for analysis or camera
  String? _error; // Error message to display if any
  Map<String, dynamic>? _analysisResult; // Parsed analysis result
  File? _selectedImage; // Image selected from camera/gallery
  bool _isCameraMode = true; // Toggle between camera and gallery mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize camera immediately if camera mode is enabled
    if (_isCameraMode) _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  /// Handles app lifecycle to pause/resume camera appropriately
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed && _isCameraMode) {
      _initCamera();
    }
  }

  /// Initialize device camera and handle permissions
  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    // Handle denied permissions
    if (cameraStatus.isDenied || micStatus.isDenied) {
      _showError("Camera or microphone access denied.");
      return;
    }

    // Handle permanently denied permissions
    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      _showError(
        "Camera or microphone permission permanently denied. Please enable it in settings.",
      );
      await openAppSettings();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError("No camera found on this device");
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      _showError("Camera error: $e");
    }
  }

  /// Dispose camera controller safely
  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  /// Capture photo from camera
  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError("Camera not ready");
      return;
    }

    try {
      final file = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = File(file.path);
        _isCameraMode = false;
      });

      await _disposeCamera();
      await _analyzeImage(_selectedImage!);
    } catch (e) {
      _showError("Failed to capture photo: $e");
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery(BuildContext context) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected.")),
      );
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _isCameraMode = false;
      _error = null;
      _analysisResult = null;
    });

    // Run analysis immediately after selecting image
    await _analyzeImage(_selectedImage!);
  }

  /// Analyze selected image using Gemini service
  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      final result = await GeminiService().analyzeMeal(image);
      setState(() => _analysisResult = result);

      // Extract meal name
      String text = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      text = text.trim().replaceAll(RegExp(r"^```json|```$"), "");

      final mealMatch = RegExp(r"\*\*Meal Name:\*\*\s*(.+)").firstMatch(text);
      String mealName = mealMatch?.group(1)?.trim() ?? "Unknown Meal";

print("🔎 Raw Gemini text: $result");
print("🔎 Raw Gemini text: $text");
print("🍽 Extracted mealName: $mealName");
      if (mealName.isNotEmpty && !mealName.toLowerCase().contains('unknown')) {
        await DBService().insertMealAnalysis(image.path, {
          'analysis': text,
          'meal': mealName,
          'raw': result,
        });
      } else {
        _showError("Meal not recognized, not saved.");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show error message in snackbar
  void _showError(String message) {
    setState(() => _error = message);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $message")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Centralized theme access

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // =========================
            // Camera Preview or Selected Image
            // =========================
            Positioned.fill(
              child: _isCameraMode &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : (_selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Container(color: theme.colorScheme.background)),
            ),

            // =========================
            // Loading Overlay
            // =========================
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: theme.colorScheme.secondary,
                ),
              ),

            // =========================
            // Analysis Result Panel
            // =========================
            if (_analysisResult != null && !_isCameraMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _buildResultView(theme),
                ),
              ),

            // =========================
            // Bottom Controls (Camera / Gallery)
            // =========================
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera Button
                  GestureDetector(
                    onTap: _isCameraMode
                        ? _takePhoto
                        : () async {
                            setState(() {
                              _isCameraMode = true;
                              _error = null;
                              _analysisResult = null;
                              _selectedImage = null;
                            });
                            await _initCamera();
                          },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isCameraMode ? Icons.camera : Icons.camera_alt,
                        size: 32,
                        color: theme.iconTheme.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Gallery Button
                  GestureDetector(
                    onTap: () => _pickFromGallery(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the result panel view dynamically based on Gemini analysis
  Widget _buildResultView(ThemeData theme) {
    if (_analysisResult == null) return const SizedBox();

    final text = _analysisResult.toString();

    // === Extract Meal Name ===
    final mealName =
        RegExp(r"\*\*Meal Name:\*\* (.+)").firstMatch(text)?.group(1) ?? "Unknown Meal";

    // === Extract Description ===
    final description =
        RegExp(r"\*\*Description:\*\*([\s\S]+?)\*\*Nutrition")
            .firstMatch(text)
            ?.group(1)
            ?.trim()
            .replaceAll(RegExp(r"\*\*"), "")
            .replaceAll(RegExp(r"\* "), "")
            .trim() ?? "";

    // === Extract Nutrition Key Metrics ===
    final allowedNutrients = ["calories", "protein", "carbohydrates", "fat", "fiber"];
    final nutritionMatches = RegExp(r"\*\*(.+?):\*\* ([^\n]+)")
        .allMatches(text)
        .map((m) => MapEntry(m.group(1)!.trim(), m.group(2)!.trim()))
        .where((entry) => allowedNutrients.contains(entry.key.toLowerCase()))
        .toList();

    // === Extract Ingredients ===
    final ingredientsSection =
        RegExp(r"\*\*Ingredients.*\*\*([\s\S]+)").firstMatch(text)?.group(1) ?? "";
    final ingredients = ingredientsSection
        .split("\n")
        .where((line) => line.trim().startsWith("*"))
        .map((line) => line.replaceAll("*", "").replaceAll(RegExp(r"\*\*"), "").trim())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Name Header
          Text(
            mealName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),

          // Highlight Calories
          if (nutritionMatches.any((e) => e.key.toLowerCase() == "calories"))
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "🔥 Calories: ${nutritionMatches.firstWhere((e) => e.key.toLowerCase() == "calories").value}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Nutrition Grid
          if (nutritionMatches.length > 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nutrition Breakdown",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
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
                      .map(
                        (e) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getNutrientIcon(e.key),
                                      size: 28,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      e.key,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  e.value,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Description Section
          if (description.isNotEmpty) ...[
            Text(
              "Description",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 20),
          ],

          // Ingredients Section
          if (ingredients.isNotEmpty) ...[
            Text(
              "Ingredients",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            ...ingredients.map(
              (ing) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Text(ing, style: theme.textTheme.bodyMedium),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Return icons for nutrients
  IconData _getNutrientIcon(String key) {
    switch (key.toLowerCase()) {
      case "protein":
        return Icons.fitness_center;
      case "carbohydrates":
        return Icons.bakery_dining;
      case "fat":
        return Icons.opacity;
      case "fiber":
        return Icons.eco;
      default:
        return Icons.circle;
    }
  }
}
