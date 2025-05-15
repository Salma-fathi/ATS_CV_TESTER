import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ controllers/cv_controller.dart';
import '../models/analysis_result.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analysis Results',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[900],
      body: Consumer<CvController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blue));
          }

          if (controller.error != null) {
            return _buildErrorState(controller.error!);
          }

          if (controller.currentResult == null) {
            return const Center(child: Text('No analysis results available'));
          }

          return _buildAnalysisResults(controller.currentResult!);
        },
      ),
    );
  }

  Widget _buildAnalysisResults(AnalysisResult result) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildScoreIndicator(result.score.toDouble()),
        const SizedBox(height: 32),
        _buildResultSection('Summary', result.summary),
        const SizedBox(height: 20),
        _buildResultSection('Key Skills', result.keywords.join(', ')),
      ],
    );
  }

  Widget _buildScoreIndicator(double score) {
    final color = score >= 80
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toStringAsFixed(0)}%',
                style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'SCORE',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
                color: Colors.blue[200],
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.montserrat(
                color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              error,
              style: GoogleFonts.montserrat(
                  color: Colors.white70, fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.read<CvController>().clearResults(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
