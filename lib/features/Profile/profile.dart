import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroverse/core/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pageController;
  int _selectedNavIndex = 4;

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Design colors matching home screen
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color creamBeige = Color(0xFFF5EBE0);
  static const Color softYellow = Color(0xFFFFF3CD);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color navBg = Color(0xFFFAFAFA);
  static const Color blueAccent = Color(0xFF3B82F6);

  String _memberSince = "";
  int _totalTestsCompleted = 0;
  int _testsThisWeek = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    _loadUserData();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getUserProfile();
    final dashResult = await ApiService.getUserDashboard();

    if (mounted) {
      setState(() {
        _isLoading = false;

        if (result['success']) {
          final data = result['data'];
          _userData = data;

          if (data['created_at'] != null) {
            final date = DateTime.parse(data['created_at']);
            _memberSince = "${_monthName(date.month)} ${date.year}";
          }
        }

        if (dashResult['success']) {
          final dash = dashResult['data'];
          _totalTestsCompleted = dash['total_tests_completed'] ?? 0;
          _testsThisWeek = dash['tests_this_week'] ?? 0;
          _streak = dash['streak'] ?? dash['wellness_streak'] ?? 0;
        }
      });
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    HapticFeedback.selectionClick();
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/tests');
        break;
      case 2:
        Navigator.pushNamed(context, '/reports');
        break;
      case 3:
        Navigator.pushNamed(context, '/XAI');
        break;
      case 4:
        setState(() => _selectedNavIndex = index);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildProfileAvatar(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildPremiumCard(),
              const SizedBox(height: 24),
              _buildSettingsMenu(),
              const SizedBox(height: 20),
              _buildSignOutButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return _buildAnimatedWidget(
      delay: 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            // Empty container for balance (removed ... button)
            const SizedBox(width: 44, height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final firstName = _userData?['first_name'] ?? 'User';
    final lastName = _userData?['last_name'] ?? '';
    final email = _userData?['email'] ?? 'user@email.com';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    return _buildAnimatedWidget(
      delay: 0.1,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: darkCard.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: (_userData?['profile_image_path'] != null &&
                          _userData!['profile_image_path'].toString().isNotEmpty)
                      ? Image.network(
                          "${ApiService.baseUrl}/${_userData!['profile_image_path']}",
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (_userData?['is_verified'] ?? false) ? blueAccent : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: bgColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: blueAccent.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return _buildAnimatedWidget(
      delay: 0.15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.assignment_turned_in_outlined,
                value: '$_totalTestsCompleted',
                label: 'Tests\nCompleted',
                iconBg: mintGreen,
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.local_fire_department_rounded,
                value: '$_streak days',
                label: 'Current\nStreak',
                iconBg: softLavender,
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.calendar_month_rounded,
                value: _memberSince.isNotEmpty ? _memberSince : 'N/A',
                label: 'Member\nSince',
                iconBg: creamBeige,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconBg,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.5),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.black.withOpacity(0.08),
    );
  }

  Widget _buildPremiumCard() {
    return _buildAnimatedWidget(
      delay: 0.2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: darkCard.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: mintGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Premium Member',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mintGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Unlimited access to all features',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Manage Subscription',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return _buildAnimatedWidget(
      delay: 0.25,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                iconBgColor: blueAccent,
                isFirst: true,
                onTap: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                iconBgColor: const Color(0xFFF97316),
                onTap: () => _showPrivacySheet(),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                iconBgColor: const Color(0xFF8B5CF6),
                onTap: () => _showTermsDialog(),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                iconBgColor: const Color(0xFF10B981),
                onTap: () => _showPrivacyPolicyDialog(),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                iconBgColor: blueAccent,
                onTap: () => _showHelpSheet(),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                iconBgColor: const Color(0xFF6B7280),
                isLast: true,
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildPrivacyOption(Icons.fingerprint_rounded, 'Biometric Login', 'Use fingerprint or face ID'),
                  _buildPrivacyOption(Icons.lock_outline_rounded, 'Change Password', 'Update your password'),
                  _buildPrivacyOption(Icons.visibility_off_outlined, 'Data Visibility', 'Control who sees your data'),
                  _buildPrivacyOption(Icons.delete_outline_rounded, 'Delete Account', 'Permanently remove your data'),
                  _buildPrivacyOption(Icons.download_outlined, 'Export Data', 'Download your health data'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: Colors.black54),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildHelpOption(
              Icons.quiz_outlined, 
              'FAQs', 
              'Common questions answered',
              onTap: () {
                Navigator.pop(context);
                _navigateToFAQs();
              },
            ),
            _buildHelpOption(
              Icons.support_agent_rounded, 
              'Contact Support', 
              'Get help from our team',
              onTap: () {
                Navigator.pop(context);
                _navigateToContactSupport();
              },
            ),
            _buildHelpOption(
              Icons.menu_book_rounded, 
              'User Guide', 
              'Learn how to use the app',
              onTap: () {
                Navigator.pop(context);
                _navigateToUserGuide();
              },
            ),
            _buildHelpOption(
              Icons.feedback_outlined, 
              'Submit Feedback', 
              'Help us improve the app',
              onTap: () {
                Navigator.pop(context);
                _navigateToSubmitFeedback();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: blueAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // Navigate to FAQs Screen
  void _navigateToFAQs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQsScreen()),
    );
  }

  // Navigate to Contact Support Screen
  void _navigateToContactSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
    );
  }

  // Navigate to User Guide Screen
  void _navigateToUserGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserGuideScreen()),
    );
  }

  // Navigate to Submit Feedback Screen
  void _navigateToSubmitFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmitFeedbackScreen()),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        '1. Medical Disclaimer',
                        'NeuroVerse is a screening tool designed to assist in early detection of neurological conditions. This app does NOT provide medical diagnosis. Results should be reviewed by qualified healthcare professionals. Never disregard professional medical advice based on app results.',
                      ),
                      _buildTermsSection(
                        '2. Data Collection & Usage',
                        'We collect neurological assessment data including speech patterns, motor function measurements, cognitive test results, and digital wellness metrics. This data is encrypted using AES-256 encryption and stored securely on HIPAA-compliant servers.',
                      ),
                      _buildTermsSection(
                        '3. AI & Machine Learning',
                        'Our AI models analyze your assessment data to generate risk scores. These models are trained on anonymized clinical data and are continuously improved. AI predictions have accuracy limitations and should not replace clinical evaluation.',
                      ),
                      _buildTermsSection(
                        '4. Research Participation',
                        'Anonymized data may be used for neurodegenerative disease research to improve detection algorithms. You can opt-out of research participation in Privacy Settings without affecting app functionality.',
                      ),
                      _buildTermsSection(
                        '5. User Responsibilities',
                        'You agree to provide accurate information, complete assessments as instructed, and use the app for its intended purpose. Misuse of the app or manipulation of results is prohibited.',
                      ),
                      _buildTermsSection(
                        '6. Limitation of Liability',
                        'NeuroVerse and its developers are not liable for any decisions made based on app results. The app is provided "as is" without warranties of any kind.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'I Understand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        '1. Information We Collect',
                        '• Personal Information: Name, email, phone, date of birth\n• Health Data: Assessment results, risk scores, test recordings\n• Device Data: Device type, OS version, app usage analytics\n• Digital Wellness: Screen time (with permission)',
                      ),
                      _buildTermsSection(
                        '2. How We Use Your Data',
                        '• Generate personalized health risk assessments\n• Improve AI detection algorithms\n• Send important health notifications\n• Provide customer support\n• Conduct anonymized medical research',
                      ),
                      _buildTermsSection(
                        '3. Data Storage & Security',
                        'All data is encrypted in transit (TLS 1.3) and at rest (AES-256). We use HIPAA-compliant cloud infrastructure. Data is stored for the duration of your account unless deletion is requested.',
                      ),
                      _buildTermsSection(
                        '4. Data Sharing',
                        'We do NOT sell your personal data. Data may be shared with:\n• Healthcare providers (with your consent)\n• Research institutions (anonymized only)\n• Legal authorities (when required by law)',
                      ),
                      _buildTermsSection(
                        '5. Your Rights',
                        '• Access your data anytime\n• Request data deletion\n• Export your health records\n• Opt-out of research participation\n• Update or correct your information',
                      ),
                      _buildTermsSection(
                        '6. Contact Us',
                        'For privacy concerns or data requests:\nEmail: privacy@neuroverse.pk\nPhone: +92 300 1234567',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: BrainLogoPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'NeuroVerse',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AI-powered neurological health screening for early detection of Alzheimer\'s and Parkinson\'s disease.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconBgColor,
    String? badge,
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(24) : Radius.zero,
            bottom: isLast ? const Radius.circular(24) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconBgColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.black.withOpacity(0.06),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return _buildAnimatedWidget(
      delay: 0.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.mediumImpact();
            await ApiService.logout();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFCA5A5).withOpacity(0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Color(0xFFDC2626),
                ),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.assignment_outlined, 'Tests'),
              _buildNavItem(2, Icons.analytics_outlined, 'Reports'),
              _buildNavItem(3, Icons.auto_awesome_rounded, 'XAI'),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? darkCard : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black38,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _pageController,
        curve: Interval(delay, math.min(delay + 0.3, 1.0), curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _pageController,
          curve: Interval(delay, math.min(delay + 0.3, 1.0), curve: Curves.easeOut),
        )),
        child: child,
      ),
    );
  }
}

// ==================== FAQs Screen ====================
class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color mintGreen = Color(0xFFB8E8D1);

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is NeuroVerse?',
      'answer': 'NeuroVerse is an AI-powered mobile application designed to screen for early signs of neurodegenerative diseases like Parkinson\'s and Alzheimer\'s. It uses advanced machine learning algorithms to analyze speech patterns, motor functions, cognitive abilities, and gait movements.'
    },
    {
      'question': 'Is NeuroVerse a medical diagnostic tool?',
      'answer': 'No, NeuroVerse is a screening tool, not a diagnostic device. It helps identify potential risk factors and early indicators that should be discussed with healthcare professionals. Always consult a qualified doctor for proper medical diagnosis.'
    },
    {
      'question': 'How accurate are the test results?',
      'answer': 'Our AI models have been trained on clinical data and achieve high accuracy rates. However, results should be considered as indicators, not definitive diagnoses. Factors like device quality, environment, and user compliance can affect results.'
    },
    {
      'question': 'How often should I take the tests?',
      'answer': 'We recommend taking comprehensive tests once a week for consistent monitoring. Regular testing helps establish your baseline and track any changes over time. Quick daily check-ins are also available for routine monitoring.'
    },
    {
      'question': 'What data does the app collect?',
      'answer': 'NeuroVerse collects voice recordings (for speech analysis), finger movement data, cognitive test responses, walking pattern data from sensors, and digital wellness metrics. All data is encrypted and stored securely.'
    },
    {
      'question': 'Is my health data secure?',
      'answer': 'Yes, we take data security very seriously. All data is encrypted using AES-256 encryption both in transit and at rest. We use HIPAA-compliant cloud infrastructure and never sell your personal health information.'
    },
    {
      'question': 'Can I delete my data?',
      'answer': 'Yes, you can request complete data deletion anytime from Privacy & Security settings. Once requested, all your personal data and test results will be permanently removed within 30 days.'
    },
    {
      'question': 'What is XAI (Explainable AI)?',
      'answer': 'XAI is our transparency feature that shows you exactly why the AI made certain predictions. It highlights which factors contributed most to your risk scores, helping you understand your results better.'
    },
    {
      'question': 'How does the Speech Analysis test work?',
      'answer': 'The speech test analyzes various vocal biomarkers including voice tremor, pitch variations, speech rate, and pronunciation clarity. You\'ll be asked to read specific passages, sustain vowel sounds, and describe images.'
    },
    {
      'question': 'What is tested in Motor Functions?',
      'answer': 'Motor function tests assess fine motor control through tasks like finger tapping, spiral drawing, and hand movement tracking. These tests detect subtle changes in coordination, speed, and steadiness.'
    },
    {
      'question': 'How does Cognitive Assessment work?',
      'answer': 'Cognitive tests evaluate memory, attention, processing speed, and executive function through interactive games and puzzles. Tasks include word recall, pattern recognition, and problem-solving exercises.'
    },
    {
      'question': 'What does Gait Analysis measure?',
      'answer': 'Gait analysis uses your phone\'s sensors to measure walking patterns including step length, walking speed, balance, and rhythm. Changes in gait can be early indicators of neurological conditions.'
    },
    {
      'question': 'What do the risk scores mean?',
      'answer': 'Risk scores range from 0-100 and indicate the likelihood of neurological decline indicators. Low (0-30) suggests minimal risk, Moderate (31-60) warrants monitoring, High (61-80) recommends professional consultation, and Critical (81-100) suggests urgent medical attention.'
    },
    {
      'question': 'Can I share my reports with my doctor?',
      'answer': 'Yes! You can export detailed PDF reports from the Reports section. These comprehensive reports include test results, trend analysis, and XAI explanations that can help healthcare providers understand your health status.'
    },
    {
      'question': 'What is Digital Wellness tracking?',
      'answer': 'Digital Wellness monitors your screen time, sleep patterns, and physical activity. Research shows these lifestyle factors can impact neurological health. We help you maintain healthy habits that support brain health.'
    },
    {
      'question': 'Does the app work offline?',
      'answer': 'Basic test-taking works offline, but results sync when connected. Full functionality including AI analysis, report generation, and data backup requires an internet connection.'
    },
    {
      'question': 'What devices are supported?',
      'answer': 'NeuroVerse works on iOS (iPhone 8 and newer) and Android (version 8.0+) devices. Some tests require specific sensor capabilities which most modern smartphones have.'
    },
    {
      'question': 'How do I cancel my premium subscription?',
      'answer': 'You can cancel your subscription anytime through your device\'s app store (Google Play or Apple App Store) subscription settings. You\'ll retain premium access until the end of your billing period.'
    },
    {
      'question': 'Can family members use the same account?',
      'answer': 'Each person should have their own account for accurate health tracking. Test results are personalized, and mixing data from different individuals would compromise the accuracy of AI predictions.'
    },
    {
      'question': 'How do I contact support for technical issues?',
      'answer': 'You can reach our support team via Contact Support in Help & Support section. For technical issues, email tech.support@neuro.pk. Our team typically responds within 24-48 hours.'
    },
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _faqs.length,
                itemBuilder: (context, index) => _buildFAQItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? blueAccent.withOpacity(0.3) : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExpanded ? blueAccent.withOpacity(0.1) : mintGreen.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isExpanded ? blueAccent : darkCard,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq['question']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isExpanded ? blueAccent : Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? blueAccent : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ==================== Contact Support Screen ====================
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color softYellow = Color(0xFFFFF3CD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              
              // General Support Section
              _buildSectionTitle('General Support'),
              _buildContactCard(
                context,
                icon: Icons.support_agent_rounded,
                iconBg: blueAccent,
                name: 'Help Desk',
                role: 'General Inquiries & Support',
                email: 'help.desk@neuro.pk',
                description: 'For general questions, account issues, subscription queries, and basic app support.',
              ),
              
              // Technical Support Section
              _buildSectionTitle('Technical Support'),
              _buildContactCard(
                context,
                icon: Icons.code_rounded,
                iconBg: const Color(0xFF10B981),
                name: 'Muhammad Naeem',
                role: 'Lead Developer - Backend & AI',
                email: 'naeem.dev@neuro.pk',
                description: 'For API issues, data sync problems, AI prediction queries, and backend-related bugs.',
              ),
              _buildContactCard(
                context,
                icon: Icons.phone_android_rounded,
                iconBg: const Color(0xFF8B5CF6),
                name: 'Bilal Hassan',
                role: 'Lead Developer - Mobile & Frontend',
                email: 'bilal.dev@neuro.pk',
                description: 'For app crashes, UI/UX issues, test recording problems, and mobile app bugs.',
              ),
              
              // Other Issues Section
              _buildSectionTitle('Other Issues'),
              _buildContactCard(
                context,
                icon: Icons.business_center_rounded,
                iconBg: const Color(0xFFF97316),
                name: 'Haider Abbas',
                role: 'Project Coordinator',
                email: 'haider.support@neuro.pk',
                description: 'For partnership inquiries, feedback escalation, account recovery, and non-technical concerns.',
              ),
              
              // Response Time Notice
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: softYellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFEAB308),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Response Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We typically respond within 24-48 hours during business days. Urgent issues are prioritized.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String name,
    required String role,
    required String email,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: iconBg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: iconBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Copy email to clipboard
                Clipboard.setData(ClipboardData(text: email));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Email copied: $email'),
                    backgroundColor: darkCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconBg.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: iconBg),
                    const SizedBox(width: 8),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconBg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded, size: 16, color: iconBg.withOpacity(0.7)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== User Guide Screen ====================
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color creamBeige = Color(0xFFF5EBE0);
  static const Color softYellow = Color(0xFFFFF3CD);

  final List<Map<String, dynamic>> _guides = const [
    {
      'icon': Icons.home_rounded,
      'title': 'Dashboard Overview',
      'color': Color(0xFF3B82F6),
      'steps': [
        'View your overall health risk score at the top',
        'Check individual category scores (Speech, Motor, Cognitive, Gait)',
        'See your recent test history',
        'Track your daily streak and wellness metrics',
        'Quick access to start new tests',
      ],
    },
    {
      'icon': Icons.mic_rounded,
      'title': 'Taking Speech Tests',
      'color': Color(0xFF10B981),
      'steps': [
        'Find a quiet environment with minimal background noise',
        'Hold your phone 6-8 inches from your mouth',
        'Speak clearly at your normal pace',
        'Follow on-screen prompts (reading passages, sustained vowels)',
        'Wait for the recording indicator before speaking',
        'Review and retry if the recording quality is poor',
      ],
    },
    {
      'icon': Icons.touch_app_rounded,
      'title': 'Motor Function Tests',
      'color': Color(0xFF8B5CF6),
      'steps': [
        'Sit comfortably with your phone on a stable surface',
        'For tapping tests: Tap alternating buttons as fast as possible',
        'For spiral drawing: Start from center, draw smoothly',
        'Keep your wrist steady, move only fingers',
        'Complete all trials for accurate results',
      ],
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'Cognitive Assessments',
      'color': Color(0xFFF97316),
      'steps': [
        'Take tests when you\'re alert and focused',
        'Read instructions carefully before starting',
        'For memory tests: Pay attention during the learning phase',
        'For pattern tests: Look for visual/logical sequences',
        'Don\'t rush - accuracy matters more than speed',
      ],
    },
    {
      'icon': Icons.directions_walk_rounded,
      'title': 'Gait Analysis Tests',
      'color': Color(0xFFEF4444),
      'steps': [
        'Place phone in front pocket or hold at waist level',
        'Walk in a clear, straight path (10+ meters ideal)',
        'Walk at your normal comfortable pace',
        'Avoid holding onto objects while walking',
        'Complete multiple walking trials as prompted',
      ],
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Understanding XAI Results',
      'color': Color(0xFF6366F1),
      'steps': [
        'XAI shows which factors influenced your score',
        'Green indicators = positive contributions',
        'Red indicators = areas of concern',
        'Review feature importance charts',
        'Use insights to discuss with your doctor',
      ],
    },
    {
      'icon': Icons.analytics_rounded,
      'title': 'Viewing Reports',
      'color': Color(0xFF0EA5E9),
      'steps': [
        'Access detailed reports from Reports tab',
        'View trend graphs showing progress over time',
        'Export PDF reports for healthcare providers',
        'Compare results across different test dates',
        'Set up weekly/monthly report reminders',
      ],
    },
    {
      'icon': Icons.spa_rounded,
      'title': 'Digital Wellness Tracking',
      'color': Color(0xFF14B8A6),
      'steps': [
        'Grant screen time access for accurate tracking',
        'Set daily goals for screen time, sleep, and activity',
        'Log your sleep duration and quality daily',
        'Track physical activity and steps',
        'Review weekly patterns and insights',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: _guides.length,
                itemBuilder: (context, index) => _buildGuideCard(_guides[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'User Guide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    final color = guide['color'] as Color;
    final steps = guide['steps'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(guide['icon'] as IconData, size: 24, color: color),
          ),
          title: Text(
            guide['title'] as String,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          iconColor: Colors.black38,
          collapsedIconColor: Colors.black38,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.7),
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
      ),
    );
  }
}

// ==================== Submit Feedback Screen ====================
class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color mintGreen = Color(0xFFB8E8D1);

  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  int _rating = 0;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'UI/UX Improvement',
    'Test Quality',
    'Performance Issue',
    'Other',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your feedback'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Connect to backend API
    // await ApiService.submitFeedback({
    //   'category': _selectedCategory,
    //   'rating': _rating,
    //   'message': _feedbackController.text.trim(),
    // });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Section
                    _buildSectionLabel('How would you rate your experience?'),
                    const SizedBox(height: 12),
                    _buildRatingSelector(),
                    const SizedBox(height: 28),

                    // Category Section
                    _buildSectionLabel('Feedback Category'),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),
                    const SizedBox(height: 28),

                    // Feedback Text Section
                    _buildSectionLabel('Your Feedback'),
                    const SizedBox(height: 12),
                    _buildFeedbackInput(),
                    const SizedBox(height: 28),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Submit Feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          final isSelected = starIndex <= _rating;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _rating = starIndex);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: isSelected ? const Color(0xFFFBBF24) : Colors.black26,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? blueAccent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? blueAccent : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _feedbackController,
        maxLines: 6,
        maxLength: 1000,
        decoration: InputDecoration(
          hintText: 'Tell us what you think about NeuroVerse...\n\nYour feedback helps us improve the app for everyone.',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 14,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          counterStyle: TextStyle(
            color: Colors.black.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitFeedback,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isSubmitting ? Colors.black38 : darkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: darkCard.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              _isSubmitting ? 'Submitting...' : 'Submit Feedback',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Brain Logo Painter ====================
class BrainLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8E8D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Left hemisphere
    final leftPath = Path();
    leftPath.moveTo(centerX - 2, centerY - size.height * 0.35);
    leftPath.cubicTo(
      centerX - size.width * 0.4, centerY - size.height * 0.3,
      centerX - size.width * 0.45, centerY + size.height * 0.2,
      centerX - 2, centerY + size.height * 0.35,
    );
    canvas.drawPath(leftPath, paint);

    // Right hemisphere
    final rightPath = Path();
    rightPath.moveTo(centerX + 2, centerY - size.height * 0.35);
    rightPath.cubicTo(
      centerX + size.width * 0.4, centerY - size.height * 0.3,
      centerX + size.width * 0.45, centerY + size.height * 0.2,
      centerX + 2, centerY + size.height * 0.35,
    );
    canvas.drawPath(rightPath, paint);

    // Center line
    canvas.drawLine(
      Offset(centerX, centerY - size.height * 0.3),
      Offset(centerX, centerY + size.height * 0.3),
      paint,
    );

    // Neural connections
    paint.strokeWidth = 1.5;
    
    // Left side connections
    canvas.drawLine(
      Offset(centerX - size.width * 0.15, centerY - size.height * 0.1),
      Offset(centerX - size.width * 0.3, centerY - size.height * 0.15),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - size.width * 0.15, centerY + size.height * 0.1),
      Offset(centerX - size.width * 0.3, centerY + size.height * 0.15),
      paint,
    );

    // Right side connections
    canvas.drawLine(
      Offset(centerX + size.width * 0.15, centerY - size.height * 0.1),
      Offset(centerX + size.width * 0.3, centerY - size.height * 0.15),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.15, centerY + size.height * 0.1),
      Offset(centerX + size.width * 0.3, centerY + size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}