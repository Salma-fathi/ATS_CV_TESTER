import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
// Removed Lottie import since we're not using it anymore
import '../ controllers/cv_controller.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Your CV',
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
      ),
      body: Consumer<CvController>(
        builder: (context, controller, child) {
          return Container(
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Upload illustration
                    controller.isLoading
                        ? _buildLoadingAnimation()
                        : _buildUploadArea(controller),
                    
                    const SizedBox(height: 40),
                    
                    // File format info
                    _buildFileFormatInfo(),
                    
                    const SizedBox(height: 40),
                    
                    // Upload tips
                    _buildUploadTips(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // FIXED: Replaced Lottie animation with Flutter's built-in loading indicators
  Widget _buildLoadingAnimation() {
    return Column(
      children: [
        // Replaced Lottie with a custom animated loading indicator
        SizedBox(
          height: 200,
          width: 200,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 4,
                  ),
                ),
                // Inner circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.7)),
                    strokeWidth: 6,
                  ),
                ),
                // Icon in center
                Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ],
            ),
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
        Text(
          'We\'re checking your CV against ATS requirements and industry standards.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          backgroundColor: AppColors.cardBackground,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildUploadArea(CvController controller) {
    return Column(
      children: [
        // Upload area with drag & drop
        GestureDetector(
          onTap: () async {
            try {
              await controller.uploadAndAnalyzeCV();
            } catch (e) {
              _showErrorSnackbar(e.toString());
            }
          },
          child: DragTarget<Object>(
            onWillAccept: (_) {
              setState(() => _isDragging = true);
              return true;
            },
            onAccept: (_) async {
              setState(() => _isDragging = false);
              try {
                await controller.uploadAndAnalyzeCV();
              } catch (e) {
                _showErrorSnackbar(e.toString());
              }
            },
            onLeave: (_) => setState(() => _isDragging = false),
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 250,
                width: double.infinity,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(20),
                  color: _isDragging ? AppColors.primary : AppColors.textSecondary,
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDragging 
                          ? AppColors.primary.withOpacity(0.1) 
                          : AppColors.cardBackground.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_animationController.value * 0.1),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: _isDragging 
                                    ? AppColors.primary 
                                    : AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.selectedFile != null
                              // FIXED: Using name property instead of path for web compatibility
                              ? 'Selected: ${controller.selectedFile!.name}'
                              : 'Drag & Drop your CV here',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _isDragging 
                                ? AppColors.primary 
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'or',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text(
                            'Choose File',
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
                          onPressed: () async {
                            try {
                              await controller.uploadAndAnalyzeCV();
                            } catch (e) {
                              _showErrorSnackbar(e.toString());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileFormatInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Supported File Formats',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFormatItem(Icons.picture_as_pdf, 'PDF', '(Recommended)'),
              _buildFormatItem(Icons.description_outlined, 'DOCX', ''),
              _buildFormatItem(Icons.text_snippet_outlined, 'TXT', ''),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Maximum file size: 5MB',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(IconData icon, String format, String note) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          format,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (note.isNotEmpty)
          Text(
            note,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildUploadTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Tips for Better Results',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Use PDF format for best ATS compatibility'),
          _buildTipItem('Ensure your CV is up-to-date with your latest experience'),
          _buildTipItem('Include relevant keywords from the job description'),
          _buildTipItem('Quantify your achievements with numbers and metrics'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.scoreHigh,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.scoreLow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
