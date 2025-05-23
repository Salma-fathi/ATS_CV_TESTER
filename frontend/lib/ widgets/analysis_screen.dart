import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import '../ controllers/result_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/analysis_result.dart';
import '../utils/language_provider.dart/language_provider.dart';

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
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildScoreCard(result, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  _buildSection(appLocalizations.summary, result.summary, isRtl),
                  const SizedBox(height: 20),
                  _buildKeywordSection(result.keywords, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  _buildDateSection(result.analysisDate, appLocalizations, isRtl),
                  const SizedBox(height: 20),
                  if (result.hasSearchabilityIssues)
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
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (result.hasJobDescription) ...[
                    _buildJobDescription(result.jobDescription, appLocalizations, isRtl),
                    const SizedBox(height: 20),
                  ],
                  if (result.hasSkillsComparison) ...[
                    _buildSkillsComparison(result, appLocalizations, isRtl),
                    const SizedBox(height: 20),
                  ],
                  if (result.hasEducationComparison) ...[
                    _buildEducationComparison(result.educationComparison, appLocalizations, isRtl),
                    const SizedBox(height: 20),
                  ],
                  if (result.hasExperienceComparison) ...[
                    _buildExperienceComparison(result.experienceComparison, appLocalizations, isRtl),
                    const SizedBox(height: 20),
                  ],
                  if (result.hasRecommendations)
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
          _buildScoreCard(result, appLocalizations, isRtl),
          const SizedBox(height: 20),
          _buildSection(appLocalizations.summary, result.summary, isRtl),
          const SizedBox(height: 20),
          _buildKeywordSection(result.keywords, appLocalizations, isRtl),
          const SizedBox(height: 20),
          _buildDateSection(result.analysisDate, appLocalizations, isRtl),
          const SizedBox(height: 20),
          if (result.hasJobDescription) ...[
            _buildJobDescription(result.jobDescription, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.hasSkillsComparison) ...[
            _buildSkillsComparison(result, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.hasEducationComparison) ...[
            _buildEducationComparison(result.educationComparison, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.hasExperienceComparison) ...[
            _buildExperienceComparison(result.experienceComparison, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.hasRecommendations) ...[
            _buildRecommendations(result.recommendations, appLocalizations, isRtl),
            const SizedBox(height: 20),
          ],
          if (result.hasSearchabilityIssues)
            _buildSearchabilityIssues(result.searchabilityIssues, appLocalizations, isRtl),
        ],
      );
    }
  }

  Widget _buildDateSection(DateTime date, AppLocalizations appLocalizations, bool isRtl) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
              formattedDate,
              // Use TextDirection directly as an enum value
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsComparison(AnalysisResult result, AppLocalizations appLocalizations, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
              value: result.matchPercentage / 100,
              backgroundColor: Colors.grey[200],
              color: _getMatchColor(result.matchPercentage),
              minHeight: 10,
            ),
            const SizedBox(height: 5),
            Text(
              '${appLocalizations.match}: ${result.matchPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 15),
            
            // Matching skills
            Text(
              '${appLocalizations.matchingSkills}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 5),
            if (result.matchingKeywords.isEmpty)
              Text(
                appLocalizations.noMatchingSkills,
                // Use TextDirection directly as an enum value
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                // Use TextDirection directly as an enum value
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: result.matchingKeywords
                    .map((skill) => Chip(
                          label: Text(
                            skill,
                            // Use TextDirection directly as an enum value
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
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 5),
            if (result.missingKeywords.isEmpty)
              Text(
                appLocalizations.greatMatch,
                // Use TextDirection directly as an enum value
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                // Use TextDirection directly as an enum value
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: result.missingKeywords
                    .map((skill) => Chip(
                          label: Text(
                            skill,
                            // Use TextDirection directly as an enum value
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                    // Use TextDirection directly as an enum value
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          education[index],
                          // Use TextDirection directly as an enum value
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                    // Use TextDirection directly as an enum value
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          experience[index],
                          // Use TextDirection directly as an enum value
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                    // Use TextDirection directly as an enum value
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendations[index],
                          // Use TextDirection directly as an enum value
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
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
                // Use TextDirection directly as an enum value
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
                      // Use TextDirection directly as an enum value
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issues[index],
                            // Use TextDirection directly as an enum value
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

  Widget _buildSection(String title, String content, bool isRtl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              content,
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
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
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.keySkills,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const Divider(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: keywords
                  .map((keyword) => Chip(
                        label: Text(
                          keyword,
                          // Use TextDirection directly as an enum value
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

  Widget _buildScoreCard(AnalysisResult result, AppLocalizations appLocalizations, bool isRtl) {
    final score = result.score;
    final scoreColor = result.getScoreColor();
    final scoreRating = result.getScoreRating(appLocalizations);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.atsCompatibilityScore,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // Use TextDirection directly as an enum value
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[200],
                      color: scoreColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        scoreRating,
                        style: TextStyle(
                          fontSize: 16,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (result.scoreBreakdown != null && result.scoreBreakdown!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                // Use a default string if scoreBreakdown is not defined in AppLocalizations
                appLocalizations.scoreBreakdown ?? 'Score Breakdown',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                // Use TextDirection directly as an enum value
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 10),
              ...result.scoreBreakdown!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Row(
                    // Use TextDirection directly as an enum value
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        // Use TextDirection directly as an enum value
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      Text(
                        '${entry.value is int ? entry.value : (entry.value is double ? (entry.value as double).toStringAsFixed(1) : entry.value.toString())}',
                        // Use TextDirection directly as an enum value
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _exportResults(ResultController controller) async {
    // This would be implemented to export the results to a file
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Use a default string if exportSuccess is not defined in AppLocalizations
        content: Text(AppLocalizations.of(context).export),
        backgroundColor: Colors.green,
      ),
    );
  }
}