import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool agreeToTerms = false;
  bool isLoading = false;
  int currentStep = 0; // 0 = basic info, 1 = account details
  
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  
  late AnimationController _floatingController;
  late AnimationController _pageController;
  late AnimationController _pulseController;
  
  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;
  
  DateTime? selectedDate;
  String? selectedGender;
  
  int passwordStrength = 0;
  String passwordStrengthText = '';
  Color passwordStrengthColor = Colors.grey;

  // Design colors
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color creamBeige = Color(0xFFF5EBE0);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color orangeAccent = Color(0xFFF97316);
  static const Color redAccent = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
    _floatingController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Validations
  bool _validateFirstName(String name) {
    if (name.isEmpty) {
      setState(() => firstNameError = "First name is required");
      return false;
    }
    if (name.length < 2) {
      setState(() => firstNameError = "Name must be at least 2 characters");
      return false;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      setState(() => firstNameError = "Name can only contain letters");
      return false;
    }
    setState(() => firstNameError = null);
    return true;
  }

  bool _validateLastName(String name) {
    if (name.isEmpty) {
      setState(() => lastNameError = "Last name is required");
      return false;
    }
    if (name.length < 2) {
      setState(() => lastNameError = "Name must be at least 2 characters");
      return false;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      setState(() => lastNameError = "Name can only contain letters");
      return false;
    }
    setState(() => lastNameError = null);
    return true;
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return false;
    }
    
    // Comprehensive email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|org|net|edu|gov|mil|co|io|ai|pk|edu\.pk|gov\.pk|com\.pk|uk|co\.uk|de|fr|in|jp|au|ca|us|info|biz|xyz|app|dev|tech|online|site|web|cloud|email|mail|yahoo|gmail|hotmail|outlook)$',
      caseSensitive: false,
    );
    
    // Also check basic format
    final basicEmailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    
    if (!basicEmailRegex.hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email format");
      return false;
    }
    
    setState(() => emailError = null);
    return true;
  }

  bool _validatePhone(String phone) {
    if (phone.isEmpty) {
      setState(() => phoneError = "Phone number is required");
      return false;
    }
    
    // Remove spaces, dashes, and parentheses for validation
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it starts with + for international format
    if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }
    
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      setState(() => phoneError = "Enter a valid phone number (10-15 digits)");
      return false;
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      setState(() => phoneError = "Phone number can only contain digits");
      return false;
    }
    
    setState(() => phoneError = null);
    return true;
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        passwordStrength = 0;
        passwordStrengthText = '';
      });
      return;
    }

    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      passwordStrength = strength;
      if (strength <= 2) {
        passwordStrengthText = "Weak";
        passwordStrengthColor = redAccent;
      } else if (strength <= 4) {
        passwordStrengthText = "Medium";
        passwordStrengthColor = orangeAccent;
      } else {
        passwordStrengthText = "Strong";
        passwordStrengthColor = greenAccent;
      }
    });
  }

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      return false;
    }
    if (password.length < 8) {
      setState(() => passwordError = "Password must be at least 8 characters");
      return false;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => passwordError = "Password must contain an uppercase letter");
      return false;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      setState(() => passwordError = "Password must contain a lowercase letter");
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => passwordError = "Password must contain a number");
      return false;
    }
    setState(() => passwordError = null);
    return true;
  }

  bool _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Please confirm your password");
      return false;
    }
    if (confirmPassword != passwordController.text) {
      setState(() => confirmPasswordError = "Passwords do not match");
      return false;
    }
    setState(() => confirmPasswordError = null);
    return true;
  }

  bool _validateStep1() {
    bool isFirstNameValid = _validateFirstName(firstNameController.text.trim());
    bool isLastNameValid = _validateLastName(lastNameController.text.trim());
    bool isPhoneValid = _validatePhone(phoneController.text.trim());
    
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your date of birth'),
          backgroundColor: redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
    
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your gender'),
          backgroundColor: redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
    
    return isFirstNameValid && isLastNameValid && isPhoneValid;
  }

  bool _validateStep2() {
    bool isEmailValid = _validateEmail(emailController.text.trim());
    bool isPasswordValid = _validatePassword(passwordController.text);
    bool isConfirmPasswordValid = _validateConfirmPassword(confirmPasswordController.text);
    
    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions'),
          backgroundColor: redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
    
    return isEmailValid && isPasswordValid && isConfirmPasswordValid;
  }

  void _handleNextStep() {
    HapticFeedback.mediumImpact();
    
    if (currentStep == 0) {
      if (_validateStep1()) {
        setState(() => currentStep = 1);
      }
    } else {
      _handleSignUp();
    }
  }

  void _handlePreviousStep() {
    HapticFeedback.lightImpact();
    if (currentStep > 0) {
      setState(() => currentStep = 0);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSignUp() async {
    if (_validateStep2()) {
      setState(() => isLoading = true);
      
      await Future.delayed(const Duration(milliseconds: 2000));
      
      setState(() => isLoading = false);
      
      if (mounted) {
        // Navigate to OTP verification
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Min 13 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: darkCard,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildProgressIndicator(),
                          const SizedBox(height: 30),
                          _buildStepTitle(),
                          const SizedBox(height: 24),
                          _buildForm(),
                          const SizedBox(height: 30),
                          if (currentStep == 1) _buildSocialSection(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -60,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.sin(_floatingController.value * math.pi) * 15,
                  _floatingController.value * 30,
                ),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        currentStep == 0 ? softLavender : mintGreen,
                        (currentStep == 0 ? softLavender : mintGreen).withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -80,
          left: -50,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -math.cos(_floatingController.value * math.pi) * 20,
                  -_floatingController.value * 40,
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        currentStep == 0 ? mintGreen : creamBeige,
                        (currentStep == 0 ? mintGreen : creamBeige).withOpacity(0.2),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handlePreviousStep,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Step ${currentStep + 1} of 2",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              color: currentStep >= 1 ? darkCard : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentStep == 0 ? "Personal Information" : "Account Details",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentStep == 0
              ? "Tell us a bit about yourself"
              : "Create your secure account",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          if (currentStep == 0) ...[
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: "First Name",
                    hint: "John",
                    icon: Icons.person_outline_rounded,
                    controller: firstNameController,
                    focusNode: firstNameFocus,
                    errorText: firstNameError,
                    onChanged: (v) {
                      if (firstNameError != null) _validateFirstName(v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    label: "Last Name",
                    hint: "Doe",
                    icon: Icons.person_outline_rounded,
                    controller: lastNameController,
                    focusNode: lastNameFocus,
                    errorText: lastNameError,
                    onChanged: (v) {
                      if (lastNameError != null) _validateLastName(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            
            // Phone Number
            _buildInputField(
              label: "Phone Number",
              hint: "+92 300 1234567",
              icon: Icons.phone_outlined,
              controller: phoneController,
              focusNode: phoneFocus,
              errorText: phoneError,
              keyboardType: TextInputType.phone,
              onChanged: (v) {
                if (phoneError != null) _validatePhone(v);
              },
            ),
            const SizedBox(height: 18),
            
            // Date of Birth
            _buildDatePicker(),
            const SizedBox(height: 18),
            
            // Gender Selection
            _buildGenderSelector(),
          ] else ...[
            // Email
            _buildInputField(
              label: "Email Address",
              hint: "your.email@example.com",
              icon: Icons.email_outlined,
              controller: emailController,
              focusNode: emailFocus,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) {
                if (emailError != null) _validateEmail(v);
              },
            ),
            const SizedBox(height: 18),
            
            // Password
            _buildInputField(
              label: "Password",
              hint: "Create a strong password",
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              focusNode: passwordFocus,
              errorText: passwordError,
              isPassword: true,
              showPassword: showPassword,
              onTogglePassword: () => setState(() => showPassword = !showPassword),
              onChanged: (v) {
                _checkPasswordStrength(v);
                if (passwordError != null) _validatePassword(v);
              },
            ),
            
            // Password Strength Indicator
            if (passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPasswordStrengthIndicator(),
            ],
            const SizedBox(height: 18),
            
            // Confirm Password
            _buildInputField(
              label: "Confirm Password",
              hint: "Re-enter your password",
              icon: Icons.lock_outline_rounded,
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocus,
              errorText: confirmPasswordError,
              isPassword: true,
              showPassword: showConfirmPassword,
              onTogglePassword: () => setState(() => showConfirmPassword = !showConfirmPassword),
              onChanged: (v) {
                if (confirmPasswordError != null) _validateConfirmPassword(v);
              },
            ),
            const SizedBox(height: 20),
            
            // Terms & Conditions
            _buildTermsCheckbox(),
          ],
          
          const SizedBox(height: 28),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? errorText,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null
                  ? redAccent.withOpacity(0.5)
                  : Colors.black.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && !showPassword,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null ? redAccent : Colors.black.withOpacity(0.4),
                size: 20,
              ),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: onTogglePassword,
                      child: Icon(
                        showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.black.withOpacity(0.4),
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: redAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText,
                  style: TextStyle(color: redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.black.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : "Select your birth date",
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.black.withOpacity(0.25),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildGenderOption("Male", Icons.male_rounded),
            const SizedBox(width: 12),
            _buildGenderOption("Female", Icons.female_rounded),
            const SizedBox(width: 12),
            _buildGenderOption("Other", Icons.transgender_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => selectedGender = gender);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? darkCard : bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? darkCard : Colors.black.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black.withOpacity(0.4),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                gender,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: index < passwordStrength
                            ? passwordStrengthColor
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              passwordStrengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: passwordStrengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Use 8+ characters with uppercase, lowercase, numbers & symbols",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => agreeToTerms = !agreeToTerms);
      },
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: agreeToTerms ? darkCard : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: agreeToTerms ? darkCard : Colors.black.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: agreeToTerms
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: "I agree to the "),
                  TextSpan(
                    text: "Terms & Conditions",
                    style: TextStyle(
                      color: blueAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: TextStyle(
                      color: blueAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: isLoading ? null : _handleNextStep,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkCard, darkCard.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: darkCard.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(mintGreen),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentStep == 0 ? "Continue" : "Create Account",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      currentStep == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Or sign up with",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(child: _buildGoogleLogo(), onTap: () {}),
            const SizedBox(width: 16),
            _buildSocialButton(
              child: const Icon(Icons.apple_rounded, color: Colors.white, size: 28),
              backgroundColor: Colors.black,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              child: const Text('f', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              backgroundColor: const Color(0xFF1877F2),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account? ",
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: darkCard, width: 2)),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    Color backgroundColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: backgroundColor == Colors.white
              ? Border.all(color: Colors.black.withOpacity(0.08), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: backgroundColor == Colors.white
                  ? Colors.black.withOpacity(0.04)
                  : backgroundColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return CustomPaint(
      size: const Size(24, 24),
      painter: GoogleLogoPainter(),
    );
  }
}

// Google Logo Painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 4,
      -math.pi / 2,
      false,
      bluePaint,
    );
    
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi / 4,
      math.pi / 2,
      false,
      greenPaint,
    );
    
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi * 3 / 4,
      math.pi / 2,
      false,
      yellowPaint,
    );
    
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi * 3 / 4,
      -math.pi / 2,
      false,
      redPaint,
    );
    
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius - 2, center.dy),
      bluePaint..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}