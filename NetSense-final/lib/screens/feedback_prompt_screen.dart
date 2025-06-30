import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_result.dart';
import '../models/speed_test_result.dart';
import '../services/storage_service.dart';

class FeedbackPromptScreen extends ConsumerStatefulWidget {
  final SpeedTestResult testResult;

  const FeedbackPromptScreen({
    super.key,
    required this.testResult,
  });

  @override
  ConsumerState<FeedbackPromptScreen> createState() => _FeedbackPromptScreenState();
}

class _FeedbackPromptScreenState extends ConsumerState<FeedbackPromptScreen> {
  int _overallSatisfaction = 3;
  int _responsiveness = 3;
  int _usability = 3;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = FeedbackResult(
        overallSatisfaction: _overallSatisfaction,
        responsiveness: _responsiveness,
        usability: _usability,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        timestamp: DateTime.now(),
        testSessionId: widget.testResult.timestamp.toIso8601String(),
      );

      final storageService = StorageService();
      await storageService.saveFeedbackResult(feedback);

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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Modern app bar with gradient
            SliverAppBar(
              expandedHeight: 140.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Your Feedback',
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
                      Icons.rate_review_outlined,
                      size: 48,
                      color: colorScheme.onPrimary.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Introduction text
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How was your experience?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your feedback helps us improve the app experience.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Overall satisfaction
                  _buildRatingSection(
                    title: 'Overall Satisfaction',
                    value: _overallSatisfaction,
                    onChanged: (value) {
                      setState(() {
                        _overallSatisfaction = value;
                      });
                    },
                    icon: Icons.sentiment_satisfied_alt,
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Responsiveness
                  _buildRatingSection(
                    title: 'App Responsiveness',
                    value: _responsiveness,
                    onChanged: (value) {
                      setState(() {
                        _responsiveness = value;
                      });
                    },
                    icon: Icons.speed,
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Usability
                  _buildRatingSection(
                    title: 'Ease of Use',
                    value: _usability,
                    onChanged: (value) {
                      setState(() {
                        _usability = value;
                      });
                    },
                    icon: Icons.touch_app,
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comments
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Comments (Optional)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Tell us more about your experience...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SUBMIT FEEDBACK',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Skip button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                              ),
                            ),
                            child: Text(
                              'SKIP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = rating <= value;
                final size = MediaQuery.of(context).size.width < 400 ? 36.0 : 42.0;
                
                return InkWell(
                  onTap: () => onChanged(rating),
                  borderRadius: BorderRadius.circular(size / 2),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected 
                            ? colorScheme.primary 
                            : colorScheme.surfaceContainerHighest,
                        boxShadow: isSelected 
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ] 
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          rating.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Poor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Excellent',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
