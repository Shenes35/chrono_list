import 'package:chrono_list/core/task_core.dart';
import 'package:chrono_list/model/task_model.dart';
import 'package:chrono_list/presentation/custom_calender.dart';
import 'package:chrono_list/presentation/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
  

  

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _selectedBottomIndex = 0;

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
    _buildDateHeader(),
    _buildCalendar(),
    
    
     ValueListenableBuilder(
       valueListenable: taskList,
       builder: (context,  tasks, _) {
        final totalTasks = tasks.length; // ✅ tasks is List<TaskModel>
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final progressPercent = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

         return Padding(
           padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
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
              children:  [
                
                Expanded(
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
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                
              ],
            ),
            const SizedBox(height: 10),
           
            /// ✅ Bar + Left Text Row
            Row(
              children: [
                 Expanded(
                  flex: 6,
                  child: 
                  Text(
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
               alignment: Alignment.center, // 🔹 Center everything
               children: [
            // Base bar and progress
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B2B),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filledWidth = constraints.maxWidth * progressPercent;
         
                    return Stack(
                      children: [
                        // Filled bar
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
                        // Glowing ball
                        Positioned(
                          left: filledWidth - 10,
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
           
            // 🔹 Centered progress text (always visible)
             Text(
              "${(progressPercent * 100).toInt()}%",
              style: TextStyle(
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
       }
     ),


      Expanded(
  child: ValueListenableBuilder<List<TaskModel>>(
    valueListenable: taskList,
    builder: (context, tasks, _) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // increased bottom padding

        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 40, 39, 39),
                  Color.fromARGB(255, 0, 0, 0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.oxanium(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(255, 251, 252, 252),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Implement Direct logic
                  },
                  child: const Text(
                    'Direct',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    taskList.value[index].isCompleted = true;
                    taskList.notifyListeners();
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    taskList.value[index].isCompleted = true;
                    taskList.notifyListeners();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
)



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
                // Your left FAB action
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
                // Your right FAB action
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
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {},
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('yyyy-MM-dd').format(_selectedDay),
              style: GoogleFonts.namdhinggo(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: const Color.fromARGB(255, 13, 105, 151),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.event_note),
            color: Colors.black,
            tooltip: 'Change Date',
            onPressed: () async {
              final picked = await showCustomDatePicker(
                context: context,
                initialDate: _selectedDay,
                firstDate: DateTime(1900),
                lastDate: DateTime(3000, 12, 31),
              );
              if (picked != null) {
                setState(() {
                  _focusedDay = picked;
                  _selectedDay = picked;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.black,
            tooltip: 'Edit Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskPage(selectedDate: _selectedDay),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.black,
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

  Widget _buildCalendar() {
    return SizedBox(
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
        calendarStyle: const CalendarStyle(
          cellMargin: EdgeInsets.zero, // ✅ reduces cell spacing
    cellPadding: EdgeInsets.zero, // ✅ reduce inner padding
          todayDecoration: BoxDecoration(
            color: Color.fromARGB(255, 58, 115, 214),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFFFF9800),
            shape: BoxShape.rectangle,
          ),
          todayTextStyle: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          selectedTextStyle: TextStyle(
            fontSize: 13.5,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          defaultTextStyle: TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 112, 141, 237),
            fontWeight: FontWeight.bold,
          ),
          weekendTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 112, 141, 237),
          ),
        ),
        headerStyle: HeaderStyle(
          headerPadding: EdgeInsets.zero,
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.baloo2(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          titleTextFormatter: (date, locale) => DateFormat.yMMM(locale).format(date),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          weekendStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, date, _) {
            if (date.weekday == DateTime.sunday) {
              return Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.red,
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
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
    );
  }
}