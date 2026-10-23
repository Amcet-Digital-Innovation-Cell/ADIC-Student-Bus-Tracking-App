import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'theme_controller.dart';

class LoginScreen extends StatefulWidget {
  final String? initialErrorMessage;
  const LoginScreen({super.key, this.initialErrorMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final AnimationController _cardRevealController;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;

  // Login Controllers
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _activationkeyController = TextEditingController();
  final FocusNode _studentIdFocus = FocusNode();
  final FocusNode _activationFocus = FocusNode();

  // Registration Controllers
  final TextEditingController _regStudentIdController = TextEditingController();
  final TextEditingController _regStudentNameController = TextEditingController();
  final TextEditingController _regYearController = TextEditingController();
  final TextEditingController _studentMobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  final FocusNode _regStudentIdFocus = FocusNode();
  final FocusNode _regStudentNameFocus = FocusNode(); // <-- ADD THIS
  final FocusNode _regYearFocus = FocusNode();
  final FocusNode _studentMobileFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _parentNameFocus = FocusNode();
  final FocusNode _parentPhoneFocus = FocusNode();

  String? _selectedDepartment;
  final List<String> _departments = const [
    'B.E - Computer Science and Engineering',
    'B.E - Electronics and Communication Engineering',
    'B.E - Electrical and Electronics Engineering',
    'B.E - Mechanical Engineering',
    'B.E - Civil Engineering',
    'B.Tech - Artificial Intelligence and Data Science',
    'B.Tech - Information Technology',
  ];

  // Route Dropdown state
  List<String> _busRoutes = [];
String? _selectedRoute;
bool _isRouteDropdownOpen = false;
bool _isLoadingRoutes = false;

  // 0: LOGIN, 1: REGISTRATION
  int _activeVerticalTabIndex = 0;

  bool _isLoading = false;
  bool _isAutoFetching = false;
  bool _isStudentVerified = false;
  bool _isDepartmentDropdownOpen = false;
  String? _errorMessage;

  static const Color _deepBackground = Color(0xFF040A12);
  static const double _targetLogoSize = 76.0;

  @override
  void initState() {
    super.initState();

    if (widget.initialErrorMessage != null) {
      _errorMessage = widget.initialErrorMessage;
    }
    
    _loadBusRoutes();

    _cardRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardFadeAnim = CurvedAnimation(
      parent: _cardRevealController,
      curve: Curves.easeOutCubic,
    );

    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardRevealController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardRevealController.forward();
    });
  }
  
  Future<void> _loadBusRoutes() async {
    setState(() => _isLoadingRoutes = true);
    final routes = await ApiService.fetchBusRoutesList();
    if (!mounted) return;

    final routeNames = <String>[];
    for (final route in routes) {
      final routeMap = route as Map<String, dynamic>;
      final routeName = routeMap['route_name'] ??
          routeMap['name'] ??
          routeMap['routeName'] ??
          routeMap['bus_route'] ??
          routeMap['route'];
      if (routeName != null && routeName.toString().trim().isNotEmpty) {
        routeNames.add(routeName.toString());
      }
    }

    setState(() {
      _busRoutes = routeNames;
      _isLoadingRoutes = false;
    });
  }

  @override
  void dispose() {
    _cardRevealController.dispose();
    _studentIdController.dispose();
    _activationkeyController.dispose();
    _studentIdFocus.dispose();
    _activationFocus.dispose();

    _regStudentIdController.dispose();
    _regStudentNameController.dispose();
    _regYearController.dispose();
    _studentMobileController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();

    _regStudentIdFocus.dispose();
    _regStudentNameFocus.dispose();
    _regYearFocus.dispose();
    _studentMobileFocus.dispose();
    _emailFocus.dispose();
    _parentNameFocus.dispose();
    _parentPhoneFocus.dispose();
    super.dispose();
  }

  // Step 1: Auto-Fetch student Name & Year
  Future<void> _fetchStudentDetails(String studentId) async {
    final cleanId = studentId.trim().toUpperCase();
    if (cleanId.length < 5) return;

    setState(() {
      _isAutoFetching = true;
      _errorMessage = null;
      _isStudentVerified = false; // Reset verification state
    });

    final result = await ApiService.fetchStudentPreview(cleanId);

if (result['success'] == true &&
        (result['studentname'] as String).trim().isNotEmpty &&
        (result['year'] as String).trim().isNotEmpty) {
      setState(() {
        _regStudentNameController.text = result['studentname'];
        _regYearController.text = result['year'];
        _isStudentVerified = true; // Verified successfully
      });
      FocusScope.of(context).requestFocus(_studentMobileFocus);
    } else {
      // Reject non-verified students
      setState(() {
        _isStudentVerified = false;
        _regStudentNameController.clear();
        _regYearController.clear();
        _errorMessage = result['error'] ?? 'Student record not found in college database.';
      });
      _showBottomErrorSnackBar(_errorMessage!);
    }
  
  }

  // Step 2: Form validation & Registration submission
  Future<void> _handleRegistration() async {
    debugPrint('--- [REGISTER BUTTON TAPPED] ---');

    final studentId = _regStudentIdController.text.trim().toUpperCase();
    final studentName = _regStudentNameController.text.trim();
    final academicYear = _regYearController.text.trim();
    final studentMobile = _studentMobileController.text.trim();
    final email = _emailController.text.trim();
    final parentName = _parentNameController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();

    debugPrint('Field Check: ID=$studentId, Name=$studentName, Year=$academicYear, Dept=$_selectedDepartment, Route=$_selectedRoute');

    if (studentId.isEmpty) {
      debugPrint('Validation failed: Student ID empty');
      _showBottomErrorSnackBar('Please enter/scan Student ID.');
      return;
    }
    if (studentName.isEmpty) {
      debugPrint('Validation failed: Student Name empty');
      _showBottomErrorSnackBar('Please enter Student Name.');
      return;
    }
    if (academicYear.isEmpty) {
      debugPrint('Validation failed: Academic Year empty');
      _showBottomErrorSnackBar('Please enter Year of Study.');
      return;
    }
    if (_selectedDepartment == null) {
      debugPrint('Validation failed: Department not selected');
      _showBottomErrorSnackBar('Please select your department from dropdown.');
      return;
    }
    if (_selectedRoute == null|| _selectedRoute!.isEmpty) {
      debugPrint('Validation failed: Bus route not selected');
      _showBottomErrorSnackBar('Please select a bus route from dropdown.');
      return;
    }

    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    if (!mobileRegex.hasMatch(studentMobile)) {
      debugPrint('Validation failed: Student mobile ($studentMobile) invalid');
      _showBottomErrorSnackBar('Enter a valid 10-digit Indian mobile number of Student.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      debugPrint('Validation failed: Email ($email) invalid');
      _showBottomErrorSnackBar('Enter a valid email address.');
      return;
    }

    if (parentName.isEmpty) {
      debugPrint('Validation failed: Parent name empty');
      _showBottomErrorSnackBar('Please enter parent name.');
      return;
    }

    if (!mobileRegex.hasMatch(parentPhone)) {
      debugPrint('Validation failed: Parent mobile ($parentPhone) invalid');
      _showBottomErrorSnackBar('Enter a valid 10-digit Indian mobile number of Parent.');
      return;
    }
    // Block non-verified students
    if (!_isStudentVerified || studentName.isEmpty || academicYear.isEmpty) {
      _showBottomErrorSnackBar('Student verification failed. Only pre-enrolled AMCET students can register.');
      return;
    }

    debugPrint('All validations passed! Calling ApiService.registerStudent...');

    setState(() {
      _isLoading = true;
    });

    debugPrint('Submitting registration details...');

  try {
    final result = await ApiService.registerStudent(
      studentId: studentId,
      studentName: studentName,
      academicYear: academicYear,
      department: _selectedDepartment!,
      studentMobile: studentMobile,
      email: email,
      parentName: parentName,
      parentPhone: parentPhone,
      routeName:_selectedRoute!,
    );

    debugPrint('Registration Result from API: $result');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
  _showRegistrationSuccessDialog(studentId);
} else {
  final errorMsg = result['error']?.toString() ?? 'Registration failed.';
  
  if (errorMsg.contains('already registered')) {
    _showAlreadyRegisteredDialog(studentId);
  } else {
    _showBottomSnackBar(errorMsg);
  }
}
  } catch (err, stack) {
    debugPrint('Exception in _handleRegistration: $err');
    debugPrint('Stack: $stack');
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showBottomErrorSnackBar('An unexpected error occurred: $err');
  }
}

void _showBottomSnackBar(String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF0F3648),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}

  void _showRegistrationSuccessDialog(String registeredId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF091B28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 24),
            SizedBox(width: 8),
            Text(
              'REGISTRATION SUCCESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        content: const Text(
          'Registered Successfully!\n\nThe password has been sent to your registered email.\n\nPlease log in with it.',
          style: TextStyle(color: Color(0xFFBACFE6), fontSize: 13, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // 1. Close the popup
              Navigator.pop(context);

              // 2. Switch tab to LOGIN (0) and pre-fill the registered student ID
              setState(() {
                _activeVerticalTabIndex = 0;
                _studentIdController.text = registeredId;
                _errorMessage = null;
              });
              // 3. Immediately focus the Password / Activation Key field
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FocusScope.of(context).requestFocus(_activationFocus);
              }
            });
            },
            child: const Text(
              'PROCEED TO LOGIN',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Login Handler
  Future<void> _handleLogin() async {
    final studentId = _studentIdController.text.trim().toUpperCase();
    final activationkey = _activationkeyController.text.trim();

    if (studentId.isEmpty || activationkey.isEmpty) {
      debugPrint('Validation failed: Student ID or Password empty');
      setState(() => _errorMessage = 'enter student id and Passwork key.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.loginStudent(
      studentId: studentId,
      activationkey: activationkey,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        smoothPageRoute(page: const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['error']?.toString() ?? 'login failed.';
      });
    }
  }

  Future<void> _openScanner({required bool isRegistration}) async {
    final scannedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (scannedResult != null && scannedResult.isNotEmpty && mounted) {
      final clean = scannedResult.toUpperCase();
      if (isRegistration) {
        setState(() => _regStudentIdController.text = clean);
        _fetchStudentDetails(clean);
      } else {
        setState(() => _studentIdController.text = clean);
        FocusScope.of(context).requestFocus(_activationFocus);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Student ID filled: $clean',
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _deepBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _deepBackground,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StaticDiagonalSlitsPainter(),
                ),
              ),
            ),
            SafeArea(
            child: SmoothKeyboardLayout(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuad,
                        height: isKeyboardOpen ? 46.0 : _targetLogoSize,
                        width: isKeyboardOpen ? 46.0 : _targetLogoSize,
                        child: Hero(
                          tag: 'app_college_logo',
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.directions_bus_filled_rounded,
                              size: 54,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SlideTransition(
                        position: _cardSlideAnim,
                        child: FadeTransition(
                          opacity: _cardFadeAnim,
                          child: Column(
                            children: [
                              const Text(
                                'AMCET BUS TRACKING',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ANNAI MIRA COLLEGE OF ENGINEERING & TECHNOLOGY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Georgia',
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFrostedCard(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildVerticalTabBar(),
                                    const SizedBox(height: 18),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      child: _activeVerticalTabIndex == 0
                                          ? _buildloginFields()
                                          : _buildRegistrationFields(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildVerticalTabBar() {
    return Column(
      children: [
        _buildPillTabItem(
          index: 0,
          title: 'LOGIN',
          icon: Icons.badge_rounded,
        ),
        const SizedBox(height: 5),
        _buildPillTabItem(
          index: 1,
          title: 'REGISTRATION',
          icon: Icons.app_registration_rounded,
        ),
      ],
    );
  }

  Widget _buildPillTabItem({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = _activeVerticalTabIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _activeVerticalTabIndex = index;
            _errorMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 38,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromARGB(255, 1, 70, 109),
                      Color(0xFF041829),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color.fromARGB(28, 0, 0, 0).withValues(alpha: 0.35),
                      const Color.fromARGB(255, 5, 18, 28).withValues(alpha: 0.30),
                    ],
                  ),
            border: Border.all(
              color: isSelected
                  ? const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.22),
              width: isSelected ? 1.0 : 0.3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(4, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected ? Colors.white : const Color(0xFFBACFE6),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFFBACFE6),
                  letterSpacing: isSelected ? 1.8 : 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(119, 0, 0, 0).withValues(alpha: 0.45),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
            offset: const Offset(0, 10),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0E2A38).withValues(alpha: 0.72),
                  const Color(0xFF061522).withValues(alpha: 0.82),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                width: 0.3,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showAlreadyRegisteredDialog(String studentId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: const Color(0xFF091B28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(
          color: Color(0xFFFFB74D), // Amber border to distinguish from success cyan
          width: 0.5,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFB74D),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ALREADY REGISTERED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This student account is already active in the transport database.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.8,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // ID badge preview container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 18,
                  color: Color(0xFF00E5FF),
                ),
                const SizedBox(width: 10),
                Text(
                  'ID: $studentId',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 223, 235, 236),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Use the Password sent to your email to log in directly.',
            style: TextStyle(
              color: const Color(0xFFBACFE6).withValues(alpha: 0.90),
              fontSize: 12.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Direct shortcut to password resend popup
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Navigator.pop(dialogCtx);
                _studentIdController.text = studentId;
                _showForgotPasswordDialog();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Forgot / Lost Password?',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFB74D),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 175, 217, 222),
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // 1. Dismiss the dialog
            Navigator.pop(dialogCtx);

            // 2. Switch directly to LOGIN tab and prefill the student ID
            setState(() {
              _activeVerticalTabIndex = 0; // Switch to LOGIN[cite: 5]
              _studentIdController.text = studentId; // Pre-fill ID[cite: 5]
              _errorMessage = null; // Clear previous errors[cite: 5]
            });

            // 3. Jump focus directly into the password field[cite: 5]
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FocusScope.of(context).requestFocus(_activationFocus); // Move cursor to password[cite: 5]
              }
            });
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GO TO LOGIN',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
            ],
          ),
        ),
      ],
    ),
  );
}

  // REGISTRATION FORM
  Widget _buildRegistrationFields() {
    return Column(
      key: const ValueKey('registration_fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STUDENT ID',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _regStudentIdController,
          focusNode: _regStudentIdFocus,
          hintText: 'e.g., TEST999',
          prefixIcon: Icons.account_circle_outlined,
          textCapitalization: TextCapitalization.characters,
          suffixWidget: _isAutoFetching
              ? const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                  ),
                )
              : _buildScanIconAction(isRegistration: true),
          onChanged: (val) {
            if (val.trim().length >= 8) {
              _fetchStudentDetails(val);
            }
          },
        ),

        // Auto-fetched Student Name & Year
        
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STUDENT NAME',
                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, color: Color(0xFFBACFE6)),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _regStudentNameController,
                      focusNode: _regStudentNameFocus,
                      hintText: _regStudentNameController.text.isNotEmpty ? _regStudentNameController.text : 'Auto-fetched Name',
                      prefixIcon: Icons.badge_outlined,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YEAR',
                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, color: Color(0xFFBACFE6)),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _regYearController,
                      focusNode: _regYearFocus,
                      hintText: _regYearController.text.isNotEmpty ? _regYearController.text : 'Auto-fetched Year',
                      prefixIcon: Icons.calendar_today_rounded,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        

        const SizedBox(height: 25),
        const Text(
          'STUDENT MOBILE NUMBER',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _studentMobileController,
          focusNode: _studentMobileFocus,
          hintText: 'e.g., 9876543210',
          prefixIcon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 14),
        const Text(
          'EMAIL ID',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          focusNode: _emailFocus,
          hintText: 'e.g., student123@gmail.com',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 14),
        const Text(
          'PARENT NAME',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _parentNameController,
          focusNode: _parentNameFocus,
          hintText: 'e.g., S. Ramesh',
          prefixIcon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 14),
        const Text(
          'PARENT MOBILE NUMBER',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _parentPhoneController,
          focusNode: _parentPhoneFocus,
          hintText: 'e.g., 9786543210',
          prefixIcon: Icons.contact_phone_outlined,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 14),
        const Text(
          'DEPARTMENT',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildDepartmentDropdown(),

        const SizedBox(height: 14),
        const Text('SELECT BUS ROUTE',
         style: TextStyle(
          fontSize: 10.0, 
          fontWeight: FontWeight.w700, 
          letterSpacing: 1.2, 
          color: Color(0xFFBACFE6))),
        const SizedBox(height: 8),
        _buildRouteDropdown(),

        const SizedBox(height: 18),

        // Static Guidelines Notice Board
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF04121F).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color.fromARGB(255, 0, 255, 8),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Note:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color.fromARGB(255, 0, 255, 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '• Incase You are facing Auto-fetch Issue, Reachout the College Transport Management \n• Ensure your email address is valid; your Password will be sent there.\n• Use a 10-digit registered Indian mobile number for verification.\n• Select your allocated college bus route accurately.',
                style: TextStyle(
                  fontSize: 11.0,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        _buildActionGradientButton(
          title: 'REGISTER NOW',
          onTap: _handleRegistration,
        ),
      ],
    );
  }

  // BUS ROUTE DROPDOWN (Fetched dynamically from 'buses' table)
  Widget _buildRouteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isRouteDropdownOpen = !_isRouteDropdownOpen;
                _isDepartmentDropdownOpen = false;
              });
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 255, 254, 254).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _isRouteDropdownOpen
                      ? const Color.fromARGB(122, 0, 0, 0).withValues(alpha: 0.30)
                      : Colors.white.withValues(alpha: 0.16),
                  width: _isRouteDropdownOpen ? 1.0 : 0.3,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    size: 18,
                    color: _isRouteDropdownOpen ? const Color.fromARGB(255, 4, 163, 255) : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingRoutes
                          ? 'Loading bus routes...'
                          : (_selectedRoute ?? 'Select Bus Route'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: _selectedRoute != null ? Colors.white : const Color.fromARGB(113, 255, 255, 255),
                      ),
                    ),
                  ),
                  Icon(
                    _isRouteDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color.fromARGB(255, 148, 148, 148),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isRouteDropdownOpen) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              color: const Color(0xFF081724),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.75), blurRadius: 12, offset: const Offset(4, 4)),
              ],
            ),
            child: _busRoutes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No routes available', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  )
                : RawScrollbar(
                    thumbColor: const Color.fromARGB(255, 141, 139, 139).withValues(alpha: 0.5),
                    radius: const Radius.circular(15),
                    thickness: 2.0,
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      itemCount: _busRoutes.length,
                      separatorBuilder: (context, _) => Divider(height: 5, color: Colors.white.withValues(alpha: 0.03)),
                      itemBuilder: (context, index) {
                        final route = _busRoutes[index];
                        final isSelected = _selectedRoute == route;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRoute = route;
                              _isRouteDropdownOpen = false;
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? const Color.fromARGB(255, 4, 163, 255).withValues(alpha: 0.15)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    route,
                                    style: TextStyle(
                                      fontSize: isSelected ? 13.0 : 11.5,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                      color: isSelected ? const Color.fromARGB(255, 4, 163, 255) : Colors.white70,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, size: 16, color: Color.fromARGB(255, 4, 163, 255)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  // 2. Replace _buildDepartmentDropdown() with this:
Widget _buildDepartmentDropdown() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Trigger header button
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _isDepartmentDropdownOpen = !_isDepartmentDropdownOpen;
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 255, 254, 254).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _isDepartmentDropdownOpen
                    ? const Color.fromARGB(122, 0, 0, 0).withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.16),
                width: _isDepartmentDropdownOpen ? 1.0 : 0.3,
              ),
              boxShadow: _isDepartmentDropdownOpen
                  ? [
                      BoxShadow(
                        color: const Color.fromARGB(108, 0, 0, 0).withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: _isDepartmentDropdownOpen
                      ? Color.fromARGB(255, 4, 163, 255)
                      : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDepartment ?? 'Select your department',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: _selectedDepartment != null
                          ? Colors.white
                          : const Color.fromARGB(113, 255, 255, 255),
                    ),
                  ),
                ),
                Icon(
                  _isDepartmentDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color.fromARGB(255, 148, 148, 148),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),

      // Scrollable list rendered directly underneath
      if (_isDepartmentDropdownOpen) ...[
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 135), // limits vertical expansion
          decoration: BoxDecoration(
            color: const Color(0xFF081724),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: RawScrollbar(
            thumbColor: const Color.fromARGB(255, 141, 139, 139).withValues(alpha: 0.5),
            radius: const Radius.circular(15),
            thickness: 2.0,
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 1),
              itemCount: _departments.length,
              separatorBuilder: (context, _) => Divider(
                height: 5,
                color: const Color.fromARGB(149, 255, 255, 255).withValues(alpha: 0.03),
              ),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final isSelected = dept == _selectedDepartment;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDepartment = dept;
                      _isDepartmentDropdownOpen = false;
                    });
                  },
                  child: Container(
                    color: isSelected
                        ? Color.fromARGB(255, 4, 163, 255).withValues(alpha: 0.15)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dept,
                            style: TextStyle(
                              fontSize: isSelected ? 13.0 : 11.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                              color: isSelected ? Color.fromARGB(255, 4, 163, 255) : Colors.white70,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color.fromARGB(255, 4, 163, 255),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ],
  );
}

  // LOGIN FORM
  Widget _buildloginFields() {
    return Column(
      key: const ValueKey('login_fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STUDENT ID',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _studentIdController,
          focusNode: _studentIdFocus,
          hintText: 'e.g., TEST999',
          prefixIcon: Icons.account_circle_outlined,
          textCapitalization: TextCapitalization.characters,
          suffixWidget: _buildScanIconAction(isRegistration: false),
        ),
        const SizedBox(height: 20),
        const Text(
          'PASSWORD ( Received in Email )',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFFBACFE6),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _activationkeyController,
          focusNode: _activationFocus,
          hintText: 'e.g., AM-EB2T',
          prefixIcon: Icons.vpn_key_outlined,
          textCapitalization: TextCapitalization.none,
        ),

        // FORGOT PASSWORD TRIGGER
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _showForgotPasswordDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Forgot / Lost Password?',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: const Color.fromARGB(255, 171, 209, 214).withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        
        
        const SizedBox(height: 22),
        _buildActionGradientButton(
          title: 'LOGIN NOW',
          onTap: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildActionGradientButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 46,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkNavy, Color.fromARGB(255, 1, 81, 112)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkNavy.withValues(alpha: 0.70),
            offset: const Offset(-2, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: AppTheme.cyanBlue.withValues(alpha: 0.45),
            offset: const Offset(3, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _isLoading ? null : onTap,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanIconAction({required bool isRegistration}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _openScanner(isRegistration: isRegistration),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 253, 253, 253).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.08),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 18,
                  color: Color.fromARGB(255, 181, 181, 181),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffixWidget,
    void Function(String)? onChanged,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final bool isFocused = focusNode.hasFocus;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: readOnly
                ? Colors.white.withValues(alpha: 0.03)
                : const Color.fromARGB(0, 255, 254, 254).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? const Color.fromARGB(98, 5, 5, 5).withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.16),
              width: isFocused ? 0.7 : 0.3,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(255, 2, 4, 4).withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(4, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                prefixIcon,
                size: 18,
                color: isFocused ? Color.fromARGB(255, 4, 163, 255) : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  textCapitalization: textCapitalization,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: readOnly ? const Color.fromARGB(255, 249, 249, 249) : Colors.white,
                    letterSpacing: 0.6,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(113, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              if (suffixWidget != null) suffixWidget,
            ],
          ),
        );
      },
    );
  }

  void _showBottomErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF261014),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFFFF5252).withValues(alpha: 0.60),
            width: 0.8,
          ),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF5252),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFFF8A80),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    debugPrint('[UI] Forgot Password dialog opened.');

    final TextEditingController forgotIdController = TextEditingController(
      text: _studentIdController.text.trim(),
    );
    final FocusNode forgotIdFocus = FocusNode();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF091B28).withValues(alpha: 0.99),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(
          color: Color(0xFFFFB74D), // Amber border to distinguish from success cyan
          width: 0.5,)
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFFFFB74D), size: 22),
                SizedBox(width: 8),
                Text(
                  'RECOVER PASSWORD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Student ID. Your registered password will be dispatched to your email.',
                  style: TextStyle(color: Color(0xFFBACFE6), fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: forgotIdController,
                  focusNode: forgotIdFocus,
                  hintText: 'e.g., TEST999',
                  prefixIcon: Icons.account_circle_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        debugPrint('[UI] Forgot Password dialog cancelled by user.');
                        Navigator.pop(dialogCtx);
                      },
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 196, 230, 234),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final id = forgotIdController.text.trim().toUpperCase();
                        debugPrint('[UI] "SEND KEY" tapped with input: "$id"');

                        if (id.isEmpty) {
                          debugPrint('[UI] Validation blocked: Student ID is empty.');
                          _showBottomSnackBar('Please enter your Student ID.');
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final result = await ApiService.forgotPassword(id);
                        setDialogState(() => isSubmitting = false);

                        if (!mounted) return;
                        Navigator.pop(dialogCtx);

                        debugPrint('[UI] Handling forgotPassword result: $result');

                        if (result['success'] == true) {
                          _showBottomSnackBar(result['message'] ?? 'Password sent via email!');
                        } else {
                          _showBottomErrorSnackBar(result['error'] ?? 'Recovery failed.');
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SEND KEY',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
    // Delay disposal until after the closing transition completely unmounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      forgotIdFocus.dispose();
      forgotIdController.dispose();
    });
  });
}

}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isScanCompleted = false;

  static const Color _deepBackground = Color(0xFF040A12);

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    for (final barcode in capture.barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _isScanCompleted = true;
        HapticFeedback.mediumImpact();

        String scannedId = rawValue.trim();

        if (scannedId.startsWith('{') && scannedId.endsWith('}')) {
          try {
            final parsed = jsonDecode(scannedId);
            if (parsed is Map) {
              scannedId = (parsed['student_id'] ??
                      parsed['studentId'] ??
                      parsed['id'] ??
                      scannedId)
                  .toString();
            }
          } catch (_) {}
        }

        Navigator.pop(context, scannedId);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _deepBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _deepBackground,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StaticDiagonalSlitsPainter(),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1E2C).withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 76.0,
                              width: 76.0,
                              child: Hero(
                                tag: 'app_college_logo',
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.directions_bus_filled_rounded,
                                    size: 54,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'AMCET STUDENT PORTAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Log-in to access your assigned college bus',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Georgia',
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildScanFrostedCard(),
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
      ),
    );
  }

  Widget _buildScanFrostedCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0E2A38).withValues(alpha: 0.75),
                  const Color(0xFF061522).withValues(alpha: 0.88),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.3,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                        Center(
                          child: Container(
                            width: 175,
                            height: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 1, 255, 255),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  'Scan your Student ID QR code to auto-fill the login form.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    fontSize: 11.0,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticDiagonalSlitsPainter extends CustomPainter {
  const _StaticDiagonalSlitsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double w = size.width;
    final double h = size.height;

    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040810),
          Color(0xFF060E18),
          Color(0xFF03070E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final Path upperLeftFacet = Path()
      ..moveTo(0, h * 0.12)
      ..lineTo(w * 0.46, 0)
      ..lineTo(w * 0.62, 0)
      ..lineTo(0, h * 0.38)
      ..close();
    _drawFacet(canvas, upperLeftFacet, const Color(0xFF0A1320), const Color(0xFF060C14));
    _drawSharpNeonLine(canvas, Offset(0, h * 0.12), Offset(w * 0.46, 0), intensity: 1.0);

    _drawSharpNeonLine(canvas, Offset(w * 0.72, 0), Offset(0, h * 0.42), intensity: 0.85);

    final Path centerRightFacet = Path()
      ..moveTo(w, h * 0.24)
      ..lineTo(w * 0.22, h * 0.64)
      ..lineTo(w * 0.16, h * 1.0)
      ..lineTo(w, h * 1.0)
      ..close();
    _drawFacet(canvas, centerRightFacet, const Color(0xFF08111D), const Color(0xFF040A12));
    _drawSharpNeonLine(canvas, Offset(w, h * 0.24), Offset(w * 0.22, h * 0.64), intensity: 1.0);

    final Path lowerLeftFacet = Path()
      ..moveTo(0, h * 0.58)
      ..lineTo(w * 0.32, h * 0.82)
      ..lineTo(0, h * 0.96)
      ..close();
    _drawFacet(canvas, lowerLeftFacet, const Color(0xFF091422), const Color(0xFF050B12));
    _drawSharpNeonLine(canvas, Offset(0, h * 0.58), Offset(w * 0.32, h * 0.82), intensity: 0.95);

    _drawSharpNeonLine(canvas, Offset(w * 0.78, h * 0.74), Offset(w, h * 0.86), intensity: 0.90);
  }

  void _drawFacet(Canvas canvas, Path path, Color c1, Color c2) {
    canvas.drawPath(
      path.shift(const Offset(2.0, 4.0)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ).createShader(path.getBounds()),
    );
  }

  void _drawSharpNeonLine(
    Canvas canvas,
    Offset start,
    Offset end, {
    double intensity = 1.0,
  }) {
    final Rect bounds = Rect.fromPoints(start, end);

    final Paint wideGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color.fromARGB(255, 0, 229, 255).withValues(alpha: 0.38 * intensity),
          const Color.fromARGB(255, 0, 162, 255).withValues(alpha: 0.25 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(bounds)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawLine(start, end, wideGlow);

    final Paint sharpAura = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color.fromARGB(255, 0, 247, 255).withValues(alpha: 0.85 * intensity),
          const Color.fromARGB(255, 0, 208, 255).withValues(alpha: 0.80 * intensity),
          Colors.transparent,
        ],
        stops: const [0.05, 0.35, 0.65, 0.95],
      ).createShader(bounds)
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawLine(start, end, sharpAura);

    final Paint razorCore = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.95 * intensity),
          const Color.fromARGB(255, 224, 255, 255).withValues(alpha: 0.90 * intensity),
          Colors.transparent,
        ],
        stops: const [0.08, 0.35, 0.65, 0.92],
      ).createShader(bounds)
      ..strokeWidth = 1.1;
    canvas.drawLine(start, end, razorCore);
  }

  @override
  bool shouldRepaint(covariant _StaticDiagonalSlitsPainter oldDelegate) => false;
}

class SmoothKeyboardLayout extends StatelessWidget {
  final Widget child;

  const SmoothKeyboardLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Read the keyboard inset directly from View (bypasses full build delays)
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;

    return AnimatedPadding(
      // 2. 250ms duration with easeOutCubic mirrors Android/iOS keyboard acceleration
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      // Shifts up proportionally to keep inputs centered without squishing the layout
      padding: EdgeInsets.only(
        bottom: isKeyboardOpen ? keyboardHeight * 0.75 : 0.0,
      ),
      child:child,
    );
  }
}