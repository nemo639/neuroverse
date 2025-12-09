import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Test phases
enum NBackPhase { instructions, practice, test, completed }

class NBackTestScreen extends StatefulWidget {
  const NBackTestScreen({super.key});

  @override
  State<NBackTestScreen> createState() => _NBackTestScreenState();
}

class _NBackTestScreenState extends State<NBackTestScreen>
    with TickerProviderStateMixin {
  
  NBackPhase _currentPhase = NBackPhase.instructions;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _gridController;

  // Test configuration
  final int _nBack = 2; // 2-back test
  final int _practiceTrials = 8;
  final int _testTrials = 25;
  final int _gridSize = 3; // 3x3 grid
  int _currentTrial = 0;
  bool _isPractice = true;

  // Stimulus timing
  final int _stimulusDurationMs = 500;
  final int _interStimulusIntervalMs = 2000;

  // Current state
  int? _currentPosition; // 0-8 for 3x3 grid
  List<int> _sequence = [];
  bool _showingStimulus = false;
  bool _canRespond = false;
  bool _responded = false;
  bool? _lastResponseCorrect;
  DateTime? _stimulusStartTime;

  // Results tracking
  int _hits = 0; // Correctly identified matches
  int _misses = 0; // Missed matches
  int _falseAlarms = 0; // Incorrectly pressed when no match
  int _correctRejections = 0; // Correctly didn't press when no match
  List<int> _reactionTimes = [];
  final List<Map<String, dynamic>> _trialResults = [];

  // Timers
  Timer? _stimulusTimer;
  Timer? _responseWindowTimer;

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
  static const Color orangeAccent = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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
    _gridController.dispose();
    _stimulusTimer?.cancel();
    _responseWindowTimer?.cancel();
    super.dispose();
  }

  void _generateSequence(int length) {
    _sequence = [];
    final positions = List.generate(9, (i) => i); // 0-8 positions
    
    for (int i = 0; i < length; i++) {
      if (i >= _nBack && _random.nextDouble() < 0.3) {
        // 30% chance of match (same as N positions back)
        _sequence.add(_sequence[i - _nBack]);
      } else {
        // Random position (avoiding match if not intended)
        int pos;
        do {
          pos = positions[_random.nextInt(positions.length)];
        } while (i >= _nBack && pos == _sequence[i - _nBack]);
        _sequence.add(pos);
      }
    }
  }

  bool _isMatch() {
    if (_currentTrial < _nBack) return false;
    return _sequence[_currentTrial] == _sequence[_currentTrial - _nBack];
  }

  void _startPractice() {
    _generateSequence(_practiceTrials);
    setState(() {
      _currentPhase = NBackPhase.practice;
      _isPractice = true;
      _currentTrial = 0;
      _hits = 0;
      _misses = 0;
      _falseAlarms = 0;
      _correctRejections = 0;
    });
    _showNextStimulus();
  }

  void _startTest() {
    _generateSequence(_testTrials);
    setState(() {
      _currentPhase = NBackPhase.test;
      _isPractice = false;
      _currentTrial = 0;
      _hits = 0;
      _misses = 0;
      _falseAlarms = 0;
      _correctRejections = 0;
      _reactionTimes = [];
      _trialResults.clear();
    });
    _showNextStimulus();
  }

  void _showNextStimulus() {
    setState(() {
      _currentPosition = _sequence[_currentTrial];
      _showingStimulus = true;
      _canRespond = true;
      _responded = false;
      _lastResponseCorrect = null;
      _stimulusStartTime = DateTime.now();
    });

    _pulseController.forward(from: 0);
    _gridController.forward(from: 0);

    // Hide stimulus after duration
    _stimulusTimer = Timer(Duration(milliseconds: _stimulusDurationMs), () {
      setState(() {
        _showingStimulus = false;
      });
    });

    // Response window
    _responseWindowTimer = Timer(Duration(milliseconds: _interStimulusIntervalMs), () {
      _evaluateResponse();
    });
  }

  void _handleMatchPress() {
    if (!_canRespond || _responded) return;

    HapticFeedback.mediumImpact();
    final reactionTime = DateTime.now().difference(_stimulusStartTime!).inMilliseconds;

    setState(() {
      _responded = true;
      _canRespond = false;
      
      if (_isMatch()) {
        _hits++;
        _lastResponseCorrect = true;
      } else {
        _falseAlarms++;
        _lastResponseCorrect = false;
      }

      if (!_isPractice) {
        _reactionTimes.add(reactionTime);
      }
    });
  }

  void _evaluateResponse() {
    final wasMatch = _isMatch();
    
    if (!_responded) {
      // No response given
      if (wasMatch) {
        _misses++;
        _lastResponseCorrect = false;
      } else {
        _correctRejections++;
        _lastResponseCorrect = true;
      }
    }

    if (!_isPractice) {
      _trialResults.add({
        'trial': _currentTrial + 1,
        'position': _currentPosition,
        'was_match': wasMatch,
        'responded': _responded,
        'correct': _lastResponseCorrect ?? false,
        'reaction_time_ms': _responded ? _reactionTimes.last : null,
      });
    }

    setState(() {
      _currentTrial++;
      _canRespond = false;
    });

    final maxTrials = _isPractice ? _practiceTrials : _testTrials;
    
    if (_currentTrial >= maxTrials) {
      if (_isPractice) {
        Future.delayed(const Duration(milliseconds: 500), _startTest);
      } else {
        setState(() {
          _currentPhase = NBackPhase.completed;
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 300), _showNextStimulus);
    }
  }

  Map<String, dynamic> _getTestData() {
    final totalMatches = _hits + _misses;
    final totalNonMatches = _falseAlarms + _correctRejections;
    final accuracy = (_hits + _correctRejections) / _testTrials;
    final avgRT = _reactionTimes.isNotEmpty 
        ? _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length 
        : 0.0;
    
    return {
      'test_type': 'nback',
      'n_back_level': _nBack,
      'total_trials': _testTrials,
      'hits': _hits,
      'misses': _misses,
      'false_alarms': _falseAlarms,
      'correct_rejections': _correctRejections,
      'accuracy': accuracy,
      'hit_rate': totalMatches > 0 ? _hits / totalMatches : 0,
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
    _stimulusTimer?.cancel();
    _responseWindowTimer?.cancel();
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
            if (_currentPhase == NBackPhase.practice || 
                _currentPhase == NBackPhase.test)
              _buildBottomSection(),
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
                  'N-Back Memory',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
              color: orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_nBack-Back',
              style: const TextStyle(
                color: orangeAccent,
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
      case NBackPhase.instructions:
        return 'Read instructions carefully';
      case NBackPhase.practice:
        return 'Practice round - Trial ${_currentTrial + 1}/$_practiceTrials';
      case NBackPhase.test:
        return 'Trial ${_currentTrial + 1}/$_testTrials';
      case NBackPhase.completed:
        return 'Test completed';
    }
  }

  Widget _buildProgressBar() {
    double progress = 0;
    if (_currentPhase == NBackPhase.practice) {
      progress = _currentTrial / _practiceTrials * 0.2;
    } else if (_currentPhase == NBackPhase.test) {
      progress = 0.2 + (_currentTrial / _testTrials * 0.8);
    } else if (_currentPhase == NBackPhase.completed) {
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
            gradient: const LinearGradient(colors: [orangeAccent, redAccent]),
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
      case NBackPhase.instructions:
        return _buildInstructionsPhase();
      case NBackPhase.practice:
      case NBackPhase.test:
        return _buildTestPhase();
      case NBackPhase.completed:
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
              color: orangeAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grid_3x3_rounded, color: orangeAccent, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            '2-Back Memory Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Test your working memory',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          // Mini grid example
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Watch the grid:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: _buildMiniGrid(4), // Example position
                ),
                const SizedBox(height: 12),
                Text(
                  'Press "MATCH" if the position is the same\nas 2 steps ago',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softLavender.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildInstructionRow(Icons.visibility, 'Watch where the square appears'),
                const SizedBox(height: 8),
                _buildInstructionRow(Icons.history, 'Remember the position from 2 steps back'),
                const SizedBox(height: 8),
                _buildInstructionRow(Icons.touch_app, 'Tap MATCH if positions are the same'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _startPractice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: orangeAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: orangeAccent.withOpacity(0.4),
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
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
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
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }

  Widget _buildMiniGrid(int highlightPosition) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final isHighlighted = index == highlightPosition;
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted ? orangeAccent : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  Widget _buildTestPhase() {
    return Column(
      children: [
        // Feedback indicator
        if (_lastResponseCorrect != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _lastResponseCorrect! 
                  ? greenAccent.withOpacity(0.1) 
                  : redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _lastResponseCorrect! ? Icons.check : Icons.close,
                  color: _lastResponseCorrect! ? greenAccent : redAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _lastResponseCorrect! ? 'Correct!' : 'Wrong',
                  style: TextStyle(
                    color: _lastResponseCorrect! ? greenAccent : redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isPractice ? Colors.orange.withOpacity(0.1) : blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isPractice ? '🎯 Practice' : '📝 Test',
              style: TextStyle(
                color: _isPractice ? Colors.orange : blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Main grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
                child: _buildGrid(),
              ),
            ),
          ),
        ),
        // Match hint
        if (_currentTrial >= _nBack)
          Text(
            'Same as $_nBack positions ago?',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final isHighlighted = _showingStimulus && index == _currentPosition;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHighlighted ? orangeAccent : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? orangeAccent : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: orangeAccent.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Match button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _canRespond ? _handleMatchPress : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _canRespond 
                    ? (_responded ? Colors.grey : orangeAccent) 
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canRespond && !_responded
                    ? [
                        BoxShadow(
                          color: orangeAccent.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _responded ? Icons.check : Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _responded ? 'Responded!' : 'MATCH',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Metrics bar
        _buildMetricsBar(),
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
          _buildMiniMetric('HITS', '$_hits', greenAccent),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _buildMiniMetric('MISSES', '$_misses', redAccent),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _buildMiniMetric('FALSE', '$_falseAlarms', orangeAccent),
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

  Widget _buildCompletedPhase() {
    final data = _getTestData();
    final accuracy = (data['accuracy'] * 100).toStringAsFixed(0);
    final hitRate = (data['hit_rate'] * 100).toStringAsFixed(0);
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mintGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildResultRow('Overall Accuracy', '$accuracy%'),
                const Divider(height: 20),
                _buildResultRow('Hit Rate', '$hitRate%'),
                const Divider(height: 20),
                _buildResultRow('Hits / Misses', '$_hits / $_misses'),
                const Divider(height: 20),
                _buildResultRow('False Alarms', '$_falseAlarms'),
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
}