import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Test phases
enum StroopPhase { instructions, practice, test, completed }

class StroopTestScreen extends StatefulWidget {
  const StroopTestScreen({super.key});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen>
    with TickerProviderStateMixin {
  
  StroopPhase _currentPhase = StroopPhase.instructions;

  // Animation controllers
  late AnimationController _pulseController;

  // Test configuration
  final int _practiceTrials = 3;
  final int _testTrials = 20;
  int _currentTrial = 0;
  bool _isPractice = true;

  // Stroop stimuli
  final List<String> _colorWords = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  final Map<String, Color> _colors = {
    'RED': const Color(0xFFEF4444),
    'BLUE': const Color(0xFF3B82F6),
    'GREEN': const Color(0xFF10B981),
    'YELLOW': const Color(0xFFEAB308),
  };

  // Current stimulus
  String _currentWord = '';
  Color _currentColor = Colors.black;
  String _correctAnswer = '';
  DateTime? _stimulusStartTime;
  bool _showingStimulus = false;
  bool _showingFeedback = false;
  bool? _lastAnswerCorrect;

  // Results tracking
  final List<Map<String, dynamic>> _trialResults = [];
  int _correctCount = 0;
  int _errorCount = 0;
  List<int> _reactionTimes = [];

  // Timers
  Timer? _nextTrialTimer;

  // Random generator
  final math.Random _random = math.Random();

  // Design colors
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color redAccent = Color(0xFFEF4444);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nextTrialTimer?.cancel();
    super.dispose();
  }

  void _generateStimulus() {
    // Pick random word and color (ensuring they're different for Stroop effect)
    final wordIndex = _random.nextInt(_colorWords.length);
    int colorIndex = _random.nextInt(_colorWords.length);
    
    // 70% chance of incongruent (word != color) for Stroop effect
    if (_random.nextDouble() < 0.7) {
      while (colorIndex == wordIndex) {
        colorIndex = _random.nextInt(_colorWords.length);
      }
    }

    _currentWord = _colorWords[wordIndex];
    final colorName = _colorWords[colorIndex];
    _currentColor = _colors[colorName]!;
    _correctAnswer = colorName; // Answer is the INK COLOR, not the word
  }

  void _startPractice() {
    setState(() {
      _currentPhase = StroopPhase.practice;
      _isPractice = true;
      _currentTrial = 0;
      _correctCount = 0;
      _errorCount = 0;
    });
    _showNextStimulus();
  }

  void _startTest() {
    setState(() {
      _currentPhase = StroopPhase.test;
      _isPractice = false;
      _currentTrial = 0;
      _correctCount = 0;
      _errorCount = 0;
      _reactionTimes = [];
      _trialResults.clear();
    });
    _showNextStimulus();
  }

  void _showNextStimulus() {
    _generateStimulus();
    setState(() {
      _showingStimulus = true;
      _showingFeedback = false;
      _stimulusStartTime = DateTime.now();
    });
  }

  void _handleResponse(String selectedColor) {
    if (!_showingStimulus || _showingFeedback) return;

    final reactionTime = DateTime.now().difference(_stimulusStartTime!).inMilliseconds;
    final isCorrect = selectedColor == _correctAnswer;

    HapticFeedback.mediumImpact();

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = isCorrect;
      
      if (isCorrect) {
        _correctCount++;
      } else {
        _errorCount++;
      }

      if (!_isPractice) {
        _reactionTimes.add(reactionTime);
        _trialResults.add({
          'trial': _currentTrial + 1,
          'word': _currentWord,
          'ink_color': _correctAnswer,
          'response': selectedColor,
          'correct': isCorrect,
          'reaction_time_ms': reactionTime,
        });
      }

      _currentTrial++;
    });

    // Show feedback briefly, then next trial
    _nextTrialTimer = Timer(const Duration(milliseconds: 800), () {
      final maxTrials = _isPractice ? _practiceTrials : _testTrials;
      
      if (_currentTrial >= maxTrials) {
        if (_isPractice) {
          // Move to actual test
          _startTest();
        } else {
          // Test complete
          setState(() {
            _currentPhase = StroopPhase.completed;
            _showingStimulus = false;
          });
        }
      } else {
        _showNextStimulus();
      }
    });
  }

  Map<String, dynamic> _getTestData() {
    final avgRT = _reactionTimes.isNotEmpty 
        ? _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length 
        : 0.0;
    
    return {
      'test_type': 'stroop',
      'total_trials': _testTrials,
      'correct': _correctCount,
      'errors': _errorCount,
      'accuracy': _correctCount / _testTrials,
      'avg_reaction_time_ms': avgRT,
      'reaction_times': _reactionTimes,
      'trials': _trialResults,
      'completed': true,
    };
  }

  void _completeTest() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _getTestData());
  }

  void _exitTest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Test?'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: _buildContent()),
            if (_currentPhase == StroopPhase.practice || 
                _currentPhase == StroopPhase.test)
              _buildMetricsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _exitTest,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stroop Test',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _getPhaseText(),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: purpleAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isPractice ? 'Practice' : '${_currentTrial}/$_testTrials',
              style: TextStyle(
                color: purpleAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case StroopPhase.instructions:
        return 'Read instructions carefully';
      case StroopPhase.practice:
        return 'Practice round';
      case StroopPhase.test:
        return 'Tap the INK COLOR, not the word';
      case StroopPhase.completed:
        return 'Test completed';
    }
  }

  Widget _buildProgressBar() {
    double progress = 0;
    if (_currentPhase == StroopPhase.practice) {
      progress = _currentTrial / _practiceTrials * 0.2;
    } else if (_currentPhase == StroopPhase.test) {
      progress = 0.2 + (_currentTrial / _testTrials * 0.8);
    } else if (_currentPhase == StroopPhase.completed) {
      progress = 1.0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [purpleAccent, blueAccent]),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildPhaseContent(),
    );
  }

  Widget _buildPhaseContent() {
    switch (_currentPhase) {
      case StroopPhase.instructions:
        return _buildInstructionsPhase();
      case StroopPhase.practice:
      case StroopPhase.test:
        return _buildTestPhase();
      case StroopPhase.completed:
        return _buildCompletedPhase();
    }
  }

  Widget _buildInstructionsPhase() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: purpleAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_rounded, color: purpleAccent, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Stroop Color Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Test your attention and processing speed',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          // Example
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  'Example:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'RED',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3B82F6), // Blue color
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The word says "RED" but the ink is BLUE',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap BLUE (the ink color)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: greenAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softLavender.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildInstructionRow(Icons.visibility, 'Look at the word displayed'),
                const SizedBox(height: 8),
                _buildInstructionRow(Icons.touch_app, 'Tap the INK COLOR, not the word'),
                const SizedBox(height: 8),
                _buildInstructionRow(Icons.speed, 'Be quick but accurate'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _startPractice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: purpleAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: purpleAccent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Start Practice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ),
      ],
    );
  }

  Widget _buildTestPhase() {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Phase indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isPractice ? Colors.orange.withOpacity(0.1) : greenAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isPractice ? '🎯 Practice Round' : '📝 Test Round',
            style: TextStyle(
              color: _isPractice ? Colors.orange : greenAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        // Stimulus or Feedback
        if (_showingFeedback)
          _buildFeedback()
        else if (_showingStimulus)
          _buildStimulus(),
        const Spacer(),
        // Color buttons
        _buildColorButtons(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStimulus() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Text(
            _currentWord,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _currentColor,
              letterSpacing: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lastAnswerCorrect! 
            ? greenAccent.withOpacity(0.1) 
            : redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            _lastAnswerCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _lastAnswerCorrect! ? greenAccent : redAccent,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(
            _lastAnswerCorrect! ? 'Correct!' : 'Wrong!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _lastAnswerCorrect! ? greenAccent : redAccent,
            ),
          ),
          if (!_lastAnswerCorrect!)
            Text(
              'Answer was: $_correctAnswer',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildColorButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _colorWords.map((colorName) {
        final color = _colors[colorName]!;
        return GestureDetector(
          onTap: _showingStimulus && !_showingFeedback
              ? () => _handleResponse(colorName)
              : null,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                colorName[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedPhase() {
    final data = _getTestData();
    final accuracy = (data['accuracy'] * 100).toStringAsFixed(0);
    final avgRT = (data['avg_reaction_time_ms'] as double).toStringAsFixed(0);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: greenAccent, size: 45),
          ),
          const SizedBox(height: 20),
          const Text(
            'Test Completed!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          // Results
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mintGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildResultRow('Accuracy', '$accuracy%'),
                const Divider(height: 20),
                _buildResultRow('Correct', '${data['correct']}/$_testTrials'),
                const Divider(height: 20),
                _buildResultRow('Avg Reaction Time', '${avgRT}ms'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _completeTest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: greenAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Continue', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniMetric('CORRECT', '$_correctCount', greenAccent),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _buildMiniMetric('ERRORS', '$_errorCount', redAccent),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _buildMiniMetric('TRIAL', '$_currentTrial/${_isPractice ? _practiceTrials : _testTrials}', blueAccent),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}