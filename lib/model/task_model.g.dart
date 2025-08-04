// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      type: fields[3] as TaskType,
      isCompleted: fields[4] as bool,
      isSkipped: fields[5] as bool,
      repeatingCount: fields[6] as int?,
      currentCount: fields[7] as int?,
      timeToTrigger: fields[8] as String?,
      alarmEnabled: fields[9] as bool,
      soundOrVibration: fields[10] as String?,
      repeatPattern: (fields[11] as List?)?.cast<int>(),
      dateRange: fields[12] as DateTimeRangeHive?,
      appToLaunch: fields[13] as String?,
      folderPath: fields[14] as String?,
      interviewQuestion: fields[15] as String?,
      recordingPath: fields[16] as String?,
      fluencyScore: fields[17] as double?,
      clarityScore: fields[18] as double?,
      confidenceScore: fields[19] as double?,
      note: fields[20] as String?,
      autoAction: fields[21] as String?,
      isFavorite: fields[22] as bool,
      createdAt: fields[23] as DateTime,
      lastModified: fields[24] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.isSkipped)
      ..writeByte(6)
      ..write(obj.repeatingCount)
      ..writeByte(7)
      ..write(obj.currentCount)
      ..writeByte(8)
      ..write(obj.timeToTrigger)
      ..writeByte(9)
      ..write(obj.alarmEnabled)
      ..writeByte(10)
      ..write(obj.soundOrVibration)
      ..writeByte(11)
      ..write(obj.repeatPattern)
      ..writeByte(12)
      ..write(obj.dateRange)
      ..writeByte(13)
      ..write(obj.appToLaunch)
      ..writeByte(14)
      ..write(obj.folderPath)
      ..writeByte(15)
      ..write(obj.interviewQuestion)
      ..writeByte(16)
      ..write(obj.recordingPath)
      ..writeByte(17)
      ..write(obj.fluencyScore)
      ..writeByte(18)
      ..write(obj.clarityScore)
      ..writeByte(19)
      ..write(obj.confidenceScore)
      ..writeByte(20)
      ..write(obj.note)
      ..writeByte(21)
      ..write(obj.autoAction)
      ..writeByte(22)
      ..write(obj.isFavorite)
      ..writeByte(23)
      ..write(obj.createdAt)
      ..writeByte(24)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DateTimeRangeHiveAdapter extends TypeAdapter<DateTimeRangeHive> {
  @override
  final int typeId = 2;

  @override
  DateTimeRangeHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DateTimeRangeHive(
      start: fields[0] as DateTime,
      end: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DateTimeRangeHive obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeRangeHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 0;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.normal;
      case 1:
        return TaskType.count;
      case 2:
        return TaskType.timed;
      case 3:
        return TaskType.appLaunch;
      case 4:
        return TaskType.folderOpen;
      case 5:
        return TaskType.appPerform;
      default:
        return TaskType.normal;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.normal:
        writer.writeByte(0);
        break;
      case TaskType.count:
        writer.writeByte(1);
        break;
      case TaskType.timed:
        writer.writeByte(2);
        break;
      case TaskType.appLaunch:
        writer.writeByte(3);
        break;
      case TaskType.folderOpen:
        writer.writeByte(4);
        break;
      case TaskType.fileOpen:
        writer.writeByte(5);
        break;
      case TaskType.appPerform:
        writer.writeByte(6);
        break;
      case TaskType.feedback:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
