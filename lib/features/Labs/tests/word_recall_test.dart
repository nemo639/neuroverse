import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Test phases
enum WordRecallPhase { instructions, learning, distraction, recall, completed }

class WordRecallTestScreen extends StatefulWidget {
  const WordRecallTestScreen({super.key});

  @override
  State<WordRecallTestScreen> createState() => _WordRecallTestScreenState();
}

class _WordRecallTestScreenState extends State<WordRecallTestScreen>
    with TickerProviderStateMixin {
  
  WordRecallPhase _currentPhase = WordRecallPhase.instructions;

  // Animation controllers
  late AnimationController _fadeController;

  // Test configuration
  final List<String> _wordList = [
    'APPLE', 'RIVER', 'CHAIR', 'SUNSET', 'GARDEN',
    'CLOCK', 'BRIDGE', 'COFFEE', 'WINDOW', 'FLOWER',
    'MUSIC', 'SILVER', 'DOCTOR', 'CANDLE', 'FOREST',
  ];
  
  final int _displayTimePerWord = 2; // seconds
  int _currentWordIndex = 0;
  
  // Distraction phase
  final int _distractionDuration = 30; // seconds
  int _distractionTimeLeft = 30;
  int _countdownNumber = 100;
  final List<int> _countdownResponses = [];
  Timer? _countdownTimer;
  final TextEditingController _countdownController = TextEditingController();

  // Recall phase
  final TextEditingController _recallController = TextEditingController();
  final List<String> _recalledWords = [];
  final int _recallTimeLimit = 90; // seconds
  int _recallTimeLeft = 90;
  Timer? _recallTimer;

  // Timers
  Timer? _wordTimer;
  Timer? _distractionTimer;

  // Design colors
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color redAccent = Color(0xFFEF4444);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color tealAccent = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _fadeController.dispose();
    _wordTimer?.cancel();
    _distractionTimer?.cancel();
    _countdownTimer?.cancel();
    _recallTimer?.cancel();
    _countdownController.dispose();
    _recallController.dispose();
    super.dispose();
  }

  void _startLearning() {
    setState(() {
      _currentPhase = WordRecallPhase.learning;
      _currentWordIndex = 0;
    });
    _showNextWord();
  }

  void _showNextWord() {
    if (_currentWordIndex >= _wordList.length) {
      // Done showing words, start distraction
      _startDistraction();
      return;
    }

    _fadeController.forward(from: 0);

    _wordTimer = Timer(Duration(seconds: _displayTimePerWord), () {
      setState(() {
        _currentWordIndex++;
      });
      _showNextWord();
    });
  }

  void _startDistraction() {
    setState(() {
      _currentPhase = WordRecallPhase.distraction;
      _distractionTimeLeft = _distractionDuration;
      _countdownNumber = 100;
    });

    _distractionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _distractionTimeLeft--;
      });

      if (_distractionTimeLeft <= 0) {
        timer.cancel();
        _startRecall();
      }
    });
  }

  void _handleCountdownSubmit() {
    final input = int.tryParse(_countdownController.text);
    if (input != null) {
      _countdownResponses.add(input);
      _countdownController.clear();
      setState(() {
        _countdownNumber = input - 7;
        if (_countdownNumber < 0) _countdownNumber = 0;
      });
    }
  }

  void _startRecall() {
    setState(() {
      _currentPhase = WordRecallPhase.recall;
      _recallTimeLeft = _recallTimeLimit;
      _recalledWords.clear();
    });

    _recallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recallTimeLeft--;
      });

      if (_recallTimeLeft <= 0) {
        timer.cancel();
        _completeRecall();
      }
    });
  }

  void _handleWordSubmit() {
    final word = _recallController.text.trim().toUpperCase();
    if (word.isNotEmpty && !_recalledWords.contains(word)) {
      setState(() {
        _recalledWords.add(word);
      });
      _recallController.clear();
      HapticFeedback.lightImpact();
    }
  }

  void _removeWord(String word) {
    setState(() {
      _recalledWords.remove(word);
    });
  }

  void _completeRecall() {
    _recallTimer?.cancel();
    setState(() {
      _currentPhase = WordRecallPhase.completed;
    });
  }

  Map<String, dynamic> _getTestData() {
    final correctWords = _recalledWords.where((w) => _wordList.contains(w)).toList();
    final incorrectWords = _recalledWords.where((w) => !_wordList.contains(w)).toList();
    final missedWords = _wordList.where((w) => !_recalledWords.contains(w)).toList();
    
    return {
      'test_type': 'word_recall',
      'words_shown': _wordList,
      'words_recalled': _recalledWords,
      'correct_words': correctWords,
      'incorrect_words': incorrectWords,
      'missed_words': missedWords,
      'correct_count': correctWords.length,
      'total_words': _wordList.length,
      'accuracy': correctWords.length / _wordList.length,
      'intrusion_errors': incorrectWords.length,
      'distraction_responses': _countdownResponses,
      'recall_time_used': _recallTimeLimit - _recallTimeLeft,
      'completed': true,
    };
  }

  void _completeTest() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _getTestData());
  }

  void _exitTest() {
    _wordTimer?.cancel();
    _distractionTimer?.cancel();
    _recallTimer?.cancel();
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
                  'Word List Recall',
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
              color: tealAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_wordList.length} words',
              style: const TextStyle(
                color: tealAccent,
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
      case WordRecallPhase.instructions:
        return 'Read instructions carefully';
      case WordRecallPhase.learning:
        return 'Memorize each word';
      case WordRecallPhase.distraction:
        return 'Count backwards by 7';
      case WordRecallPhase.recall:
        return 'Type all words you remember';
      case WordRecallPhase.completed:
        return 'Test completed';
    }
  }

  Widget _buildProgressBar() {
    double progress = 0;
    switch (_currentPhase) {
      case WordRecallPhase.instructions:
        progress = 0;
        break;
      case WordRecallPhase.learning:
        progress = 0.1 + (_currentWordIndex / _wordList.length * 0.3);
        break;
      case WordRecallPhase.distraction:
        progress = 0.4 + ((1 - _distractionTimeLeft / _distractionDuration) * 0.2);
        break;
      case WordRecallPhase.recall:
        progress = 0.6 + ((1 - _recallTimeLeft / _recallTimeLimit) * 0.35);
        break;
      case WordRecallPhase.completed:
        progress = 1.0;
        break;
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
            gradient: const LinearGradient(colors: [tealAccent, greenAccent]),
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
      case WordRecallPhase.instructions:
        return _buildInstructionsPhase();
      case WordRecallPhase.learning:
        return _buildLearningPhase();
      case WordRecallPhase.distraction:
        return _buildDistractionPhase();
      case WordRecallPhase.recall:
        return _buildRecallPhase();
      case WordRecallPhase.completed:
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
              color: tealAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.text_fields_rounded, color: tealAccent, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Word List Recall',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Test your memory for words',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                _buildInstructionStep('1', 'You will see 15 words, one at a time'),
                const SizedBox(height: 10),
                _buildInstructionStep('2', 'Try to memorize each word'),
                const SizedBox(height: 10),
                _buildInstructionStep('3', 'Then count backwards (distraction)'),
                const SizedBox(height: 10),
                _buildInstructionStep('4', 'Finally, type all words you remember'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: Colors.grey[500], size: 18),
              const SizedBox(width: 6),
              Text(
                'Total time: ~6 minutes',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _startLearning,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: tealAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: tealAccent.withOpacity(0.4),
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
                    'Start Test',
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

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: tealAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ),
      ],
    );
  }

  Widget _buildLearningPhase() {
    if (_currentWordIndex >= _wordList.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tealAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Word ${_currentWordIndex + 1} of ${_wordList.length}',
            style: const TextStyle(
              color: tealAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        FadeTransition(
          opacity: _fadeController,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tealAccent.withOpacity(0.3), width: 2),
            ),
            child: Text(
              _wordList[_currentWordIndex],
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Memorize this word',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _wordList.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: index == _currentWordIndex ? 10 : 6,
              height: index == _currentWordIndex ? 10 : 6,
              decoration: BoxDecoration(
                color: index <= _currentWordIndex ? tealAccent : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDistractionPhase() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: purpleAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: purpleAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_distractionTimeLeft}s remaining',
                  style: const TextStyle(
                    color: purpleAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Count backwards by 7',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Starting from:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            '$_countdownNumber',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: purpleAccent,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _countdownController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '${_countdownNumber - 7}',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: purpleAccent, width: 2),
                ),
              ),
              onSubmitted: (_) => _handleCountdownSubmit(),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _handleCountdownSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: purpleAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This keeps your mind busy',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallPhase() {
    return Column(
      children: [
        // Timer and count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: redAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_recallTimeLeft}s',
                    style: const TextStyle(
                      color: redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_recalledWords.length} words',
                style: const TextStyle(
                  color: greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _recallController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Type a word...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: tealAccent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _handleWordSubmit(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleWordSubmit,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tealAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Recalled words
        Expanded(
          child: _recalledWords.isEmpty
              ? Center(
                  child: Text(
                    'Type words you remember',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recalledWords.map((word) {
                    final isCorrect = _wordList.contains(word);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _removeWord(word),
                            child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 10),
        // Done button
        GestureDetector(
          onTap: _completeRecall,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Done Recalling',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedPhase() {
    final data = _getTestData();
    final correct = data['correct_count'] as int;
    final total = data['total_words'] as int;
    final accuracy = (data['accuracy'] * 100).toStringAsFixed(0);
    final intrusions = data['intrusion_errors'] as int;

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
                _buildResultRow('Words Recalled', '$correct / $total'),
                const Divider(height: 20),
                _buildResultRow('Accuracy', '$accuracy%'),
                const Divider(height: 20),
                _buildResultRow('Intrusion Errors', '$intrusions'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Show correct and missed words
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recalled correctly:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (data['correct_words'] as List).map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w,
                      style: const TextStyle(fontSize: 11, color: greenAccent, fontWeight: FontWeight.w600),
                    ),
                  )).toList(),
                ),
                if ((data['missed_words'] as List).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Missed:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (data['missed_words'] as List).map((w) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        w,
                        style: const TextStyle(fontSize: 11, color: redAccent, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ],
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