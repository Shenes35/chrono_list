import 'package:chrono_list/model/task_model.dart';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for describeEnum
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/src/material/material_state.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:file_selector/file_selector.dart';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For external storage paths






Future<List<AppInfo>> fetchInstalledApps() async {
  return await InstalledApps.getInstalledApps(true, true); 
  // (includeSystemApps, includeIcons)
}




class TaskPage extends StatelessWidget {
  final DateTime selectedDate;
  final ValueNotifier<String?> filePathNotifier = ValueNotifier<String?>(null);
final TextEditingController fileController = TextEditingController();
final ValueNotifier<AppInfo?> selectedAppNotifier = ValueNotifier<AppInfo?>(null);
static const recorderChannel = MethodChannel('your.plugin/recorder');
TextEditingController folderController = TextEditingController();
  TaskPage({super.key, required this.selectedDate}) {
  // Sync notifier changes to the controller
  folderPathNotifier.addListener(() {
    folderController.text = folderPathNotifier.value ?? '';
  });
}
Future<void> pickFile(BuildContext context) async {
  try {
    print("📄 [DEBUG] File picker triggered.");

    String? filePath = await FilePicker.platform.pickFiles(
      type: FileType.any
    ).then((result) => result?.files.single.path);

    if (filePath != null) {
      filePathNotifier.value = filePath;
      fileController.text = filePath;
      print("✅ File selected: $filePath");
    } else {
      print("⚠️ File picker cancelled.");
    }
  } catch (e) {
    print("❌ File picking failed: $e");
  }
}

Future<void> pickFolder(BuildContext context) async {
  try {
    print("📂 [DEBUG] Folder picker triggered.");

    String? folderPath = await FilePicker.platform.getDirectoryPath();

    if (folderPath != null) {
      folderPathNotifier.value = folderPath;
      folderController.text = folderPath; // <-- add this line!
      print("✅ Folder selected: $folderPath");
    } else {
      print("⚠️ Folder picker cancelled.");
    }
  } catch (e) {
    print("❌ Folder picking failed: $e");
  }
}

final ValueNotifier<String?> folderPathNotifier = ValueNotifier<String?>(null);


  final ValueNotifier<TaskType?> selectedTypeNotifier = ValueNotifier<TaskType?>(null);
  TimeOfDay? selectedTime;
  final ValueNotifier<TimeOfDay?> selectedTimeNotifier = ValueNotifier<TimeOfDay?>(null);

  // Capitalize enum name (e.g., "count" -> "Count")
  String formatEnum(TaskType type) {
    final name = type.name;
    return name[0].toUpperCase() + name.substring(1);
  }
  Widget _buildTaskFields(TaskType? selectedType) {
  if (selectedType == null) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (selectedType == TaskType.count) ...[
        const Text("Count Target"),
        const SizedBox(height: 6),
        TextField(
          decoration: _inputDecoration("Enter target count"),
          keyboardType: TextInputType.number,
        ),
      ],
    
      if (selectedType == TaskType.appPerform) ...[
  const Text("App Name"),
  const SizedBox(height: 6),
  FutureBuilder<List<AppInfo>>(
    future: InstalledApps.getInstalledApps(true, true),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator(color: Color(0xFF1273C2));
      } else if (snapshot.hasError) {
        return Text("❌ Error loading apps: ${snapshot.error}");
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text("⚠️ No apps found");
      }

      final apps = snapshot.data!;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Colors.blue,
          ),
        ),
        child: ValueListenableBuilder<AppInfo?>(
          valueListenable: selectedAppNotifier,
          builder: (context, selectedApp, _) => DropdownButtonFormField<AppInfo>(
            isExpanded: true,
            value: selectedApp,
            decoration: const InputDecoration(
              labelText: "Select App",
              labelStyle: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              border: OutlineInputBorder(),
            ),
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
                        app.name ?? app.packageName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (app) {
              selectedAppNotifier.value = app;
            },
          ),
        ),
      );
    },
  ),
  const SizedBox(height: 16),
  Row(
    children: [
      ValueListenableBuilder<AppInfo?>(
        valueListenable: selectedAppNotifier,
        builder: (context, selectedApp, _) => ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1273C2),
          ),
          icon: const Icon(Icons.fiber_manual_record, color: Color(0xFF1273C2)),
          label: const Text('Record Actions', style: TextStyle(color: Color(0xFF1273C2))),
          onPressed: () async {
  final selectedApp = selectedAppNotifier.value;
  if (selectedApp != null) {
  // 1. Ask native to display floating 'Start Recording' overlay
  try {
    await recorderChannel.invokeMethod('showOverlayButton'); // <- Change this!
  } catch (e) {
    print("Failed to start overlay: $e");
    return;
  }
  
  // 2. Wait 5 seconds before launching the app
  await Future.delayed(Duration(seconds: 5));

  // 3. Launch the selected app
  await InstalledApps.startApp(selectedApp.packageName);

  // Native overlay keeps running the whole time!
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please select an app first pls."))
  );
}

}
 
        ),
      ),
      const SizedBox(width: 10),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1273C2),
        ),
        icon: const Icon(Icons.play_arrow, color: Color(0xFF1273C2)),
        label: const Text('Play Actions', style: TextStyle(color: Color(0xFF1273C2))),
        onPressed: () {
          // TODO: Implement play actions logic if desired
        },
      ),
    ],
  ),
],

      if (selectedType == TaskType.folderOpen) ...[
  const Text("📁 Folder Path"),
  const SizedBox(height: 6),
  ValueListenableBuilder<String?>(
    valueListenable: folderPathNotifier,
    builder: (context, value, _) {
      // Only update controller if different (avoids cursor jump/loop)
      if (folderController.text != (value ?? '')) {
        folderController.text = value ?? '';
      }
      return TextFormField(
        controller: folderController,
        readOnly: true,
        decoration:  InputDecoration(
          hintText: 'Folder Path',
          hintStyle:TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          suffixIcon: Icon(Icons.folder,color: Colors.black,),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1273C2), width: 2), ),
        fillColor: Colors.white, filled: true, ),
        onTap: () {
          pickFolder(context); // Pop up the folder picker dialog
        },
      );
    },
  ),
],

if (selectedType == TaskType.fileOpen) ...[
  const Text("📄 File Path"),
  const SizedBox(height: 6),
  ValueListenableBuilder<String?>(
    valueListenable: filePathNotifier,
    builder: (context, value, _) {
      if (fileController.text != (value ?? '')) {
        fileController.text = value ?? '';
      }
      return TextFormField(
        controller: fileController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'File Path',
          hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          suffixIcon: Icon(Icons.insert_drive_file, color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1273C2), width: 2),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        onTap: () {
          pickFile(context); // Open the file picker dialog
        },
      );
    },
  ),
],


      if (selectedType == TaskType.feedback) ...[
        const Text("Feedback Notes"),
        const SizedBox(height: 6),
        TextField(
          maxLines: 3,
          decoration: _inputDecoration("Enter feedback details"),
        ),
      ],
    ],
  );
}

Widget buildTimePickerField({
  required BuildContext context,
  required ValueNotifier<TimeOfDay?> selectedTimeNotifier,
  required String label,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      ValueListenableBuilder<TimeOfDay?>(
        valueListenable: selectedTimeNotifier,
        builder: (context, selectedTime, _) {
          return DropdownButtonFormField<String>(
            decoration: _inputDecoration("Select time"),
            value: selectedTime == null ? 'None' : 'Time',
            items: const [
              DropdownMenuItem(
                value: 'Time',
                child: Text('Select Time...'),
              ),
              DropdownMenuItem(
                value: 'None',
                child: Text('None'),
              ),
            ],
            onChanged: (value) async {
              if (value == 'None') {
                selectedTimeNotifier.value = null;
              } else {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        timePickerTheme: const TimePickerThemeData(
                          dialHandColor: Colors.grey,
                          dialBackgroundColor: Colors.white,
                          hourMinuteTextColor: Colors.black,
                          hourMinuteColor: Colors.grey,
                          entryModeIconColor: Colors.black,
                          dayPeriodColor: Colors.grey,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  selectedTimeNotifier.value = pickedTime;
                }
              }
            },
            selectedItemBuilder: (context) {
              return ['Time', 'None'].map((value) {
                final display = selectedTime?.format(context) ?? 'None';
                return Text(display);
              }).toList();
            },
          );
        },
      ),
    ],
  );
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF1273C2), width: 2),
    ),
    fillColor: Colors.white,
    filled: true,
  );
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
      case TaskType.feedback:
        return Icons.feedback;
      default:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF282727), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              height: 60,
              child: Row(
                children: [
                  GestureDetector(
  onTap: () => Navigator.pop(context),
  child: const Icon(Icons.arrow_back, color: Colors.white),
),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tasks for ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                      style: GoogleFonts.oxanium(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Task Title"),
                  const SizedBox(height: 6),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter task title",
                      hintStyle:TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF1273C2), width: 2),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Task Description"),
                  const SizedBox(height: 6),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter task description",
                      hintStyle:TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF1273C2), width: 2),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildTimePickerField(
    context: context,
    selectedTimeNotifier: selectedTimeNotifier,
    label: "Time",
  ),
  const SizedBox(height: 12),
                  const Text("Task Type"),
                  const SizedBox(height: 6),

                  // Dropdown
                  ValueListenableBuilder<TaskType?>(
                    valueListenable: selectedTypeNotifier,
                    builder: (context, selectedType, _) {
                      final taskTypes = TaskType.values.where((t) => t != TaskType.normal).toList();

                      return DropdownButtonFormField<TaskType>(
                        value: selectedType,
                  
                        hint: const Text(
                          "Select task type",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                        items: taskTypes.map((type) {
                          return DropdownMenuItem<TaskType>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getIconForType(type), size: 18, color: Color(0xFF1273C2)),
                                const SizedBox(width: 10),
                                Text(
                                  formatEnum(type),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return taskTypes.map((type) {
                            return Row(
                              children: [
                                Icon(_getIconForType(type), size: 18, color: Color(0xFF1273C2)),
                                const SizedBox(width: 8),
                                Text(
                                  formatEnum(type),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        onChanged: (newValue) {
                          selectedTypeNotifier.value = newValue!;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black,),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF1273C2), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        
                        isExpanded: true,


                        dropdownColor: Colors.grey[100],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
ValueListenableBuilder<TaskType?>(
  valueListenable: selectedTypeNotifier,
  builder: (context, selectedType, _) {
    return _buildTaskFields(selectedType);
  },
),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
