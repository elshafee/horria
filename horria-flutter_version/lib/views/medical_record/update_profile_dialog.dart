import 'package:flutter/material.dart';
import '../../core/network/user_service.dart';
import '../../presentation/global_widgets/sdui_primary_button.dart';

class UpdateProfileDialog extends StatefulWidget {
  final UserProfile profile;

  const UpdateProfileDialog({super.key, required this.profile});

  @override
  State<UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _conditionsController;
  late TextEditingController _allergiesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.profile.medicalHistory['weight'] ?? '');
    _heightController = TextEditingController(text: widget.profile.medicalHistory['height'] ?? '');
    _bloodTypeController = TextEditingController(text: widget.profile.medicalHistory['blood_type'] ?? '');
    _conditionsController = TextEditingController(text: widget.profile.medicalHistory['conditions'] ?? '');
    _allergiesController = TextEditingController(text: widget.profile.medicalHistory['allergies'] ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bloodTypeController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    final updates = {
      'weight': _weightController.text.trim(),
      'height': _heightController.text.trim(),
      'blood_type': _bloodTypeController.text.trim(),
      'conditions': _conditionsController.text.trim(),
      'allergies': _allergiesController.text.trim(),
    };

    final success = await UserService().updateUserProfile(updates);

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحديث البيانات. يرجى المحاولة مرة أخرى.', textDirection: TextDirection.rtl),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: Color(0xFF65418F)), // Fixed: Explicitly set text color to dark purple
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF65418F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF65418F), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تحديث البيانات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65418F),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const Divider(height: 32),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField('الوزن (كجم)', _weightController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('الطول (سم)', _heightController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('فصيلة الدم', _bloodTypeController)),
                    ],
                  ),
                  _buildTextField('الأمراض المزمنة', _conditionsController, maxLines: 2),
                  _buildTextField('الحساسية (أدوية، طعام)', _allergiesController, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF85A1)))
                : SduiPrimaryButton(
                    text: 'حفظ التغييرات',
                    onPressed: _save,
                    backgroundColor: const Color(0xFF65418F),
                  ),
          ],
        ),
      ),
    );
  }
}
