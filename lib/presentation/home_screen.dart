import 'dart:async';
import 'package:chrono_list/core/task_core.dart';
import 'package:chrono_list/model/task_model.dart';
import 'package:chrono_list/presentation/custom_calender.dart';
import 'package:chrono_list/presentation/settings_screen.dart';
import 'package:chrono_list/presentation/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
 int _selectedBottomIndex = 0;// 0 = Home, 1 = Analytics, 2 = Notifications, 3 = Profile

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isExpanded = false;
  

  

  Timer? _alarmCheckTimer;
  final Set<String> _notified5MinTasks = {};
  final Set<String> _alarmTriggeredTasks = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _selectedBottomIndex = 0;
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkTaskAlarmsAndNotifications();
    });
    try {
      const MethodChannel('touch_recorder/methods').invokeMethod('startPersistentService');
    } catch (_) {}
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    super.dispose();
  }

  void _checkTaskAlarmsAndNotifications() {
    final now = DateTime.now();
    const methodChannel = MethodChannel('touch_recorder/methods');

    for (final task in taskList.value) {
      if (task.isCompleted || task.isSkipped || task.timeToTrigger == null) continue;
      if (!task.timeToTrigger!.contains(':')) continue;

      if (!_isTaskForSelectedDay(task, now)) continue;

      final parts = task.timeToTrigger!.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;

      final taskDateTime = DateTime(now.year, now.month, now.day, h, m);
      final diffInSeconds = taskDateTime.difference(now).inSeconds;

      // 1. 5 Minutes Prior Notification
      final notifKey = "${task.id}_5min_${now.year}${now.month}${now.day}";
      if (diffInSeconds >= 270 && diffInSeconds <= 330 && !_notified5MinTasks.contains(notifKey)) {
        _notified5MinTasks.add(notifKey);
        methodChannel.invokeMethod('showNotification', {
          'title': 'Upcoming Task in 5 Minutes',
          'message': "'${task.title}' is scheduled for ${DateFormat('hh:mm a').format(taskDateTime)}",
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⏰ Notification: '${task.title}' starts in 5 minutes!"),
              backgroundColor: const Color(0xFF1273C2),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // 2. Exact Task Alarm Trigger
      final alarmKey = "${task.id}_alarm_${now.year}${now.month}${now.day}_$h:$m";
      if (diffInSeconds.abs() <= 45 && !_alarmTriggeredTasks.contains(alarmKey)) {
        _alarmTriggeredTasks.add(alarmKey);

        methodChannel.invokeMethod('playAlarmSound', {
          'soundType': task.soundOrVibration ?? 'Default Alarm Sound',
          'durationSeconds': 15,
          'volume': 0.9,
        });

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.amberAccent, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    "TASK ALARM",
                    style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.oxanium(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scheduled for ${DateFormat('hh:mm a').format(taskDateTime)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (task.note != null && task.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text("Note: ${task.note}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    methodChannel.invokeMethod('stopAlarmSound');
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.alarm_off, color: Colors.white),
                  label: Text("Dismiss Alarm", style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  bool _isTaskForSelectedDay(TaskModel task, DateTime selectedDate) {
    if (task.date.year == selectedDate.year &&
        task.date.month == selectedDate.month &&
        task.date.day == selectedDate.day) {
      return true;
    }
    if (task.dateRange != null) {
      final start = task.dateRange!.start;
      final end = task.dateRange!.end;
      if (!selectedDate.isBefore(start) && !selectedDate.isAfter(end)) {
        return true;
      }
    }
    if (task.repeatPattern != null && task.repeatPattern!.isNotEmpty) {
      final weekdayIndex = selectedDate.weekday % 7;
      if (task.repeatPattern!.contains(weekdayIndex)) {
        return true;
      }
    }
    return false;
  }

  Widget _verticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.black,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                if (_selectedBottomIndex == 0)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const LiveClockWidget(),
                          _buildDateHeader(),
                          _buildCalendar(),
                        ],
                      ),
                    ),
                  )
                else if (_selectedBottomIndex == 1) ...[
                  _buildTaskProgressCard(),
                  Expanded(
                    child: _buildTaskList(),
                  ),
                ] else if (_selectedBottomIndex == 2) ...[
                  Expanded(
                    child: _buildNotificationsView(),
                  ),
                ] else if (_selectedBottomIndex == 3) ...[
                  Expanded(
                    child: _buildProfileView(),
                  ),
                ],
              ],
            ),


            // Bottom App Bar with FABs
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isExpanded)
  Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              // You can toggle left button shape independently if you want,
              // or toggle _isExpanded again if you want both together.
              // Here just toggling _isExpanded for demo:
              _isExpanded = false;
            });
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle, // or toggle to rectangle if you want here
              gradient: const LinearGradient(
                colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'leftFab',
              tooltip: 'Edit tasks',
              mini: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                setState(() {
                  _isExpanded = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskPage(selectedDate: _selectedDay),
                  ),
                );
              },
              child: const Icon(Icons.edit, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = false;
            });
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'rightFab',
              tooltip: 'Add tasks',
              mini: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                setState(() {
                  _isExpanded = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskPage(selectedDate: _selectedDay),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ),
      ],
    ),
  ),

                    
                  BottomAppBar(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, -2),
                        ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                         IconButton(
  icon: _selectedBottomIndex == 0
      ? ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
          ).createShader(bounds),
          child: const Icon(Icons.home, color: Colors.white),
        )
      : const Icon(Icons.home, color: Colors.black),
  tooltip: 'Home',
  onPressed: () {
    setState(() {
      _selectedBottomIndex = 0;
    });
  },
),

_verticalDivider(),

IconButton(
  icon: _selectedBottomIndex == 1
      ? ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
          ).createShader(bounds),
          child: const Icon(Icons.bar_chart, color: Colors.white),
        )
      : const Icon(Icons.bar_chart, color: Colors.black),
  tooltip: 'Analytics',
  onPressed: () {
    setState(() {
      _selectedBottomIndex = 1;
    });
  },
),

const SizedBox(width: 60), // Space for FAB

IconButton(
  icon: _selectedBottomIndex == 2
      ? ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
          ).createShader(bounds),
          child: const Icon(Icons.notifications, color: Colors.white),
        )
      : const Icon(Icons.notifications, color: Colors.black),
  tooltip: 'Notifications',
  onPressed: () {
    setState(() {
      _selectedBottomIndex = 2;
    });
  },
),

_verticalDivider(),

IconButton(
  icon: _selectedBottomIndex == 3
      ? ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
          ).createShader(bounds),
          child: const Icon(Icons.person, color: Colors.white),
        )
      : const Icon(Icons.person, color: Colors.black),
  tooltip: 'Profile',
  onPressed: () {
    setState(() {
      _selectedBottomIndex = 3;
    });
  },
),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) =>
      ScaleTransition(scale: animation, child: child),
  child: GestureDetector(
    key: ValueKey<bool>(_isExpanded),
    onTap: () {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    },
    child: Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.lightBlueAccent, Color.fromARGB(255, 3, 99, 177)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: Icon(
          _isExpanded ? Icons.event_busy : Icons.edit_calendar,
          color: Colors.black,
          size: 30,
        ),
      ),
    ),
  ),
),


            ),
          ],
        ),
        drawerEnableOpenDragGesture: false,
        drawer: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: Drawer(
            width: MediaQuery.of(context).size.width * 0.50,
            backgroundColor: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 60,
                  child: Container(
                    color: Colors.grey[900],
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 35),
                    child: Text(
                      'Menu',
                      style: GoogleFonts.baloo2(
                        textStyle: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black87),
                  title: Text('Settings', style: GoogleFonts.oxanium(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: Center(
            child: Text(
              'Chrono List',
              style: GoogleFonts.baloo2(
                textStyle: const TextStyle(
                  fontSize: 37,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.search, color: Colors.black, size: 30),
              tooltip: 'Search',
              onPressed: () {},
            ),
          ],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 30),
              tooltip: 'Menu',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF282727), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('yyyy-MM-dd').format(_selectedDay),
              style: GoogleFonts.oxanium(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: const [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.lightBlueAccent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.event_note),
            color: Colors.lightBlueAccent,
            tooltip: 'Change Date Range',
            onPressed: _selectDateRangeAndOpenTaskPage,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.lightBlueAccent,
            tooltip: 'Edit Tasks',
            onPressed: () {
              final tasksForDay = taskList.value.where((t) => _isTaskForSelectedDay(t, _selectedDay)).toList();
              if (tasksForDay.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No tasks to edit for this date.")),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      "Select Task to Edit",
                      style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tasksForDay.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white24),
                        itemBuilder: (context, index) {
                          final task = tasksForDay[index];
                          return ListTile(
                            title: Text(
                              task.title,
                              style: GoogleFonts.oxanium(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "Type: ${task.type.name}${task.timeToTrigger != null ? ' | Time: ${task.timeToTrigger}' : ''}",
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.lightBlueAccent),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskPage(
                                    selectedDate: _selectedDay,
                                    taskToEdit: task,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.lightBlueAccent,
            tooltip: 'Add Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskPage(selectedDate: _selectedDay),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRangeAndOpenTaskPage() async {
    final fromDate = await showCustomDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000, 12, 31),
      title: "FROM DATE",
    );
    if (fromDate == null || !mounted) return;

    final toDate = await showCustomDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: fromDate,
      lastDate: DateTime(3000, 12, 31),
      title: "TO DATE",
    );
    if (toDate == null || !mounted) return;

    setState(() {
      _selectedDay = fromDate;
      _focusedDay = fromDate;
    });

    final DateTimeRange? range = fromDate.year == toDate.year &&
            fromDate.month == toDate.month &&
            fromDate.day == toDate.day
        ? null
        : DateTimeRange(start: fromDate, end: toDate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskPage(
          selectedDate: fromDate,
          initialDateRange: range,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF282727), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: SizedBox(
        height: 270,
        child: TableCalendar(
          firstDay: DateTime.utc(1900, 1, 1),
          lastDay: DateTime.utc(3000, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
            todayDecoration: const BoxDecoration(
              color: Color.fromARGB(255, 58, 115, 214),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFFFF9800),
              shape: BoxShape.rectangle,
            ),
            todayTextStyle: GoogleFonts.oxanium(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            selectedTextStyle: GoogleFonts.oxanium(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: GoogleFonts.oxanium(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            weekendTextStyle: GoogleFonts.oxanium(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlueAccent,
            ),
          ),
          headerStyle: HeaderStyle(
            headerPadding: EdgeInsets.zero,
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            titleTextStyle: GoogleFonts.oxanium(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            titleTextFormatter: (date, locale) => DateFormat.yMMM(locale).format(date),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.oxanium(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            weekendStyle: GoogleFonts.oxanium(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              if (date.weekday == DateTime.sunday) {
                return Center(
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.oxanium(
                      fontSize: 13,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return null;
            },
            dowBuilder: (context, day) {
              if (day.weekday == DateTime.sunday) {
                return Center(
                  child: Text(
                    'Sun',
                    style: GoogleFonts.oxanium(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          rowHeight: 30,
          availableGestures: AvailableGestures.none,
        ),
      ),
    );
  }

  Widget _buildTaskProgressCard() {
    return ValueListenableBuilder<List<TaskModel>>(
      valueListenable: taskList,
      builder: (context, tasks, _) {
        final filteredTasks = tasks.where((t) => _isTaskForSelectedDay(t, _selectedDay)).toList();
        final totalTasks = filteredTasks.length;
        final completedTasks = filteredTasks.where((task) => task.isCompleted).length;
        final progressPercent = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        return Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 40, 39, 39), Color.fromARGB(255, 0, 0, 0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Task \nProgress",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "$completedTasks of $totalTasks tasks completed",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        DateFormat('yyyy/MM/dd').format(DateTime.now()),
                        style: GoogleFonts.oxanium(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 251, 252, 252),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1B2B),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                                ),
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final filledWidth = constraints.maxWidth * progressPercent;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: filledWidth,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 64, 166, 238),
                                              Color(0xFF0072FF),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: (filledWidth - 10).clamp(0.0, (constraints.maxWidth - 22).clamp(0.0, double.infinity)),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.blue,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent,
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            "${(progressPercent * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return ValueListenableBuilder<List<TaskModel>>(
      valueListenable: taskList,
      builder: (context, tasks, _) {
        final filteredTasks = tasks.where((t) => _isTaskForSelectedDay(t, _selectedDay)).toList();
        // Sort so not done (pending) tasks (including count tasks not finished) come to the top
        filteredTasks.sort((a, b) {
          final int scoreA = a.isCompleted ? 2 : (a.isSkipped ? 1 : 0);
          final int scoreB = b.isCompleted ? 2 : (b.isSkipped ? 1 : 0);
          return scoreA.compareTo(scoreB);
        });

        if (filteredTasks.isEmpty) {
          return Center(
            child: Text(
              "No tasks scheduled for this date",
              style: GoogleFonts.oxanium(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            final bool isSkipped = task.isSkipped;
            final bool isDone = task.isCompleted;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSkipped
                      ? [const Color(0xFF4A1E1E), const Color(0xFF200000)]
                      : isDone
                          ? [const Color(0xFF1E3A20), const Color(0xFF0A200B)]
                          : [const Color(0xFF282727), const Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSkipped
                      ? Colors.redAccent
                      : isDone
                          ? Colors.greenAccent
                          : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: task.type == TaskType.count
                          ? () {
                              if (!task.isCompleted) {
                                final current = task.currentCount ?? 0;
                                final target = task.repeatingCount ?? 1;
                                final next = current + 1;
                                task.currentCount = next;
                                if (next >= target) {
                                  task.isCompleted = true;
                                  task.isSkipped = false;
                                }
                                taskList.value = List.from(taskList.value);
                              }
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.oxanium(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 251, 252, 252),
                            ),
                          ),
                          if (task.timeToTrigger != null)
                            Text(
                              "Time: ${task.timeToTrigger}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          if (task.type == TaskType.count && task.repeatingCount != null)
                            Text(
                              "Count: ${task.currentCount ?? 0} / ${task.repeatingCount}",
                              style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (task.type == TaskType.count) {
                        final current = task.currentCount ?? 0;
                        final target = task.repeatingCount ?? 1;
                        final next = current + 1;
                        task.currentCount = next;
                        if (next >= target) {
                          task.isCompleted = true;
                          task.isSkipped = false;
                        }
                        taskList.value = List.from(taskList.value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("'${task.title}' count updated: $next/$target")),
                          );
                        }
                      } else if (task.type == TaskType.appPerform || (task.appToLaunch != null && task.appToLaunch!.isNotEmpty)) {
                        final methodChannel = MethodChannel('touch_recorder/methods');
                        try {
                          await methodChannel.invokeMethod('performAppSequence', {
                            'packageName': task.appToLaunch ?? 'org.telegram.messenger',
                            'x': 500.0,
                            'y': 1000.0,
                            'delaySeconds': 2,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Auto app performance started for '${task.title}'")),
                            );
                          }
                        } catch (e) {
                          if (task.appToLaunch != null && task.appToLaunch!.isNotEmpty) {
                            try {
                              await InstalledApps.startApp(task.appToLaunch!);
                            } catch (err) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Could not launch app: $err")),
                                );
                              }
                            }
                          }
                        }
                      } else if (task.folderPath != null && task.folderPath!.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Opening folder: ${task.folderPath}")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Direct action performed for '${task.title}'")),
                        );
                      }
                    },
                    child: const Text(
                      'Direct',
                      style: TextStyle(color: Colors.yellow),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      task.isSkipped = !task.isSkipped;
                      if (task.isSkipped) {
                        task.isCompleted = false;
                      }
                      taskList.value = List.from(taskList.value);
                    },
                    child: Text(
                      task.isSkipped ? 'Unskip' : 'Skip',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (task.type == TaskType.count) {
                        if (task.isCompleted) {
                          task.isCompleted = false;
                          task.currentCount = 0;
                        } else {
                          task.currentCount = task.repeatingCount ?? 1;
                          task.isCompleted = true;
                          task.isSkipped = false;
                        }
                      } else {
                        task.isCompleted = !task.isCompleted;
                        if (task.isCompleted) {
                          task.isSkipped = false;
                        }
                      }
                      taskList.value = List.from(taskList.value);
                    },
                    child: Text(
                      task.isSkipped ? 'Unskip' : (task.isCompleted ? 'Undo' : 'Done'),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 60, color: Colors.black45),
          const SizedBox(height: 12),
          Text(
            "Notifications",
            style: GoogleFonts.oxanium(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          const Text("You have no new notifications", style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: Color(0xFF0F1B2B),
            child: Icon(Icons.person, size: 54, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            "User Profile",
            style: GoogleFonts.oxanium(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          const Text("Chrono List User", style: TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm:ss a').format(_now);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_now);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF282727), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_filled, color: Colors.lightBlueAccent, size: 26),
              const SizedBox(width: 10),
              Text(
                "CURRENT TIME",
                style: GoogleFonts.oxanium(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            timeStr,
            style: GoogleFonts.oxanium(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 12,
                  color: Colors.lightBlueAccent,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}