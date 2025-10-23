import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart' show AppTheme;
import 'custom_button.dart';


class DragDropArea extends StatefulWidget {
  final Function(PlatformFile) onFileSelected;
  final List<String> allowedExtensions;
  final int maxFileSizeMB;
  final String? selectedFileName;

  const DragDropArea({
    super.key,
    required this.onFileSelected,
    this.allowedExtensions = const ['pdf', 'doc', 'docx'],
    this.maxFileSizeMB = 10,
    this.selectedFileName,
  });

  @override
  State<DragDropArea> createState() => _DragDropAreaState();
}

class _DragDropAreaState extends State<DragDropArea>
    with SingleTickerProviderStateMixin {
  bool _isDragOver = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size
        if (file.size > widget.maxFileSizeMB * 1024 * 1024) {
          _showError('File size exceeds ${widget.maxFileSizeMB}MB limit');
          return;
        }

        widget.onFileSelected(file);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = widget.selectedFileName != null;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  padding: const EdgeInsets.all(24),
                  color: _isDragOver
                      ? AppTheme.primaryColor
                      : _isHovered
                          ? AppTheme.primaryColor.withOpacity(0.7)
                          : hasFile
                              ? AppTheme.successColor
                              : theme.colorScheme.outline,
                  strokeWidth: _isDragOver ? 3 : 2,
                  dashPattern: const [8, 4],
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _isDragOver
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : _isHovered
                              ? AppTheme.primaryColor.withOpacity(0.05)
                              : hasFile
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasFile
                                ? AppTheme.successColor.withOpacity(0.2)
                                : AppTheme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasFile ? Icons.check_circle : Icons.cloud_upload,
                            size: 48,
                            color: hasFile
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                          ),
                        ).animate().scale(duration: 300.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          hasFile ? 'File Selected' : 'Upload Your CV',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasFile
                                ? AppTheme.successColor
                                : theme.colorScheme.onSurface,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        if (hasFile) ...[
                          Text(
                            widget.selectedFileName!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click to change file',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Drag and drop your CV here, or click to browse',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Browse button
                          CustomButton(
                            text: 'Browse Files',
                            variant: ButtonVariant.outline,
                            size: ButtonSize.medium,
                            icon: Icons.folder_open,
                            onPressed: _pickFile,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // File info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Supported: ${widget.allowedExtensions.join(', ').toUpperCase()} • Max ${widget.maxFileSizeMB}MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
