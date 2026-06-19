import 'package:flutter/material.dart';
import '../models/measurement_type.dart';
import '../views/measurements/measurement_instruction_screen.dart';
import '../views/history/history_screen.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../presentation/global_widgets/sdui_vital_card.dart';
import '../data/models/sdui_payload_model.dart';
import '../presentation/global_widgets/sdui_sidebar.dart';

class VitalSignsScreen extends StatelessWidget {
  const VitalSignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Waves extending under sidebar
          Positioned(
            bottom: 0,
            left: 0,
            right: -105,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/common/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Row(
            children: [
              // Main Content
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 20),

                        Text(
                          AppStrings.measurementsTab,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: MediaQuery.of(context).size.width *0.05),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width *0.8,
                              child: GridView.count(
                                crossAxisCount: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.4,
                                children: [
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'glucose',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/glucose.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.glucose,
                                  ),
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'ecg',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/ECG.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.ecg,
                                  ),
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'bp',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/blood_pressure.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.bloodPressure,
                                  ),
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'spo2',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/oxygen_level.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.oxygen,
                                  ),
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'hr',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/heart_rate.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.heartRate,
                                  ),
                                  SduiVitalCard(
                                    payload: const SduiVitalCardPayload(
                                      id: 'temp',
                                      type: 'VitalCard',
                                      imagePath: 'assets/images/measurements/icons/temperature.png',
                                      title: '',
                                    ),
                                    type: MeasurementType.temperature,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
