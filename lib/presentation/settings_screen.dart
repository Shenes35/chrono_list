import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedAlarmSound = "Default Alarm Sound";
  int _alarmDurationSeconds = 10;
  double _alarmVolume = 0.8;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  bool _floatingVolumeEnabled = false;

  final MethodChannel _methodChannel = const MethodChannel('touch_recorder/methods');

  final List<String> _alarmOptions = [
    "Default Alarm Sound",
    "Digital Chime (Short Beep)",
    "Gentle Bell (Ringtone)",
    "Loud Siren (Emergency)",
    "Vibration Only",
    "Silent",
  ];

  final List<int> _durationOptions = [5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final box = await Hive.openBox('settings_box');
      final savedVolumeEnabled = box.get('floating_volume_enabled', defaultValue: false);
      bool isShowing = false;
      try {
        isShowing = await _methodChannel.invokeMethod('isVolumeOverlayShowing') ?? false;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _selectedAlarmSound = box.get('default_alarm_sound', defaultValue: "Default Alarm Sound");
          _alarmDurationSeconds = box.get('alarm_duration_seconds', defaultValue: 10);
          _alarmVolume = (box.get('alarm_volume', defaultValue: 0.8) as num).toDouble();
          _vibrationEnabled = box.get('vibration_enabled', defaultValue: true);
          _notificationsEnabled = box.get('notifications_enabled', defaultValue: true);
          _floatingVolumeEnabled = savedVolumeEnabled || isShowing;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFloatingVolume(bool val) async {
    setState(() {
      _floatingVolumeEnabled = val;
    });
    _saveSetting('floating_volume_enabled', val);

    try {
      await _methodChannel.invokeMethod('toggleVolumeOverlay', {'enable': val});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? "Floating Volume Button Activated!" : "Floating Volume Button Disabled"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == "OVERLAY_PERMISSION_REQUIRED") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Overlay permission required. Please grant 'Display over other apps'."),
              action: SnackBarAction(
                label: "GRANT",
                onPressed: () {
                  _methodChannel.invokeMethod('requestOverlayPermission');
                },
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _adjustVolumeDirectly(String action) async {
    try {
      await _methodChannel.invokeMethod('adjustSystemVolume', {'action': action});
      if (mounted) {
        String msg = action == 'up' ? "Volume Up (+)" : action == 'down' ? "Volume Down (-)" : "Mute / Unmute Toggled";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final box = await Hive.openBox('settings_box');
      await box.put(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF282727), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: GoogleFonts.oxanium(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      "TIME TRIGGER ALARM SOUND",
                      style: GoogleFonts.oxanium(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Alarm Sound Tone Picker Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Default Task Alarm Tone",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Selected sound will play when time trigger alarm activates",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedAlarmSound,
                            items: _alarmOptions.map((sound) {
                              return DropdownMenuItem<String>(
                                value: sound,
                                child: Row(
                                  children: [
                                    Icon(
                                      sound == "Silent"
                                          ? Icons.volume_off
                                          : sound == "Vibration Only"
                                              ? Icons.vibration
                                              : Icons.notifications_active,
                                      color: const Color(0xFF1273C2),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(sound, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAlarmSound = val;
                                });
                                _saveSetting('default_alarm_sound', val);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Alarm sound saved as: $val")),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Alarm Ring Duration (Seconds)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _alarmDurationSeconds,
                            items: _durationOptions.map((sec) {
                              return DropdownMenuItem<int>(
                                value: sec,
                                child: Text("$sec Seconds", style: const TextStyle(fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _alarmDurationSeconds = val;
                                });
                                _saveSetting('alarm_duration_seconds', val);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Alarm ring duration set to: $val seconds")),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Test Play & Stop Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1273C2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      SystemSound.play(SystemSoundType.click);
                                      HapticFeedback.vibrate();
                                      const methodChannel = MethodChannel('touch_recorder/methods');
                                      try {
                                        await methodChannel.invokeMethod('playAlarmSound', {
                                          'soundType': _selectedAlarmSound,
                                          'durationSeconds': _alarmDurationSeconds,
                                          'volume': _alarmVolume,
                                        });
                                      } catch (_) {}
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Playing Alarm: '$_selectedAlarmSound' for $_alarmDurationSeconds sec"),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 20),
                                    label: Text(
                                      "Test Play",
                                      style: GoogleFonts.oxanium(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    const methodChannel = MethodChannel('touch_recorder/methods');
                                    try {
                                      await methodChannel.invokeMethod('stopAlarmSound');
                                    } catch (_) {}
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Alarm stopped")),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.stop, color: Colors.white, size: 20),
                                  label: Text(
                                    "Stop",
                                    style: GoogleFonts.oxanium(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Volume & Vibration Section Title
                    Text(
                      "AUDIO & NOTIFICATIONS",
                      style: GoogleFonts.oxanium(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Controls Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Alarm Sound Volume",
                                style: GoogleFonts.oxanium(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                "${(_alarmVolume * 100).toInt()}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1273C2)),
                              ),
                            ],
                          ),
                          Slider(
                            value: _alarmVolume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xFF1273C2),
                            onChanged: (val) {
                              setState(() {
                                _alarmVolume = val;
                              });
                              _saveSetting('alarm_volume', val);
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1273C2),
                            title: const Text("Vibration Feedback", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text("Vibrate device when task alarm triggers", style: TextStyle(fontSize: 12)),
                            value: _vibrationEnabled,
                            onChanged: (val) {
                              setState(() {
                                _vibrationEnabled = val;
                              });
                              _saveSetting('vibration_enabled', val);
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1273C2),
                            title: const Text("Task Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text("Show system notifications for scheduled tasks", style: TextStyle(fontSize: 12)),
                            value: _notificationsEnabled,
                            onChanged: (val) {
                              setState(() {
                                _notificationsEnabled = val;
                              });
                              _saveSetting('notifications_enabled', val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Floating Volume Button (Hardware Fix) Section Title
                    Text(
                      "FLOATING VOLUME BUTTON (HARDWARE FIX)",
                      style: GoogleFonts.oxanium(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Floating Volume Control Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _floatingVolumeEnabled ? const Color(0xFF1273C2) : Colors.grey.shade300,
                          width: _floatingVolumeEnabled ? 2 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1273C2),
                            title: Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, color: Color(0xFF1273C2), size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Permanent Floating Volume Button",
                                    style: GoogleFonts.oxanium(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Show an overlay volume button permanently on your screen to adjust volume if physical buttons are broken",
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                            value: _floatingVolumeEnabled,
                            onChanged: (val) {
                              _toggleFloatingVolume(val);
                            },
                          ),
                          const Divider(),
                          const SizedBox(height: 4),
                          const Text(
                            "Quick Software Volume Controls",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E293B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _adjustVolumeDirectly('down'),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
                                  label: const Text("Vol -", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1273C2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _adjustVolumeDirectly('up'),
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                                  label: const Text("Vol +", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _adjustVolumeDirectly('mute'),
                                  icon: const Icon(Icons.volume_off, color: Colors.white, size: 18),
                                  label: const Text("Mute", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // System Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "System & Floating Overlay Status",
                                  style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Samsung Galaxy A13 | Overlay Permission Active",
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
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
    );
  }
}
