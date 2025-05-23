import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

import '../ controllers/cv_controller.dart';
import '../ widgets/scoring_system.dart';


class ResultsPage extends StatefulWidget {
  const ResultsPage({Key? key}) : super(key: key);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

// Using TickerProviderStateMixin to support multiple animation controllers
class _ResultsPageState extends State<ResultsPage> with TickerProviderStateMixin {
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
    _tabController = TabController(length: 3, vsync: this);
    
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
    return Consumer<CvController>(
      builder: (context, controller, child) {
        // Update language based on CV content if result is available
        if (controller.currentResult != null) {
          // Fixed syntax error here
          controller.updateLanguageBasedOnContent();
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Analysis Results',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Share button
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.primary),
                onPressed: () {
                  // Implement share functionality
                },
                tooltip: 'Share Results',
              ),
              // Download button
              IconButton(
                icon: const Icon(Icons.download, color: AppColors.primary),
                onPressed: () {
                  // Implement download functionality
                },
                tooltip: 'Download Report',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundDark,
                  AppColors.backgroundDark.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildContent(controller),
          ),
        );
      },
    );
  }

  Widget _buildContent(CvController controller) {
    if (controller.isLoading) {
      return _buildLoadingState();
    } else if (controller.error != null) {
      return _buildErrorState(controller);
    } else if (controller.currentResult == null) {
      return _buildNoResultState();
    } else {
      // Apply realistic scoring system to the results
      return _buildResultsView(controller);
    }
  }

  Widget _buildLoadingState() {
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your CV...',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'We\'re checking your CV against ATS requirements and industry standards.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CvController controller) {
    // Parse the error message to provide more specific guidance
    String errorTitle = 'Oops! Something went wrong';
    String errorMessage = controller.getLocalizedError(context);
    String actionText = 'Try Again';
    IconData errorIcon = Icons.error_outline;
    
    // Customize based on error type
    if (errorMessage.contains('timed out') || errorMessage.contains('taking too long')) {
      errorTitle = 'Server Connection Timeout';
      errorMessage = 'The server is taking too long to respond. This might be due to high traffic or connectivity issues.';
      errorIcon = Icons.timer_off;
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      errorTitle = 'Network Connection Error';
      errorMessage = 'Please check your internet connection and try again.';
      errorIcon = Icons.wifi_off;
    } else if (errorMessage.contains('server') || errorMessage.contains('500')) {
      errorTitle = 'Server Error';
      errorMessage = 'Our servers encountered an issue. Our team has been notified and is working on it.';
      errorIcon = Icons.cloud_off;
    }

    // Show retry count if retrying
    String retryText = '';
    if (_isRetrying && _retryCount > 0) {
      retryText = 'Retry ${_retryCount}/${_maxRetries}';
      actionText = 'Cancel';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              errorIcon,
              size: 80,
              color: AppColors.scoreLow,
            ),
            const SizedBox(height: 24),
            Text(
              errorTitle,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (retryText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                retryText,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Try again button
                ElevatedButton.icon(
                  icon: Icon(_isRetrying ? Icons.cancel : Icons.refresh),
                  label: Text(
                    actionText,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRetrying ? Colors.grey : AppColors.primary,
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
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
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

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No Analysis Results',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please upload your CV to get an analysis of its ATS compatibility.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.textSecondary,
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
              backgroundColor: AppColors.primary,
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

  Widget _buildResultsView(CvController controller) {
    final result = controller.currentResult!;
    
    // Extract component scores from the result
    final keywordMatchScore = result.keywordMatchScore.toDouble();
    final formattingScore = result.formattingScore.toDouble();
    final contentScore = result.contentScore.toDouble();
    final readabilityScore = result.readabilityScore.toDouble();
    
    // Calculate a more realistic overall score
    final overallScore = ImprovedScoringSystem.calculateRealisticScore(
      keywordMatchScore: keywordMatchScore,
      formattingScore: formattingScore,
      contentScore: contentScore,
      readabilityScore: readabilityScore,
      industryDifficulty: 0.7, // Higher difficulty for more challenging scores
    );
    
    // Get appropriate label and color for the score
    final scoreLabel = ImprovedScoringSystem.getLabelForScore(overallScore);
    final scoreColor = _getColorFromHex(ImprovedScoringSystem.getColorForScore(overallScore));
    
    // Generate realistic suggestions
    final suggestions = ImprovedScoringSystem.generateSuggestions(
      keywordMatchScore: keywordMatchScore,
      formattingScore: formattingScore,
      contentScore: contentScore,
      readabilityScore: readabilityScore,
      industry: result.industry,
    );
    
    // Set up score animation if not already done
    if (!_scoreAnimationController.isAnimating && !_scoreAnimationController.isCompleted) {
      _scoreAnimation = Tween<double>(
        begin: 0.0,
        end: overallScore,
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
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'DETAILS'),
            Tab(text: 'SUGGESTIONS'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Overview tab
              _buildOverviewTab(result, overallScore, scoreLabel, scoreColor),
              
              // Details tab
              _buildDetailsTab(result),
              
              // Suggestions tab
              _buildSuggestionsTab(suggestions),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(dynamic result, double overallScore, String scoreLabel, Color scoreColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'ATS Compatibility Score',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Animated score display
                  AnimatedBuilder(
                    animation: _scoreAnimationController,
                    builder: (context, child) {
                      final displayScore = _scoreAnimationController.isAnimating
                          ? _scoreAnimation.value
                          : overallScore;
                      
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: displayScore / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey.shade800,
                              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${displayScore.toInt()}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                scoreLabel,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Summary text
                  Text(
                    result.summary,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Component scores
          Text(
            'Score Breakdown',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Keyword match score
          _buildScoreItem(
            'Keyword Match',
            result.keywordMatchScore,
            'How well your CV matches the job description keywords',
            Icons.search,
          ),
          
          // Formatting score
          _buildScoreItem(
            'Formatting',
            result.formattingScore,
            'How well your CV is formatted for ATS systems',
            Icons.format_align_left,
          ),
          
          // Content score
          _buildScoreItem(
            'Content Quality',
            result.contentScore,
            'The quality and relevance of your CV content',
            Icons.description,
          ),
          
          // Readability score
          _buildScoreItem(
            'Readability',
            result.readabilityScore,
            'How easy your CV is to read and understand',
            Icons.visibility,
          ),
          
          const SizedBox(height: 24),
          
          // Keywords section
          Text(
            'Keywords Found',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Keywords chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.keywords.map<Widget>((keyword) {
              // Check if this keyword matches job requirements
              final isMatch = result.keywordMatches(keyword); // Using the new method here
              
              return Chip(
                label: Text(
                  keyword,
                  style: TextStyle(
                    color: isMatch ? Colors.white : AppColors.textPrimary,
                    fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: isMatch ? AppColors.primary : Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(dynamic result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills comparison
          _buildSectionCard(
            'Skills Comparison',
            Icons.compare_arrows,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Matched skills
                if (result.skillsComparison.containsKey('matched') &&
                    result.skillsComparison['matched'] is List &&
                    (result.skillsComparison['matched'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matched Skills',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.scoreHigh,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (result.skillsComparison['matched'] as List)
                            .map<Widget>((skill) {
                          return Chip(
                            label: Text(
                              skill.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: AppColors.scoreHigh.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Missing skills
                if (result.skillsComparison.containsKey('missing') &&
                    result.skillsComparison['missing'] is List &&
                    (result.skillsComparison['missing'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missing Skills',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.scoreLow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (result.skillsComparison['missing'] as List)
                            .map<Widget>((skill) {
                          return Chip(
                            label: Text(
                              skill.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: AppColors.scoreLow.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Education comparison
          _buildSectionCard(
            'Education',
            Icons.school,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.educationComparison.map<Widget>((item) {
                final isPositive = !item.contains('missing') && !item.contains('lacking');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isPositive ? Icons.check_circle : Icons.info,
                        color: isPositive ? AppColors.scoreHigh : AppColors.scoreMedium,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Experience comparison
          _buildSectionCard(
            'Experience',
            Icons.work,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.experienceComparison.map<Widget>((item) {
                final isPositive = !item.contains('missing') && !item.contains('lacking');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isPositive ? Icons.check_circle : Icons.info,
                        color: isPositive ? AppColors.scoreHigh : AppColors.scoreMedium,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Searchability issues
          _buildSectionCard(
            'ATS Searchability Issues',
            Icons.error_outline,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.searchabilityIssues.isEmpty
                  ? [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.scoreHigh,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No major searchability issues found.',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    ]
                  : result.searchabilityIssues.map<Widget>((issue) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning,
                              color: AppColors.scoreLow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSuggestionsTab(List<Map<String, String>> suggestions) {
  // Update the method implementation to handle the Map structure
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations to Improve Your CV',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Updated to handle Map structure
        ...suggestions.map((suggestion) {
          // Assuming each map has a 'text' key for the suggestion content
          final text = suggestion['text'] ?? '';
          final category = suggestion['category'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                category,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          Text(
                            text,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        // Rest of the method remains the same
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              // Action buttons...
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildScoreItem(String title, int score, String description, IconData icon) {
    final color = _getScoreColor(score);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade800,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '$score%',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Score details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) {
      return AppColors.scoreHigh;
    } else if (score >= 60) {
      return AppColors.scoreMedium;
    } else {
      return AppColors.scoreLow;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
