import 'package:flutter/material.dart';
import 'package:horria_t/core/routes/app_router.dart';
import 'package:horria_t/core/network/face_auth_service.dart';
import 'package:horria_t/core/network/auth_store.dart';
import 'package:camera/camera.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FaceAuthService _faceAuthService = FaceAuthService();
  bool _isVerifying = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front, 
        orElse: () => cameras.first
      );
      
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _verifyFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكاميرا غير متاحة')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      final result = await _faceAuthService.verifyFace(imageBytes);

      if (!mounted) return;

      if (result.isSuccess) {
        // Only navigate if backend explicitly approves the face
        AuthStore().setSession(
          result.token, 
          id: result.userId,
          name: result.userName, 
          userGreeting: result.greeting,
        );
        Navigator.of(context).pushNamed(AppRouter.dashboard);
      } else {
        // Show error message from backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'فشل التحقق من الوجه. يرجى المحاولة مرة أخرى.',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ في الاتصال: $e',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4294);
    const lightPurple = Color(0xFFEEC8D9);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/common/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // White overlay for transparency effect
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.85),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: TextButton.icon(
                      onPressed: _isVerifying ? null : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: primaryColor,
                      ),
                      label: const Text(
                        'رجوع',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'التحقق بالوجه',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'قم بمحاذاة وجهك داخل الإطار لإتمام التسجيل بأمان',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 4),
                            ),
                            child: ClipOval(
                              child: _isCameraInitialized
                                  ? CameraPreview(_cameraController!)
                                  : const Center(child: CircularProgressIndicator()),
                            ),
                          ),

                          const SizedBox(height: 40),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: lightPurple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isVerifying
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.verified_user,
                                        color: primaryColor,
                                      ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _isVerifying 
                                        ? 'يتم التواصل مع الخادم...'
                                        : 'جاري التحقق من الوجه... يرجى عدم تحريك وجهك',
                                    style: const TextStyle(
                                      color: Color(0xFF5B4A6E),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: 360,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isVerifying ? null : _verifyFace,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                disabledBackgroundColor: primaryColor.withOpacity(0.5),
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'تحقق',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}