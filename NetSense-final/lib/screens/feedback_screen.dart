import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_result.dart';
import '../models/speed_test_result.dart';
import '../services/storage_service.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final SpeedTestResult? testResult;
  final bool isFromBackgroundTest;

  const FeedbackScreen({
    super.key,
    this.testResult,
    this.isFromBackgroundTest = false,
  });

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _satisfaction = 3;
  int _responsiveness = 3;
  int _usability = 3;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  final StorageService _storageService = StorageService();
  List<SpeedTestResult> _recentTests = [];
  SpeedTestResult? _selectedTest;

  @override
  void initState() {
    super.initState();
    _loadRecentTests();
    if (widget.testResult != null) {
      _selectedTest = widget.testResult;
    }
  }

  Future<void> _loadRecentTests() async {
    final tests = await _storageService.getTestResults();
    setState(() {
      _recentTests = tests;
      if (_selectedTest == null && tests.isNotEmpty) {
        _selectedTest = tests.first;
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting || _selectedTest == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = FeedbackResult(
        overallSatisfaction: _satisfaction,
        responsiveness: _responsiveness,
        usability: _usability,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        timestamp: DateTime.now(),
        testSessionId: _selectedTest!.timestamp.toIso8601String(),
      );

      await _storageService.saveFeedbackResult(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern app bar with gradient
          SliverAppBar(
            expandedHeight: 140.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Provide Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.feedback_outlined,
                    size: 48,
                    color: colorScheme.onPrimary.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // List items go here
              if (widget.isFromBackgroundTest)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background Test Completed',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A network performance test was completed in the background. '
                          'We\'d appreciate your feedback on the app experience.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

              // Test selection dropdown if no specific test was provided
              if (widget.testResult == null && _recentTests.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Test',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SpeedTestResult>(
                      value: _selectedTest,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _recentTests.map((test) {
                        final date = test.timestamp;
                        final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                        return DropdownMenuItem(
                          value: test,
                          child: Text('$formattedDate - ${test.connectionType} (${test.downloadSpeed.toStringAsFixed(1)} Mbps)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTest = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              Text(
                'Rate Your Experience',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Satisfaction rating
              _buildRatingSlider(
                title: 'Overall Satisfaction',
                value: _satisfaction,
                onChanged: (value) {
                  setState(() {
                    _satisfaction = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Responsiveness rating
              _buildRatingSlider(
                title: 'App Responsiveness',
                value: _responsiveness,
                onChanged: (value) {
                  setState(() {
                    _responsiveness = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Usability rating
              _buildRatingSlider(
                title: 'Ease of Use',
                value: _usability,
                onChanged: (value) {
                  setState(() {
                    _usability = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Comments
              Text(
                'Additional Comments (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Tell us more about your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTest == null || _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SUBMIT FEEDBACK', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('SKIP', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    ])
  );
}

  Widget _buildRatingSlider({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0'),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: value.toString(),
                onChanged: (double newValue) {
                  onChanged(newValue.round());
                },
              ),
            ),
            const Text('5'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Poor'),
            Text('Excellent'),
          ],
        ),
      ],
    );
  }
}
