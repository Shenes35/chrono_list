import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chrono_list/core/task_core.dart';
import 'package:chrono_list/model/task_model.dart';
import 'package:chrono_list/presentation/custom_calender.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskPage extends StatefulWidget {
  final DateTime selectedDate;
  final DateTimeRange? initialDateRange;
  final TaskModel? taskToEdit;

  const TaskPage({
    super.key,
    required this.selectedDate,
    this.initialDateRange,
    this.taskToEdit,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  TaskType? _selectedType;
  TimeOfDay? _selectedTime;
  String _selectedAlarmSound = "Default Alarm";
  DateTimeRange? _selectedDateRange;
  AppInfo? _selectedApp;
  bool _isRecording = false;
  late final Future<List<AppInfo>> _installedAppsFuture;
  static const MethodChannel _recorderChannel = MethodChannel('touch_recorder/methods');

  @override
  void initState() {
    super.initState();
    _installedAppsFuture = InstalledApps.getInstalledApps(false, true);
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descriptionController.text = task.note ?? '';
      _selectedType = task.type;
      if (task.repeatingCount != null) {
        _countController.text = task.repeatingCount.toString();
      }
      if (task.folderPath != null) {
        _folderController.text = task.folderPath!;
      }
      if (task.recordingPath != null) {
        _fileController.text = task.recordingPath!;
      }
      if (task.dateRange != null) {
        _selectedDateRange = DateTimeRange(start: task.dateRange!.start, end: task.dateRange!.end);
      }
      if (task.timeToTrigger != null && task.timeToTrigger!.contains(':')) {
        final parts = task.timeToTrigger!.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _selectedTime = TimeOfDay(hour: h, minute: m);
        }
      }
      if (task.soundOrVibration != null && task.soundOrVibration!.isNotEmpty) {
        _selectedAlarmSound = task.soundOrVibration!;
      }
    } else {
      if (widget.initialDateRange != null) {
        _selectedDateRange = widget.initialDateRange;
      }
      _loadDefaultAlarmSound();
    }
  }

  Future<void> _loadDefaultAlarmSound() async {
    try {
      final box = await Hive.openBox('settings_box');
      final savedSound = box.get('default_alarm_sound', defaultValue: "Default Alarm Sound");
      if (mounted) {
        setState(() {
          _selectedAlarmSound = savedSound;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _countController.dispose();
    _folderController.dispose();
    _fileController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final String? filePath = await FilePicker.platform
          .pickFiles(type: FileType.any)
          .then((result) => result?.files.single.path);

      if (filePath != null && mounted) {
        setState(() {
          _fileController.text = filePath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File picking failed: $e")),
        );
      }
    }
  }

  Future<void> _pickFolder() async {
    try {
      final String? folderPath = await FilePicker.platform.getDirectoryPath();

      if (folderPath != null && mounted) {
        setState(() {
          _folderController.text = folderPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Folder picking failed: $e")),
        );
      }
    }
  }

  String _formatEnum(TaskType type) {
    final name = type.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData _getIconForType(TaskType type) {
    switch (type) {
      case TaskType.count:
        return Icons.calculate;
      case TaskType.appPerform:
        return Icons.mic;
      case TaskType.appLaunch:
        return Icons.launch;
      case TaskType.folderOpen:
        return Icons.folder_open;
      case TaskType.fileOpen:
        return Icons.insert_drive_file;
      case TaskType.feedback:
        return Icons.feedback;
      default:
        return Icons.task_alt;
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black54),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF1273C2), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a task title."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final String? description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final timeString = _selectedTime != null
        ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}"
        : null;

    final int? targetCount = _selectedType == TaskType.count
        ? int.tryParse(_countController.text.trim())
        : null;

    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      task.title = title;
      task.note = description;
      task.type = _selectedType ?? TaskType.normal;
      task.repeatingCount = targetCount;
      task.timeToTrigger = timeString;
      task.alarmEnabled = timeString != null;
      if (_selectedApp?.packageName != null) {
        task.appToLaunch = _selectedApp!.packageName;
      }
      task.folderPath = _selectedType == TaskType.folderOpen ? _folderController.text.trim() : null;
      task.recordingPath = _selectedType == TaskType.fileOpen ? _fileController.text.trim() : null;
      task.dateRange = _selectedDateRange != null
          ? DateTimeRangeHive(start: _selectedDateRange!.start, end: _selectedDateRange!.end)
          : null;
      task.soundOrVibration = _selectedAlarmSound;
      task.lastModified = DateTime.now();
      try {
        task.save();
      } catch (_) {}
      taskList.value = List.from(taskList.value);
    } else {
      final newTask = TaskModel(
        id: id,
        title: title,
        note: description,
        date: widget.selectedDate,
        dateRange: _selectedDateRange != null
            ? DateTimeRangeHive(start: _selectedDateRange!.start, end: _selectedDateRange!.end)
            : null,
        type: _selectedType ?? TaskType.normal,
        isCompleted: false,
        isSkipped: false,
        repeatingCount: targetCount,
        currentCount: _selectedType == TaskType.count ? 0 : null,
        timeToTrigger: timeString,
        alarmEnabled: timeString != null,
        soundOrVibration: _selectedAlarmSound,
        appToLaunch: _selectedApp?.packageName,
        folderPath: _selectedType == TaskType.folderOpen ? _folderController.text.trim() : null,
        recordingPath: _selectedType == TaskType.fileOpen ? _fileController.text.trim() : null,
        isFavorite: false,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      // Update global task list
      taskList.value = [...taskList.value, newTask];
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _deleteTask() {
    if (widget.taskToEdit == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Task", style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this task?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              try {
                widget.taskToEdit!.delete();
              } catch (_) {}
              taskList.value = taskList.value.where((t) => t.id != widget.taskToEdit!.id).toList();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task deleted successfully")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({
    required String text,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.oxanium(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskFields(TaskType? selectedType) {
    if (selectedType == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedType == TaskType.count) ...[
          const Text("Count Target", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _countController,
            decoration: _inputDecoration("Enter target count (e.g. 20)"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
        ],
        if (selectedType == TaskType.appPerform || selectedType == TaskType.appLaunch) ...[
          const Text("App Name", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          FutureBuilder<List<AppInfo>>(
            future: _installedAppsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1273C2)));
              } else if (snapshot.hasError) {
                return Text("❌ Error loading apps: ${snapshot.error}");
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("⚠️ No apps found");
              }

              final apps = snapshot.data!;
              return DropdownButtonFormField<AppInfo>(
                isExpanded: true,
                value: _selectedApp,
                decoration: _inputDecoration("Select App"),
                items: apps.map((app) {
                  return DropdownMenuItem<AppInfo>(
                    value: app,
                    child: Row(
                      children: [
                        if (app.icon != null)
                          Image.memory(app.icon!, width: 24, height: 24, fit: BoxFit.contain)
                        else
                          const Icon(Icons.apps, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            app.name.isNotEmpty ? app.name : app.packageName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (app) {
                  setState(() {
                    _selectedApp = app;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),
          if (selectedType == TaskType.appPerform)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!_isRecording)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1273C2),
                    ),
                    icon: const Icon(Icons.fiber_manual_record, color: Colors.red),
                    label: const Text('Start Recording'),
                    onPressed: () async {
                      if (_selectedApp != null) {
                        try {
                          final bool hasOverlay = await _recorderChannel.invokeMethod<bool>('checkOverlayPermission') ?? false;
                          if (!hasOverlay) {
                            await _recorderChannel.invokeMethod('requestOverlayPermission');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enable 'Display over other apps' permission for Chrono List."),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            return;
                          }

                          final bool hasAccessibility = await _recorderChannel.invokeMethod<bool>('checkAccessibilityPermission') ?? false;
                          if (!hasAccessibility) {
                            await _recorderChannel.invokeMethod('requestAccessibilityPermission');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enable Accessibility Service for Chrono List in Settings."),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            return;
                          }

                          await _recorderChannel.invokeMethod('startRecording');
                          setState(() {
                            _isRecording = true;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          await InstalledApps.startApp(_selectedApp!.packageName);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Start recording: $e")),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select an app first.")),
                        );
                      }
                    },
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_circle, color: Colors.white),
                    label: const Text('Stop & Save'),
                    onPressed: () async {
                      try {
                        await _recorderChannel.invokeMethod('stopRecording');
                        final String? savedPath = await _recorderChannel.invokeMethod<String>('saveRecording');
                        setState(() {
                          _isRecording = false;
                          if (savedPath != null) {
                            _fileController.text = savedPath;
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Recording stopped and saved!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Stop recording error: $e")),
                          );
                        }
                      }
                    },
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1273C2),
                  ),
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF1273C2)),
                  label: const Text('Replay Actions'),
                  onPressed: () async {
                    if (_selectedApp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select an app first.")),
                      );
                      return;
                    }
                    try {
                      final bool? success = await _recorderChannel.invokeMethod<bool>('replayTouches', {
                        'packageName': _selectedApp!.packageName,
                        'filePath': _fileController.text.trim().isNotEmpty ? _fileController.text.trim() : null,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success == true
                                ? "Opening ${_selectedApp!.name} & replaying actions..."
                                : "No recorded actions found to replay."),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Replay error: $e")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
        if (selectedType == TaskType.folderOpen) ...[
          const Text("Folder Path", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _folderController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Select Folder Path',
              hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
              suffixIcon: const Icon(Icons.folder, color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1273C2), width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            onTap: _pickFolder,
          ),
          const SizedBox(height: 12),
        ],
        if (selectedType == TaskType.fileOpen) ...[
          const Text("File Path", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fileController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Select File Path',
              hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
              suffixIcon: const Icon(Icons.insert_drive_file, color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1273C2), width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            onTap: _pickFile,
          ),
          const SizedBox(height: 12),
        ],
        if (selectedType == TaskType.feedback) ...[
          const Text("Feedback Notes", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: _inputDecoration("Enter feedback details"),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDateRangePickerField() {
    final String dateText = _selectedDateRange != null
        ? "${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)}  →  ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}"
        : "Select multiple dates";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Task Date / Date Range", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedDateRange != null ? const Color(0xFF1273C2) : Colors.black54,
              width: _selectedDateRange != null ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromToDateRange,
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedDateRange != null ? const Color(0xFF1273C2) : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (_selectedDateRange != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                  child: const Icon(Icons.clear, size: 22, color: Colors.red),
                )
              else
                GestureDetector(
                  onTap: _pickFromToDateRange,
                  child: const Icon(Icons.date_range, color: Color(0xFF1273C2)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromToDateRange() async {
    final fromDate = await showCustomDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? widget.selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000, 12, 31),
      title: "FROM DATE",
    );
    if (fromDate == null || !mounted) return;

    final toDate = await showCustomDatePicker(
      context: context,
      initialDate: _selectedDateRange?.end ?? fromDate,
      firstDate: fromDate,
      lastDate: DateTime(3000, 12, 31),
      title: "TO DATE",
    );
    if (toDate == null || !mounted) return;

    setState(() {
      _selectedDateRange = DateTimeRange(start: fromDate, end: toDate);
    });
  }

  Widget _buildTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Time", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                _selectedTime = pickedTime;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black54),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : "Select Trigger Time (Optional)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedTime != null ? Colors.black : Colors.black54,
                  ),
                ),
                if (_selectedTime != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = null;
                      });
                    },
                    child: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  )
                else
                  const Icon(Icons.access_time, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmSoundPickerField() {
    final options = ["Default Alarm", "Digital Chime", "Gentle Bell", "Loud Siren", "Vibration Only", "Silent"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text("Time Trigger Alarm Sound", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: options.contains(_selectedAlarmSound) ? _selectedAlarmSound : "Default Alarm",
          items: options.map((sound) {
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
                    size: 18,
                    color: const Color(0xFF1273C2),
                  ),
                  const SizedBox(width: 10),
                  Text(sound, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedAlarmSound = val;
              });
            }
          },
          decoration: _inputDecoration("Select Alarm Sound"),
          isExpanded: true,
          dropdownColor: Colors.grey[100],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskTypes = TaskType.values;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      _selectedDateRange != null
                          ? 'Tasks for multiple days'
                          : 'Tasks for ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}',
                      style: GoogleFonts.oxanium(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Task Title *", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration("Enter task title"),
                    ),
                    const SizedBox(height: 12),
                    const Text("Task Description", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration("Enter task description"),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedDateRange != null) ...[
                      _buildDateRangePickerField(),
                      const SizedBox(height: 12),
                    ],
                    _buildTimePickerField(),
                    _buildAlarmSoundPickerField(),
                    const SizedBox(height: 12),
                    const Text("Task Type", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TaskType>(
                      value: _selectedType,
                      hint: const Text(
                        "Select task type",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                      ),
                      items: taskTypes.map((type) {
                        return DropdownMenuItem<TaskType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getIconForType(type), size: 18, color: const Color(0xFF1273C2)),
                              const SizedBox(width: 10),
                              Text(
                                _formatEnum(type),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      },
                      decoration: _inputDecoration("Select Task Type"),
                      isExpanded: true,
                      dropdownColor: Colors.grey[100],
                    ),
                    const SizedBox(height: 12),
                    _buildTaskFields(_selectedType),
                    const SizedBox(height: 20),
                    // Action Buttons
                    if (widget.taskToEdit != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildPremiumButton(
                              text: "Delete",
                              icon: Icons.delete_outline_rounded,
                              gradientColors: [const Color(0xFFE53935), const Color(0xFF8E0000)],
                              shadowColor: const Color(0x66E53935),
                              onTap: _deleteTask,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildPremiumButton(
                              text: "Save",
                              icon: Icons.save_rounded,
                              gradientColors: [const Color(0xFF1E88E5), const Color(0xFF0D47A1)],
                              shadowColor: const Color(0x661E88E5),
                              onTap: _saveTask,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildPremiumButton(
                        text: "Save Task",
                        icon: Icons.save_rounded,
                        gradientColors: [const Color(0xFF1E88E5), const Color(0xFF0D47A1)],
                        shadowColor: const Color(0x661E88E5),
                        onTap: _saveTask,
                      ),
                    ],
                    const SizedBox(height: 30),
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
