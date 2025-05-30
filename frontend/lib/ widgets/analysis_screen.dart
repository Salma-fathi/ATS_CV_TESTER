import 'package:flutter/material.dart';
import 'package:frontend/%20widgets/keyword_chip.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../ controllers/cv_controller.dart';
import '../models/analysis_result.dart';
import 'score_indicator.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

// Using TickerProviderStateMixin to support multiple animation controllers
class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _retryCount = 0;
  final int _maxRetries = 3;
  Timer? _retryTimer;
  bool _isRetrying = false;
  
  // Animation controllers for score animations
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs to include Score Breakdown
    
    // Initialize score animation controller
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _retryTimer?.cancel();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  // Retry logic with exponential backoff
  void _retryAnalysis(CvController controller) {
    if (_retryCount >= _maxRetries) {
      // Max retries reached, stop trying
      return;
    }

    setState(() {
      _isRetrying = true;
    });

    // Calculate backoff time (2^retry_count * 1000ms)
    final backoffMs = (1 << _retryCount) * 1000;
    
    _retryTimer = Timer(Duration(milliseconds: backoffMs), () {
      if (mounted) {
        setState(() {
          _retryCount++;
        });
        controller.retryAnalysis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    return Consumer<CvController>(
      builder: (context, controller, child) {
        // Update language based on CV content if result is available
        if (controller.currentResult != null) {
        }
        
        // Determine text direction based on current locale or CV content
        final ui.TextDirection textDirection = controller.currentResult?.isRtl == true 
            ? ui.TextDirection.rtl 
            : Localizations.localeOf(context).languageCode == 'ar' 
                ? ui.TextDirection.rtl 
                : ui.TextDirection.ltr;
        
        return Directionality(
          textDirection: textDirection,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                appLocalizations.analysisResults,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Export button
                IconButton(
                  icon: Icon(Icons.download, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: controller.currentResult != null ? () {
                    // Implement export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.exportSuccess))
                    );
                  } : null,
                  tooltip: appLocalizations.export,
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: _buildContent(controller, appLocalizations),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(CvController controller, AppLocalizations appLocalizations) {
    if (controller.isLoading) {
      return _buildLoadingState(appLocalizations);
    } else if (controller.error != null) {
      return _buildErrorState(controller, appLocalizations);
    } else if (controller.currentResult == null) {
      return _buildNoResultState(appLocalizations);
    } else {
      return _buildResultsView(controller, appLocalizations);
    }
  }

  Widget _buildLoadingState(AppLocalizations appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom loading animation
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            appLocalizations.loadingResults,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CvController controller, AppLocalizations appLocalizations) {
    // Get localized error message
    String errorMessage = controller.getLocalizedError(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Try again button
                ElevatedButton.icon(
                  icon: Icon(_isRetrying ? Icons.cancel : Icons.refresh),
                  label: Text(
                    appLocalizations.retry,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRetrying ? Colors.grey : Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (_isRetrying) {
                      // Cancel retry
                      setState(() {
                        _isRetrying = false;
                        _retryCount = 0;
                      });
                      _retryTimer?.cancel();
                    } else {
                      // Start retry with exponential backoff
                      _retryAnalysis(controller);
                    }
                  },
                ),
                const SizedBox(width: 16),
                // Go back button
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    'Go Back',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultState(AppLocalizations appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 24),
          Text(
            appLocalizations.noResultsFound,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              appLocalizations.uploadToSeeResults,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(
              'Upload CV',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(CvController controller, AppLocalizations appLocalizations) {
    final result = controller.currentResult!;
    
    // Set up score animation if not already done
    if (!_scoreAnimationController.isAnimating && !_scoreAnimationController.isCompleted) {
      _scoreAnimation = Tween<double>(
        begin: 0.0,
        end: result.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutCubic,
      ));
      
      _scoreAnimationController.forward();
    }
    
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: appLocalizations.summary.toUpperCase()),
            Tab(text: appLocalizations.skillsComparison.toUpperCase()),
            Tab(text: appLocalizations.recommendations.toUpperCase()),
            Tab(text: appLocalizations.scoreBreakdown.toUpperCase()),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Summary tab
              _buildSummaryTab(result, appLocalizations),
              
              // Skills Comparison tab
              _buildSkillsComparisonTab(result, appLocalizations),
              
              // Recommendations tab
              _buildRecommendationsTab(result, appLocalizations),
              
              // Score Breakdown tab (new)
              _buildScoreBreakdownTab(result, appLocalizations),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab(AnalysisResult result, AppLocalizations appLocalizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score indicator
          Center(
            child: AnimatedBuilder(
              animation: _scoreAnimationController,
              builder: (context, child) {
                return ScoreIndicator(
                  score: _scoreAnimation.value.round().toDouble(),
                  size: 150,
                  strokeWidth: 12,
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: result.getScoreColor(),
                  ),
                  labelStyle: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  label: result.getScoreRating(appLocalizations),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.summary,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.summary,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Key skills
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.keySkills,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.keywords.map((keyword) {
                      return KeywordChip(
                        keyword: keyword,
                        isMatched: result.matchingKeywords.contains(keyword),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Analysis date
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.version,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(result.analysisDate),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (result.analysisVersion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Version ${result.analysisVersion}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Job description (if available)
          if (result.hasJobDescription) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.jobDescription,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.jobDescription,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Industry information (if available)
          if (result.industry.isNotEmpty && result.industry != 'General') ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Industry',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.industry,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillsComparisonTab(AnalysisResult result, AppLocalizations appLocalizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills match percentage
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.match,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ScoreIndicator(
                      score: result.matchPercentage.round().toDouble(),
                      size: 120,
                      strokeWidth: 10,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getMatchColor(result.matchPercentage),
                      ),
                      labelStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      label: '%',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Matching skills
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.matchingSkills,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  result.matchingKeywords.isNotEmpty
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.matchingKeywords.map((keyword) {
                            return KeywordChip(
                              keyword: keyword,
                              isMatched: true,
                            );
                          }).toList(),
                        )
                      : Text(
                          appLocalizations.noMatchingSkills,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Missing skills
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.missingSkills,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  result.missingKeywords.isNotEmpty
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.missingKeywords.map((keyword) {
                            return KeywordChip(
                              keyword: keyword,
                              isMatched: false,
                            );
                          }).toList(),
                        )
                      : Text(
                          appLocalizations.greatMatch,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.green,
                          ),
                        ),
                ],
              ),
            ),
          ),
          
          // Education comparison (if available)
          if (result.hasEducationComparison) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.educationComparison,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: result.educationComparison.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.educationComparison[index],
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
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
            ),
          ],
          
          // Experience comparison (if available)
          if (result.hasExperienceComparison) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.experienceComparison,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: result.experienceComparison.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.work,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.experienceComparison[index],
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
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
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(AnalysisResult result, AppLocalizations appLocalizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendations
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.recommendations,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  result.hasRecommendations
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: result.recommendations.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      result.recommendations[index],
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Text(
                          'No specific recommendations at this time.',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Searchability issues
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.searchabilityIssues,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  result.hasSearchabilityIssues
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: result.searchabilityIssues.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      result.searchabilityIssues[index],
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Text(
                          appLocalizations.noIssuesFound,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.green,
                          ),
                        ),
                ],
              ),
            ),
          ),
          
          // Missing sections (if available)
          if (result.hasMissingSections) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missing Sections',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: result.missingSections.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.highlight_off,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.missingSections[index],
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
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
            ),
          ],
          
          // Identified sections (if available)
          if (result.hasIdentifiedSections) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identified Sections',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: result.identifiedSections.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.identifiedSections[index],
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
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
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // New tab for score breakdown
  Widget _buildScoreBreakdownTab(AnalysisResult result, AppLocalizations appLocalizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall score
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.atsCompatibilityScore,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ScoreIndicator(
                      score: result.score.toDouble(),
                      size: 120,
                      strokeWidth: 10,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: result.getScoreColor(),
                      ),
                      labelStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      label: result.getScoreRating(appLocalizations),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Component scores
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.scoreBreakdown,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Keyword Match Score
                  _buildScoreBar(
                    'Keyword Match',
                    result.keywordMatchScore,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  
                  // Formatting Score
                  _buildScoreBar(
                    'Formatting',
                    result.formattingScore,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  
                  // Content Score
                  _buildScoreBar(
                    'Content',
                    result.contentScore,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Readability Score
                  _buildScoreBar(
                    'Readability',
                    result.readabilityScore,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          // Detailed score breakdown (if available)
          if (result.scoreBreakdown != null && result.scoreBreakdown!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Breakdown',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...result.scoreBreakdown!.entries.map((entry) {
                      // Skip entries that are already shown as component scores
                      if (['keyword_match', 'formatting', 'content', 'readability']
                          .contains(entry.key.toLowerCase().replaceAll(' ', '_'))) {
                        return SizedBox.shrink();
                      }
                      
                      // Format the key for display
                      final displayKey = entry.key
                          .split('_')
                          .map((word) => word.isNotEmpty 
                              ? word[0].toUpperCase() + word.substring(1) 
                              : '')
                          .join(' ');
                      
                      // Get the score value
                      final scoreValue = entry.value is int 
                          ? entry.value as int 
                          : (entry.value is double 
                              ? (entry.value as double).round() 
                              : 0);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildScoreBar(
                          displayKey,
                          scoreValue,
                          _getRandomColor(entry.key),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$score/100',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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

  // Generate a consistent color based on string input
  Color _getRandomColor(String input) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];
    
    // Simple hash function to get a consistent index
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash + input.codeUnitAt(i)) % colors.length;
    }
    
    return colors[hash];
  }
}

