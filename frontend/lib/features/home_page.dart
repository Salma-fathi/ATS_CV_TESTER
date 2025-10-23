import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';

import '../ core/ widgets/analysis_progress.dart';
import '../ core/ widgets/custom_button.dart';
import '../ core/ widgets/drag_drop_area.dart';
import '../ core/ widgets/loading_widget.dart';
import '../ core/ widgets/score_card.dart';
import '../ core/providers/theme_provider.dart';
import '../ core/theme/app_theme.dart';
import '../ services/api_service.dart';
import '../ core/config/app_config.dart';
import '../ core/ widgets/keyword_chip.dart';

// State providers
final selectedFileProvider = StateProvider<PlatformFile?>((ref) => null);
final isAnalyzingProvider = StateProvider<bool>((ref) => false);
final analysisStepProvider =
    StateProvider<AnalysisStep>((ref) => AnalysisStep.uploading);
final analysisProgressProvider = StateProvider<double>((ref) => 0.0);
final analysisResultProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // Used for visual indication of current page

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFileSelected(PlatformFile file) {
    ref.read(selectedFileProvider.notifier).state = file;
  }

  Future<void> _startAnalysis() async {
    final file = ref.read(selectedFileProvider);
    if (file == null) return;

    ref.read(isAnalyzingProvider.notifier).state = true;
    ref.read(analysisProgressProvider.notifier).state = 0.0;
    ref.read(analysisStepProvider.notifier).state = AnalysisStep.uploading;

    // Navigate to analysis page
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    try {
      // Simulate staging progress while performing real API call
      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(analysisStepProvider.notifier).state = AnalysisStep.parsing;
      ref.read(analysisProgressProvider.notifier).state = 0.25;

      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(analysisStepProvider.notifier).state = AnalysisStep.analyzing;
      ref.read(analysisProgressProvider.notifier).state = 0.55;

      final api = ApiService(baseUrl: AppConfig.baseUrl);
      final result = await api.analyzeCV(file);

      ref.read(analysisStepProvider.notifier).state = AnalysisStep.generating;
      ref.read(analysisProgressProvider.notifier).state = 0.85;

      ref.read(analysisResultProvider.notifier).state = result;

      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(analysisStepProvider.notifier).state = AnalysisStep.completed;
      ref.read(analysisProgressProvider.notifier).state = 1.0;

      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      ref.read(isAnalyzingProvider.notifier).state = false;
    }
  }

  void _resetAnalysis() {
    ref.read(selectedFileProvider.notifier).state = null;
    ref.read(isAnalyzingProvider.notifier).state = false;
    ref.read(analysisProgressProvider.notifier).state = 0.0;
    ref.read(analysisStepProvider.notifier).state = AnalysisStep.uploading;
    ref.read(analysisResultProvider.notifier).state = null;

    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFile = ref.watch(selectedFileProvider);
    final isAnalyzing =
        ref.watch(isAnalyzingProvider); // This variable is now used

    return LoadingOverlay(
      isLoading: isAnalyzing, // Using isAnalyzing here
      loadingMessage: _getStepMessage(ref.watch(analysisStepProvider)),
      progress: ref.watch(analysisProgressProvider),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('ATS CV Tester'),
            ],
          ),
          actions: [
            // Theme toggle
            IconButton(
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              icon: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) =>
              setState(() => _currentPage = page), // _currentPage is used here
          children: [
            _buildUploadPage(context, selectedFile),
            _buildAnalysisPage(context),
            _buildResultsPage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPage(BuildContext context, PlatformFile? selectedFile) {
    final isAnalyzing =
        ref.watch(isAnalyzingProvider); // Watch here to disable button
    return ResponsiveRowColumn(
      layout: ResponsiveBreakpoints.of(context).smallerThan(DESKTOP)
          ? ResponsiveRowColumnType.COLUMN
          : ResponsiveRowColumnType.ROW,
      children: [
        ResponsiveRowColumnItem(
          rowFlex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimize Your CV for ATS',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ).animate().fadeIn().slideX(begin: -0.3),

                const SizedBox(height: 16),

                Text(
                  'Get instant feedback on how well your CV performs with Applicant Tracking Systems. Our AI-powered analysis provides detailed insights and actionable recommendations.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                const SizedBox(height: 32),

                // Features
                Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      Icons.speed,
                      'Instant Analysis',
                      'Get results in seconds',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.psychology,
                      'AI-Powered',
                      'Advanced machine learning algorithms',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.security,
                      'Secure & Private',
                      'Your data is protected and never stored',
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
        ResponsiveRowColumnItem(
          rowFlex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DragDropArea(
                  onFileSelected: _onFileSelected,
                  selectedFileName: selectedFile?.name,
                ).animate().fadeIn(delay: 600.ms).scale(),
                const SizedBox(height: 24),
                if (selectedFile != null)
                  CustomButton(
                    text: 'Analyze CV',
                    onPressed: isAnalyzing
                        ? null
                        : _startAnalysis, // Disable button when analyzing
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    icon: Icons.analytics,
                    isFullWidth: true,
                    isLoading: isAnalyzing, // Show loading state on button
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPage(BuildContext context) {
    final currentStep = ref.watch(analysisStepProvider);
    final progress = ref.watch(analysisProgressProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: AnalysisProgress(
          currentStep: currentStep,
          progress: progress,
          currentMessage: _getStepMessage(currentStep),
        ),
      ),
    );
  }

  Widget _buildResultsPage(BuildContext context) {
    final result = ref.watch(analysisResultProvider);

    // Fallbacks if result is null (e.g., user navigated here without running analysis)
    final overallScore = result?['score'] ?? 0;
    final keywordScore = (result?['score_breakdown']?['keyword_score']) ??
        (result?['skills_comparison']?['match_percentage'] ?? 0);
    final formatScore = (result?['score_breakdown']?['format_score']) ?? 0;
    final readabilityScore =
        (result?['score_breakdown']?['readability_score']) ?? 0;
    final summary = result?['summary'] ?? 'No analysis available.';
    final direction =
        result?['direction'] == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

    final matchingKeywords =
        (result?['skills_comparison']?['matching_keywords'] as List?)
                ?.cast<dynamic>()
                .map((e) => e.toString())
                .toList() ??
            <String>[];
    final missingKeywords =
        (result?['skills_comparison']?['missing_keywords'] as List?)
                ?.cast<dynamic>()
                .map((e) => e.toString())
                .toList() ??
            <String>[];
    final recommendations =
        (result?['recommendations'] as List?)?.map((e) => '$e').toList() ??
            <String>[];
    final searchability =
        (result?['searchability_issues'] as List?)?.map((e) => '$e').toList() ??
            <String>[];

    return Directionality(
      textDirection: direction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: 12),

            Text(
              summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 32),

            // Overall score
            OverallScoreCard(
              overallScore: overallScore,
              categoryScores: {
                'Keywords': keywordScore,
                'Format': formatScore,
                'Readability': readabilityScore,
              },
            ).animate().fadeIn(delay: 200.ms).scale(),

            const SizedBox(height: 24),

            // Keyword chips
            if (matchingKeywords.isNotEmpty || missingKeywords.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Keywords',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              if (matchingKeywords.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Matching',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchingKeywords
                      .map((k) => KeywordChip(keyword: k, isMatched: true))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (missingKeywords.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Missing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missingKeywords
                      .map((k) => KeywordChip(keyword: k, isMatched: false))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Recommendations and issues
            if (recommendations.isNotEmpty || searchability.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              ...recommendations.map(
                (r) => ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppTheme.primaryColor),
                  title: Text(r),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (searchability.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Searchability',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                ...searchability.map(
                  (s) => ListTile(
                    leading:
                        const Icon(Icons.info_outline, color: Colors.orange),
                    title: Text(s),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Analyze Another CV',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    icon: Icons.refresh,
                    onPressed: _resetAnalysis,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepMessage(AnalysisStep step) {
    switch (step) {
      case AnalysisStep.uploading:
        return 'Uploading your CV securely...';
      case AnalysisStep.parsing:
        return 'Extracting text and analyzing structure...';
      case AnalysisStep.analyzing:
        return 'Running AI analysis against ATS requirements...';
      case AnalysisStep.generating:
        return 'Generating detailed recommendations...';
      case AnalysisStep.completed:
        return 'Analysis complete! Preparing results...';
    }
  }
}
