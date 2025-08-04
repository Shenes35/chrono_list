import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime focusedDay = initialDate;
  DateTime? selectedDay = initialDate;
  bool showYearPicker = false; // move this outside StatefulBuilder
final scrollController = ScrollController(); // ❌ Remove initialScrollOffset
bool isEditingTextField = false;
final TextEditingController dateInputController = TextEditingController(
  text: DateFormat('dd/MM/yyyy').format(initialDate),
);
String inputDate = DateFormat('dd/MM/yyyy').format(initialDate);
String? errorText;




final focusNode = FocusNode();
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: const Center(
            child: Text(
              "SELECT DATE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        content: SizedBox(
          width: 250,
          height: 420,// 🔄 NEW FLAG

child: StatefulBuilder(
  
  builder: (context, setState) {
   void handleDateSubmission() async {
  try {
    final parsed = DateFormat('dd/MM/yyyy').parseStrict(inputDate);
    final DateTime input = DateTime(parsed.year, parsed.month, parsed.day);
    final DateTime minDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final DateTime maxDate = DateTime(lastDate.year, lastDate.month, lastDate.day);

    if (!input.isBefore(minDate) && !input.isAfter(maxDate)) {
      // Step 1: Hide keyboard
      FocusScope.of(context).unfocus();

      // Step 2: Wait until keyboard closes fully
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Delay UI update until next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          focusedDay = input;
          selectedDay = input;
          isEditingTextField = false;
          showYearPicker = false;
          errorText = null;
        });
      });
    } else {
      setState(() {
        errorText = "Date out of range";
      });
    }
  } catch (e) {
    setState(() {
      errorText = "Invalid date format";
    });
  }
}







if (!focusNode.hasListeners) {
  focusNode.addListener(() {
    setState(() {});
  });
}



    // Auto scroll only the first time year picker is shown
    

    return Column(

                children: [
                  // 📅 Selected Date + Line
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEE, MMM d').format(selectedDay!),
                              style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            iconSize: 28,
                            color: Colors.black,
                            onPressed: () {
  setState(() {
    isEditingTextField = true;
  });
},

                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Colors.black,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔻 Custom header with toggling
                if (!isEditingTextField)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      GestureDetector(
   onTap: () {
  final targetYear = DateTime.now().year;
  final yearIndex = targetYear - firstDate.year;

  setState(() {
    showYearPicker = !showYearPicker;
  });

  if (showYearPicker) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      final totalYears = lastDate.year - firstDate.year + 1;
      final scrollableHeight = scrollController.position.maxScrollExtent;
      final itemHeight = scrollableHeight / totalYears;
      final exactOffset = itemHeight * yearIndex;
      final clampedOffset = exactOffset.clamp(0.0, scrollableHeight);

      scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
},










                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMM yyyy').format(focusedDay),

                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Icon(showYearPicker ? Icons.arrow_drop_up : Icons.arrow_drop_down),

                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                focusedDay = DateTime(
                                  focusedDay.year,
                                  focusedDay.month - 1,
                                );
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                focusedDay = DateTime(
                                  focusedDay.year,
                                  focusedDay.month + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔁 Conditional: Show year picker instead of calendar
                  Expanded(
                    child: isEditingTextField
      ? Padding(
  padding: const EdgeInsets.symmetric(vertical: 16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
  controller: dateInputController, // ✅ Reuse controller
  focusNode: focusNode,
  onSubmitted: (_) {
  handleDateSubmission();
},

  keyboardType: TextInputType.datetime,
  decoration: InputDecoration(
    labelText: 'Enter Date',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    labelStyle: TextStyle(
      color: focusNode.hasFocus ? Colors.blue : Colors.black54,
    ),
    floatingLabelStyle: TextStyle(
  color: focusNode.hasFocus ? Colors.blue : Colors.black54,
  fontWeight: FontWeight.w600,
),

    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    hintText: 'dd/MM/yyyy',
  ),
  onChanged: (value) {
  setState(() {
    inputDate = value;
    errorText = null; // Clear error when typing
  });
},

),

      const SizedBox(height: 8),
     ElevatedButton(
  onPressed: handleDateSubmission,


  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
  ),
  child: Text(
    "Enter ",
    style: GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    ),
  ),
),
if (errorText != null) ...[
  const SizedBox(height: 6),
  Text(
    errorText!,
    style: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.w500,
    ),
    textAlign: TextAlign.center,
  ),
],


    ],
  ),
)

 :showYearPicker
                        ? GridView.builder(
                          controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: lastDate.year - firstDate.year + 1,
                            itemBuilder: (context, index) {
                              final year = firstDate.year + index;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    focusedDay = DateTime(year, focusedDay.month);
                                    showYearPicker = false;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: focusedDay.year == year
                                        ? Colors.blueAccent
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$year',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: focusedDay.year == year
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : TableCalendar(
                            firstDay: firstDate,
                            lastDay: lastDate,
                            focusedDay: focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(selectedDay, day),
                            onDaySelected: (selected, focused) {
                              setState(() {
                                selectedDay = selected;
                                focusedDay = focused;
                              });
                            },
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              defaultTextStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              dowTextFormatter: (date, locale) =>
                                  DateFormat.E(locale).format(date)[0],
                              weekdayStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              weekendStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleTextStyle: TextStyle(fontSize: 0),
                              leftChevronVisible: false,
                              rightChevronVisible: false,
                            ),
                            calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, day) {
                                if (day.weekday == DateTime.sunday) {
                                  return const Center(
                                    child: Text(
                                      'S',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                              defaultBuilder: (context, date, _) {
                                if (date.weekday == DateTime.sunday) {
                                  return Center(
                                    child: Text(
                                      '${date.day}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                            availableGestures: AvailableGestures.all,
                            rowHeight: 40,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CANCEL", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(selectedDay),
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    },
  ).then((value) {
  focusNode.dispose();
  return value;
});
}
