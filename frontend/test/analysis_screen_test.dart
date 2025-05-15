import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/%20controllers/result_controller.dart' show ResultController;
import 'package:frontend/%20widgets/analysis_screen.dart';
import 'package:frontend/models/analysis_result.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Mock ResultController
class MockResultController extends Mock implements ResultController {
  AnalysisResult? _result;
  String? _error;
  bool _isLoading = false;

  @override
  AnalysisResult? get result => _result;
  
  @override
  String? get error => _error;
  
  @override
  bool get isLoading => _isLoading;

  void setResult(AnalysisResult? result) {
    _result = result;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  @override
  Future<void> loadResult(String cvId) async {
    // Mock implementation
  }
}

void main() {
  late MockResultController mockController;

  setUp(() {
    mockController = MockResultController();
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ResultController>.value(
        value: mockController,
        child: const AnalysisScreen(cvId: 'test-id'),
      ),
    );
  }

  testWidgets('Shows loading indicator when isLoading is true', (WidgetTester tester) async {
    // Set loading state
    mockController.setLoading(true);
    
    // Build widget
    await tester.pumpWidget(createTestableWidget());
    
    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Analyzing your CV...'), findsOneWidget);
  });

  testWidgets('Shows error message when error is not null', (WidgetTester tester) async {
    // Set error state
    mockController.setLoading(false);
    mockController.setError('Test error message');
    
    // Build widget
    await tester.pumpWidget(createTestableWidget());
    
    // Verify error message is shown
    expect(find.text('Test error message'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Shows analysis report when result is available', (WidgetTester tester) async {
    // Create mock result
    final mockResult = AnalysisResult(
      id: 'test-id',
      score: 85,
      keywords: ['flutter', 'dart', 'mobile'],
      summary: 'Test summary',
      analysisDate: DateTime.now(),
      skillsComparison: {
        'matching_keywords': ['flutter', 'dart'],
        'missing_keywords': ['react'],
        'match_percentage': 75.0
      },
      searchabilityIssues: ['Missing keyword: react'],
      educationComparison: ['Bachelor\'s degree matches requirements'],
      experienceComparison: ['3 years experience matches requirements'],
      jobDescription: 'Test job description',
      recommendations: ['Add more keywords'],
    );
    
    // Set result state
    mockController.setLoading(false);
    mockController.setError(null);
    mockController.setResult(mockResult);
    
    // Build widget
    await tester.pumpWidget(createTestableWidget());
    
    // Verify score card is shown
    expect(find.text('85.0%'), findsOneWidget);
    
    // Verify summary is shown
    expect(find.text('Test summary'), findsOneWidget);
    
    // Verify keywords are shown
    expect(find.text('Key Skills Identified'), findsOneWidget);
    
    // Verify job description is shown
    expect(find.text('Job Description'), findsOneWidget);
    expect(find.text('Test job description'), findsOneWidget);
  });

  testWidgets('Retry button calls loadResult', (WidgetTester tester) async {
    // Set error state
    mockController.setLoading(false);
    mockController.setError('Test error message');
    
    // Build widget
    await tester.pumpWidget(createTestableWidget());
    
    // Verify retry button is shown
    expect(find.text('Retry'), findsOneWidget);
    
    // Tap retry button
    await tester.tap(find.text('Retry'));
    await tester.pump();
    
    // Verify loadResult was called
    verify(mockController.loadResult('test-id')).called(1);
  });
}