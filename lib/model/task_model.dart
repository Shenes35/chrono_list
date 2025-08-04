import 'package:hive_flutter/hive_flutter.dart';
part 'task_model.g.dart';

@HiveType(typeId: 0)
enum TaskType {
  @HiveField(0)
  normal,
  @HiveField(1)
  count,
  @HiveField(2)
  timed,
  @HiveField(3)
  appLaunch,
  @HiveField(4)
  folderOpen,
  @HiveField(5)
  fileOpen,
@HiveField(6)
  appPerform,
  @HiveField(7)
  feedback,
}

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  TaskType type;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  bool isSkipped;

  @HiveField(6)
  int? repeatingCount;

  @HiveField(7)
  int? currentCount;

  @HiveField(8)
  String? timeToTrigger; // store TimeOfDay as "HH:mm" string

  @HiveField(9)
  bool alarmEnabled;

  @HiveField(10)
  String? soundOrVibration; // "sound", "vibration", "none"

  @HiveField(11)
  List<int>? repeatPattern; // 0=Sun ... 6=Sat

  @HiveField(12)
  DateTimeRangeHive? dateRange;

  @HiveField(13)
  String? appToLaunch;

  @HiveField(14)
  String? folderPath;

  @HiveField(15)
  String? interviewQuestion;

  @HiveField(16)
  String? recordingPath;

  @HiveField(17)
  double? fluencyScore;

  @HiveField(18)
  double? clarityScore;

  @HiveField(19)
  double? confidenceScore;

  @HiveField(20)
  String? note;

  @HiveField(21)
  String? autoAction;

  @HiveField(22)
  bool isFavorite;

  @HiveField(23)
  DateTime createdAt;

  @HiveField(24)
  DateTime lastModified;

  TaskModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.isCompleted,
    required this.isSkipped,
    this.repeatingCount,
    this.currentCount,
    this.timeToTrigger,
    required this.alarmEnabled,
    this.soundOrVibration,
    this.repeatPattern,
    this.dateRange,
    this.appToLaunch,
    this.folderPath,
    this.interviewQuestion,
    this.recordingPath,
    this.fluencyScore,
    this.clarityScore,
    this.confidenceScore,
    this.note,
    this.autoAction,
    required this.isFavorite,
    required this.createdAt,
    required this.lastModified,
  });
}

/// Hive doesn't support `DateTimeRange` directly, so we wrap it:
@HiveType(typeId: 2)
class DateTimeRangeHive {
  @HiveField(0)
  DateTime start;

  @HiveField(1)
  DateTime end;

  DateTimeRangeHive({required this.start, required this.end});
}
