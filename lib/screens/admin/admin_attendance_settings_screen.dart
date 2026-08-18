import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../auth/login_screen.dart';

class AdminAttendanceSettingsScreen extends StatefulWidget {
  const AdminAttendanceSettingsScreen({super.key});

  @override
  State<AdminAttendanceSettingsScreen> createState() => _AdminAttendanceSettingsScreenState();
}

class _AdminAttendanceSettingsScreenState extends State<AdminAttendanceSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _thresholdController = TextEditingController(text: '80');
  final TextEditingController _qrValidityController = TextEditingController(text: '15');
  final TextEditingController _lateThresholdController = TextEditingController(text: '10');
  final TextEditingController _radiusController = TextEditingController(text: '200');

  // State Variables
  double _requiredPercentage = 80.0;
  int _qrValidityMinutes = 15;
  bool _enableLateAttendance = true;
  int _lateThresholdMinutes = 10;
  bool _enableLocationVerification = false;
  double _allowedRadiusMeters = 200.0;
  bool _enableManualAttendance = true;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadSettings();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _qrValidityController.dispose();
    _lateThresholdController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadSettings() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      return;
    }

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _firestore.collection('settings').doc('attendance_config').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 1. Required percentage
        if (data['threshold'] != null || data['requiredPercentage'] != null) {
          _requiredPercentage = (data['requiredPercentage'] ?? data['threshold'] as num).toDouble();
          _thresholdController.text = _requiredPercentage.toStringAsFixed(0);
        }

        // 2. QR Validity Duration
        if (data['qrValidityMinutes'] != null) {
          _qrValidityMinutes = (data['qrValidityMinutes'] as num).toInt();
          _qrValidityController.text = _qrValidityMinutes.toString();
        }

        // 3. Late Attendance
        if (data['enableLateAttendance'] != null) {
          _enableLateAttendance = data['enableLateAttendance'] as bool;
        }
        if (data['lateThresholdMinutes'] != null) {
          _lateThresholdMinutes = (data['lateThresholdMinutes'] as num).toInt();
          _lateThresholdController.text = _lateThresholdMinutes.toString();
        }

        // 4. Location Verification
        if (data['enableLocationVerification'] != null) {
          _enableLocationVerification = data['enableLocationVerification'] as bool;
        }
        if (data['allowedRadiusMeters'] != null) {
          _allowedRadiusMeters = (data['allowedRadiusMeters'] as num).toDouble();
          _radiusController.text = _allowedRadiusMeters.toStringAsFixed(0);
        }

        // 5. Manual Attendance
        if (data['enableManualAttendance'] != null) {
          _enableManualAttendance = data['enableManualAttendance'] as bool;
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance settings: $e');
      _errorMessage = 'Failed to load attendance settings: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct validation errors before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final user = _authService.currentUser;

    try {
      final percentage = double.tryParse(_thresholdController.text.trim()) ?? _requiredPercentage;
      final qrMinutes = int.tryParse(_qrValidityController.text.trim()) ?? _qrValidityMinutes;
      final lateMinutes = int.tryParse(_lateThresholdMinutes.toString()) ?? 10;
      final radius = double.tryParse(_radiusController.text.trim()) ?? _allowedRadiusMeters;

      final configData = {
        'threshold': percentage,
        'requiredPercentage': percentage,
        'minAttendancePercentage': percentage,
        'qrValidityMinutes': qrMinutes,
        'enableLateAttendance': _enableLateAttendance,
        'lateThresholdMinutes': lateMinutes,
        'enableLocationVerification': _enableLocationVerification,
        'allowedRadiusMeters': radius,
        'enableManualAttendance': _enableManualAttendance,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': user?.email ?? 'admin@system.com',
      };

      await _firestore
          .collection('settings')
          .doc('attendance_config')
          .set(configData, SetOptions(merge: true));

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Attendance settings successfully saved! (Required: ${percentage.toStringAsFixed(0)}% • QR: ${qrMinutes}m)',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _applyPreset({
    required double percentage,
    required int qrMinutes,
    required bool lateAttendance,
    required int lateMinutes,
    required bool locationVerify,
    required double radius,
    required bool manualAttendance,
    required String presetName,
  }) {
    setState(() {
      _requiredPercentage = percentage;
      _thresholdController.text = percentage.toStringAsFixed(0);

      _qrValidityMinutes = qrMinutes;
      _qrValidityController.text = qrMinutes.toString();

      _enableLateAttendance = lateAttendance;
      _lateThresholdMinutes = lateMinutes;
      _lateThresholdController.text = lateMinutes.toString();

      _enableLocationVerification = locationVerify;
      _allowedRadiusMeters = radius;
      _radiusController.text = radius.toStringAsFixed(0);

      _enableManualAttendance = manualAttendance;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied Preset: "$presetName". Click Save to persist.'),
        backgroundColor: Colors.indigoAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'Attendance Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSettings,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                          child: const Text('Retry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Badge
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: Colors.amberAccent, size: 30),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Institutional Attendance Policy & QR Rules',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'These rules dynamically govern QR generation, scanning, and eligibility across the app.',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Policy Presets Strip
                      _buildSectionHeader('POLICY PRESETS (1-TAP CONFIGURE)'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPresetChip('Standard University', () {
                              _applyPreset(
                                percentage: 80.0,
                                qrMinutes: 15,
                                lateAttendance: true,
                                lateMinutes: 10,
                                locationVerify: false,
                                radius: 200.0,
                                manualAttendance: true,
                                presetName: 'Standard University',
                              );
                            }),
                            const SizedBox(width: 8),
                            _buildPresetChip('Strict Examination', () {
                              _applyPreset(
                                percentage: 85.0,
                                qrMinutes: 5,
                                lateAttendance: true,
                                lateMinutes: 5,
                                locationVerify: true,
                                radius: 100.0,
                                manualAttendance: false,
                                presetName: 'Strict Examination',
                              );
                            }),
                            const SizedBox(width: 8),
                            _buildPresetChip('Flexible Lab Policy', () {
                              _applyPreset(
                                percentage: 75.0,
                                qrMinutes: 30,
                                lateAttendance: true,
                                lateMinutes: 20,
                                locationVerify: false,
                                radius: 300.0,
                                manualAttendance: true,
                                presetName: 'Flexible Lab Policy',
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Required Attendance Percentage
                      _buildSectionHeader('1. ATTENDANCE ELIGIBILITY THRESHOLD'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.percent_rounded, color: Colors.tealAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Required Minimum Percentage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withAlpha(40),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.tealAccent),
                                  ),
                                  child: Text(
                                    '${_requiredPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Students below this threshold are flagged in Low Attendance reports and exam eligibility warnings.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.tealAccent,
                                inactiveTrackColor: Colors.white12,
                                thumbColor: Colors.tealAccent,
                              ),
                              child: Slider(
                                value: _requiredPercentage,
                                min: 50.0,
                                max: 100.0,
                                divisions: 10,
                                label: '${_requiredPercentage.toStringAsFixed(0)}%',
                                onChanged: (val) {
                                  setState(() {
                                    _requiredPercentage = val;
                                    _thresholdController.text = val.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ),
                            TextFormField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Custom Percentage (50 - 100%)', Icons.fact_check_rounded),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter percentage';
                                final numVal = double.tryParse(val.trim());
                                if (numVal == null || numVal < 50 || numVal > 100) {
                                  return 'Percentage must be between 50% and 100%';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                final numVal = double.tryParse(val.trim());
                                if (numVal != null && numVal >= 50 && numVal <= 100) {
                                  setState(() => _requiredPercentage = numVal);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Dynamic QR Code Validity Duration
                      _buildSectionHeader('2. DYNAMIC QR CODE EXPIRY DURATION'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.timer_rounded, color: Colors.amberAccent, size: 18),
                                SizedBox(width: 8),
                                Text('QR Code Validity Duration (Minutes)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'How long a dynamic lecture QR session remains active before expiring and refusing student scans.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _qrValidityController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('Validity in Minutes (1 - 60)', Icons.hourglass_bottom_rounded),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Enter minutes';
                                      final numVal = int.tryParse(val.trim());
                                      if (numVal == null || numVal < 1 || numVal > 120) {
                                        return 'Duration must be between 1 and 120 minutes';
                                      }
                                      return null;
                                    },
                                    onChanged: (val) {
                                      final numVal = int.tryParse(val.trim());
                                      if (numVal != null && numVal >= 1) {
                                        setState(() => _qrValidityMinutes = numVal);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    if (_qrValidityMinutes > 5) {
                                      setState(() {
                                        _qrValidityMinutes -= 5;
                                        _qrValidityController.text = _qrValidityMinutes.toString();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.amberAccent),
                                ),
                                Text('$_qrValidityMinutes m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: () {
                                    if (_qrValidityMinutes < 60) {
                                      setState(() {
                                        _qrValidityMinutes += 5;
                                        _qrValidityController.text = _qrValidityMinutes.toString();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Late Attendance Configuration
                      _buildSectionHeader('3. LATE ATTENDANCE RULES'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _enableLateAttendance,
                              activeThumbColor: Colors.orangeAccent,
                              title: const Text('Enable Late Attendance Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Differentiates on-time presence vs late arrivals in reports', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              onChanged: (val) => setState(() => _enableLateAttendance = val),
                            ),
                            if (_enableLateAttendance) ...[
                              const Divider(color: Colors.white10, height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Late Arrival Threshold (Minutes from class start):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _lateThresholdController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('Late Threshold Minutes (1 - 60)', Icons.access_time_rounded),
                                      validator: (val) {
                                        if (!_enableLateAttendance) return null;
                                        if (val == null || val.trim().isEmpty) return 'Enter late threshold';
                                        final numVal = int.tryParse(val.trim());
                                        if (numVal == null || numVal < 1 || numVal > 60) {
                                          return 'Threshold must be between 1 and 60 minutes';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Location Verification (Geofencing)
                      _buildSectionHeader('4. LOCATION & GEOFENCING VERIFICATION'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _enableLocationVerification,
                              activeThumbColor: Colors.greenAccent,
                              title: const Text('Enforce Classroom Location Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Prevents remote screenshot sharing outside hall/campus bounds', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              onChanged: (val) => setState(() => _enableLocationVerification = val),
                            ),
                            if (_enableLocationVerification) ...[
                              const Divider(color: Colors.white10, height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Allowed Venue Radius (Meters):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _radiusController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('Allowed Radius in Meters (10 - 2000)', Icons.radar_rounded),
                                      validator: (val) {
                                        if (!_enableLocationVerification) return null;
                                        if (val == null || val.trim().isEmpty) return 'Enter radius in meters';
                                        final numVal = double.tryParse(val.trim());
                                        if (numVal == null || numVal < 10 || numVal > 5000) {
                                          return 'Radius must be between 10m and 5000m';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Manual Attendance Permission
                      _buildSectionHeader('5. MANUAL ATTENDANCE PERMISSIONS'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SwitchListTile(
                          value: _enableManualAttendance,
                          activeThumbColor: Colors.tealAccent,
                          title: const Text('Allow Lecturers Manual Marking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('If disabled, lecturers must strictly use Dynamic QR sessions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          onChanged: (val) => setState(() => _enableManualAttendance = val),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded, color: Colors.white),
                          label: Text(
                            _isSaving ? 'Saving Policy Settings...' : 'Save & Publish Attendance Rules',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Colors.indigoAccent),
      label: Text(label, style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
    );
  }
}
