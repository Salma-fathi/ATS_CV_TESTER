import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ controllers/result_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/language_provider.dart';
import '../models/analysis_result.dart';

class AnalysisScreen extends StatefulWidget {
  final String cvId;

  const AnalysisScreen({super.key, required this.cvId});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Load result when screen initializes if ID is provided
    if (widget.cvId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ResultController>().loadResult(widget.cvId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResultController>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appLocalizations = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;

    // If result is loaded and has content, update language based on result content
    if (controller.result != null && !controller.isLoading) {
      // Use the language from the result to update the app language
      if (controller.result!.isArabic && !languageProvider.isArabic) {
        // Only update if there's a mismatch to avoid infinite rebuilds
        Future.microtask(() => 
          languageProvider.setLocale(const Locale('ar', '')));
      } else if (!controller.result!.isArabic && languageProvider.isArabic) {
        Future.microtask(() => 
          languageProvider.setLocale(const Locale('en', '')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.analysisResults),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.cvId.isNotEmpty 
                ? () => controller.loadResult(widget.cvId)
                : null,
            tooltip: appLocalizations.retry,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: controller.result != null 
                ? () => _exportResults(controller)
                : null,
            tooltip: appLocalizations.export,
          ),
        ],
      ),
      body: _buildContent(controller, isDesktop, appLocalizations, languageProvider),
    );
  }

  Widget _buildContent(ResultController controller, bool isDesktop, AppLocalizations appLocalizations, LanguageProvider languageProvider) {
    if (controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(appLocalizations.loadingResults),
          ],
        ),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(controller.error!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.cvId.isNotEmpty 
                  ? () => controller.loadResult(widget.cvId)
                  : null,
              child: Text(appLocalizations.retry),
            )
          ],
        ),
      );
    }

    if (controller.result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.grey, size: 50),
            const SizedBox(height: 20),
            Text(appLocalizations.noResultsFound),
            const SizedBox(height: 10),
            Text(
              appLocalizations.uploadToSeeResults,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildAnalysisReport(controller.result!, isDesktop, appLocalizations, languageProvider);
  }

  Widget _buildAnalysisReport(AnalysisResult result, bool isDesktop, AppLocalizations appLocalizations, LanguageProvider languageProvider) {
    final isRtl = result.isRtl || languageProvider.isArabic;
    
    if (isDesktop) {
      // Desktop layout - two column
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - 40% width
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreCard(result.score.toDouble(), appLocalizations),
                  const SizedBox(height: 20),
                  _buildSection(appLocalizations.summary, result.summary, isRtl),
                  const SizedBox(height: 20),
                  _buildKeywordSection(result.keywords, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  _buildDateSection(result.analysisDate, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  if (result.searchabilityIssues.isNotEmpty)
                    _buildSearchabilityIssues(result.searchabilityIssues, appLocalizations, isRtl),
                ],
              ),
            ),
          ),
          // Right column - 60% width
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.jobDescription.isNotEmpty)
                    _buildJobDescription(result.jobDescription, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  _buildSkillsComparison(result.skillsComparison, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  if (result.educationComparison.isNotEmpty)
                    _buildEducationComparison(result.educationComparison, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  if (result.experienceComparison.isNotEmpty)
                    _buildExperienceComparison(result.experienceComparison, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  if (result.recommendations.isNotEmpty)
                    _buildRecommendations(result.recommendations, appLocalizations, isRtl),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile layout - single column
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScoreCard(result.score.toDouble(), appLocalizations),
          const SizedBox(height: 20),
          _buildSection(appLocalizations.summary, result.summary, isRtl),
          const SizedBox(height: 20),
          _buildKeywordSection(result.keywords, appLocalizations, isRtl),
          const SizedBox(height: 20),
          _buildDateSection(result.analysisDate, appLocalizations, isRtl),
          const SizedBox(height: 20),
          if (result.jobDescription.isNotEmpty) ...[
            _buildJobDescription(result.jobDescription, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          _buildSkillsComparison(result.skillsComparison, appLocalizations, isRtl),
          const SizedBox(height: 20),
          if (result.educationComparison.isNotEmpty) ...[
            _buildEducationComparison(result.educationComparison, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.experienceComparison.isNotEmpty) ...[
            _buildExperienceComparison(result.experienceComparison, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.recommendations.isNotEmpty) ...[
            _buildRecommendations(result.recommendations, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.searchabilityIssues.isNotEmpty)
            _buildSearchabilityIssues(result.searchabilityIssues, appLocalizations, isRtl),
        ],
      );
    }
  }

  Widget _buildDateSection(DateTime date, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.version,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDescription(String jobDescription, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.jobDescription,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              jobDescription,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsComparison(Map<String, dynamic> skillsComparison, AppLocalizations appLocalizations, bool isRtl) {
    // Extract data safely with null checks
    final matchingSkills = _extractListSafely(skillsComparison, 'matching_keywords');
    final missingSkills = _extractListSafely(skillsComparison, 'missing_keywords');
    final matchPercentage = skillsComparison['match_percentage'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.skillsComparison,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            
            // Match percentage indicator
            LinearProgressIndicator(
              value: matchPercentage / 100,
              backgroundColor: Colors.grey[200],
              color: _getMatchColor(matchPercentage),
              minHeight: 10,
            ),
            const SizedBox(height: 5),
            Text(
              '${appLocalizations.match}: ${matchPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 15),
            
            // Matching skills
            Text(
              '${appLocalizations.matchingSkills}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 5),
            if (matchingSkills.isEmpty)
              Text(
                appLocalizations.noMatchingSkills,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: matchingSkills
                    .map((skill) => Chip(
                          label: Text(
                            skill,
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          backgroundColor: Colors.green[100],
                          avatar: const Icon(Icons.check, color: Colors.green, size: 16),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 15),
            
            // Missing skills
            Text(
              '${appLocalizations.missingSkills}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 5),
            if (missingSkills.isEmpty)
              Text(
                appLocalizations.greatMatch,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: missingSkills
                    .map((skill) => Chip(
                          label: Text(
                            skill,
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          backgroundColor: Colors.red[50],
                          avatar: const Icon(Icons.close, color: Colors.red, size: 16),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationComparison(List<String> education, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.educationComparison,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: education.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blue),
                      Expanded(
                        child: Text(
                          education[index],
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceComparison(List<String> experience, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.experienceComparison,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: experience.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blue),
                      Expanded(
                        child: Text(
                          experience[index],
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.recommendations,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blue),
                      Expanded(
                        child: Text(
                          recommendations[index],
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchabilityIssues(List<String> issues, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search_off, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.searchabilityIssues,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            if (issues.isEmpty)
              Text(
                appLocalizations.noIssuesFound,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issues[index],
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordSection(List<String> keywords, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.keySkills,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: keywords
                  .map((keyword) => Chip(
                        label: Text(
                          keyword,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                        backgroundColor: Colors.blue[50],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score, AppLocalizations appLocalizations) {
    return Card(
      elevation: 4,
      color: _getScoreColor(score),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.atsCompatibilityScore, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${score.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              _getScoreDescription(score, appLocalizations),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Colors.blue),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                )),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              content,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green[100]!;
    if (score >= 60) return Colors.yellow[100]!;
    return Colors.red[100]!;
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score, AppLocalizations appLocalizations) {
    if (score >= 80) return appLocalizations.excellent;
    if (score >= 60) return appLocalizations.good;
    return appLocalizations.needsImprovement;
  }

  // Helper method to safely extract lists from the map
  List<String> _extractListSafely(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return [];
    
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    } else if (value is String) {
      // If it's a single string, return as a one-item list
      return [value];
    }
    
    return [];
  }

  // Export results method
  Future<void> _exportResults(ResultController controller) async {
    try {
      final exportData = await controller.exportResults();
      if (exportData != null) {
        // In a real app, this would save to a file or share
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export results: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}