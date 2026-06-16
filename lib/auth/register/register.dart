import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String _gender = "أنثى";

  // Step 2 State
  bool imageCaptured = false;

  // Step 3 State
  List<String> selectedConditions = [];
  final List<String> conditions = [
    "السكري",
    "الغدة الدرقية",
    "ضغط الدم",
    "الكلى",
    "القلب",
    "الربو",
    "لا يوجد",
  ];
  final List<bool?> answers = [null];

  @override
  void dispose() {
    fullNameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
      } else {
        // Complete Registration
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _currentStep == 3 ? const Color(0xffFAF8FB) : Colors.white,
        body: Stack(
          children: [
            if (_currentStep != 3)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
            SafeArea(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildPersonalInfo();
      case 2:
        return _buildFaceVerification();
      case 3:
        return _buildHealthData();
      default:
        return Container();
    }
  }

  // --- STEP 1: PERSONAL INFO ---
  Widget _buildPersonalInfo() {
    const primaryColor = Color(0xFFF56AA5);
    const purpleColor = Color(0xFF69409B);

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTopHeader(),
        const SizedBox(height: 10),
        _buildStepper(1),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "البيانات الشخصية",
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Center(
            child: Container(
              width: 930,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("الاسم الكامل"),
                      const SizedBox(height: 10),
                      _textField(
                        controller: fullNameController,
                        hint: "أدخل اسمك الكامل",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "يرجى إدخال الاسم الكامل";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("العمر"),
                                const SizedBox(height: 10),
                                _textField(
                                  controller: ageController,
                                  hint: "أدخل العمر",
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "يرجى إدخال العمر";
                                    }
                                    if (int.tryParse(_convertArabicNumbers(value.trim())) == null) {
                                      return "العمر غير صحيح";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("رقم الهاتف المحمول"),
                                const SizedBox(height: 10),
                                _textField(
                                  controller: phoneController,
                                  hint: "01xxxxxxxxxx",
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "يرجى إدخال رقم الهاتف";
                                    }
                                    if (value.length < 11) {
                                      return "رقم الهاتف غير صحيح";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _label("النوع"),
                      const SizedBox(height: 12),
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _gender = "أنثى"),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _gender == "أنثى" ? const Color(0xFFFFF3F8) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "أنثى",
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      if (_gender == "أنثى") ...[
                                        const SizedBox(width: 10),
                                        const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: primaryColor,
                                          child: Icon(Icons.check, color: Colors.white, size: 16),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: Colors.grey.shade300),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _gender = "ذكر"),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _gender == "ذكر" ? const Color(0xFFFFF3F8) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "ذكر",
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      if (_gender == "ذكر") ...[
                                        const SizedBox(width: 10),
                                        const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: primaryColor,
                                          child: Icon(Icons.check, color: Colors.white, size: 16),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Center(
                        child: SizedBox(
                          width: 360,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purpleColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _nextStep();
                              }
                            },
                            child: const Text(
                              "التالي",
                              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: FACE VERIFICATION ---
  Widget _buildFaceVerification() {
    const purpleColor = Color(0xFF69409B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildTopHeader(),
          const SizedBox(height: 10),
          _buildStepper(2),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 550,
                        height: 380,
                        decoration: BoxDecoration(
                          border: Border.all(color: purpleColor, width: 3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            if (imageCaptured)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  "assets/images/person.jpg",
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            _corner(Alignment.topLeft),
                            _corner(Alignment.topRight),
                            _corner(Alignment.bottomLeft),
                            _corner(Alignment.bottomRight),
                            Positioned(
                              bottom: 10,
                              left: 60,
                              right: 60,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: purpleColor.withOpacity(.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.center_focus_strong, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "ضع وجهك داخل الإطار ثم اضغط التقط الصورة",
                                      style: TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      SizedBox(
                        width: 360,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purpleColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {
                            if (!imageCaptured) {
                              setState(() => imageCaptured = true);
                            } else {
                              _nextStep();
                            }
                          },
                          child: Text(
                            imageCaptured ? "التالي" : "التقط الصورة",
                            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "التحقق بالوجه",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF2F374B)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "يرجى وضع وجهك داخل الإطار واتباع التعليمات التالية",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 35),
                      _instructionCard("قم بإزالة النظارة", Icons.visibility),
                      const SizedBox(height: 16),
                      _instructionCard("انظر مباشرة إلى الكاميرا", Icons.person_outline),
                      const SizedBox(height: 16),
                      _instructionCard("تأكد من وضوح الإضاءة", Icons.wb_sunny_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: HEALTH DATA ---
  Widget _buildHealthData() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildTopHeader(),
          const SizedBox(height: 10),
          _buildStepper(3),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "البيانات الصحية",
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xff232B3A)),
                    ),
                  ),
                  SizedBox(height: answers[0] != true ? 20 : 0),
                  answers[0] != true
                      ? const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "يرجى الإجابة على الأسئلة التالية بدقة",
                            style: TextStyle(fontSize: 26, color: Color(0xff6E5A83)),
                          ),
                        )
                      : Container(),
                  SizedBox(height: answers[0] != true ? 24 : 0),
                  if (answers[0] != true)
                    ...List.generate(
                      answers.length,
                      (index) => QuestionCard(
                        question: "هل تعاني من أمراض مزمنة",
                        value: answers[index],
                        onChanged: (value) {
                          setState(() {
                            answers[index] = value;
                          });
                        },
                      ),
                    ),
                  answers[0] == true
                      ? const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "الأمراض المزمنة (اختر كل ما ينطبق عليك)",
                            style: TextStyle(fontSize: 24, color: Color(0xff6E5A83)),
                          ),
                        )
                      : Container(),
                  const SizedBox(height: 30),
                  answers[0] == true
                      ? Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: conditions.map((e) {
                            bool selected = selectedConditions.contains(e);
                            return ConditionChip(
                              title: e,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    selectedConditions.remove(e);
                                  } else {
                                    selectedConditions.add(e);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        )
                      : Container(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 360,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff644090),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text(
                "إتمام التسجيل",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- SHARED WIDGETS ---

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        InkWell(
          onTap: _prevStep,
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward,
                color: Colors.deepPurple.shade800,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                "رجوع",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(int step) {
    const primaryColor = Color(0xFFF56AA5);
    const purpleColor = Color(0xFF69409B);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _currentStep == 3 ? 0 : 120),
      child: Row(
        children: [
          Expanded(
            child: _step(
              number: "1",
              label: "البيانات الشخصية",
              active: step == 1,
              completed: step > 1,
            ),
          ),
          Container(
            width: 50,
            height: 2,
            color: step >= 2 ? (step == 2 ? primaryColor : purpleColor) : Colors.grey.shade300,
          ),
          Expanded(
            child: _step(
              number: "2",
              label: "التحقق بالوجه",
              active: step == 2,
              completed: step > 2,
            ),
          ),
          Container(
            width: 50,
            height: 2,
            color: step >= 3 ? purpleColor : Colors.grey.shade300,
          ),
          Expanded(
            child: _step(
              number: "3",
              label: "البيانات الصحية",
              active: step == 3,
              completed: step > 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step({
    required String number,
    required String label,
    required bool active,
    bool completed = false,
  }) {
    const primaryColor = Color(0xFFF56AA5);
    const purpleColor = Color(0xFF69409B);

    if (completed) {
      return Column(
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: purpleColor,
            child: Icon(Icons.check, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: purpleColor)),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? primaryColor : Colors.grey.shade400,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF6C4AA1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? primaryColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  static Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6C4AA1),
      ),
      textAlign: TextAlign.right,
    );
  }

  static Widget _textField({
    TextEditingController? controller,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 58,
      child: TextFormField(
        controller: controller,
        validator: validator,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  String _convertArabicNumbers(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';
    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Color(0xFFE4C8D8), width: 12)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Color(0xFFE4C8D8), width: 12)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFFE4C8D8), width: 12)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFFE4C8D8), width: 12)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _instructionCard(String title, IconData icon) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF9EBF2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF5D1E3),
              child:  Icon(icon, color: Color(0xFF69409B)),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF69409B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class ConditionChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const ConditionChip({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 70,
        decoration: BoxDecoration(
          color: selected ? const Color(0xffFFF1F7) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xffFF6FA5) : const Color(0xff644090),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 28,
              color: selected ? const Color(0xff644090) : const Color(0xff6E5A83),
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String question;
  final bool? value;
  final Function(bool) onChanged;

  const QuestionCard({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24, color: Color(0xff6E5A83)),
            ),
          ),
          const SizedBox(width: 20),
          _answerButton(title: "نعم", selected: value == true, onTap: () => onChanged(true)),
          const SizedBox(width: 12),
          _answerButton(title: "لا", selected: value == false, onTap: () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _answerButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 60,
        decoration: BoxDecoration(
          color: selected ? const Color(0xffFFF1F7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xffFF6FA5) : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 24, color: Color(0xff6E5A83)),
          ),
        ),
      ),
    );
  }
}
