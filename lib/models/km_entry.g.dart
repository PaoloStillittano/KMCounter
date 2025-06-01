// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'km_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KmEntryAdapter extends TypeAdapter<KmEntry> {
  @override
  final int typeId = 1;

  @override
  KmEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KmEntry(
      date: fields[0] as DateTime,
      kilometers: fields[1] as double,
      category: fields[2] as KmCategory,
    );
  }

  @override
  void write(BinaryWriter writer, KmEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.kilometers)
      ..writeByte(2)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KmEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KmCategoryAdapter extends TypeAdapter<KmCategory> {
  @override
  final int typeId = 0;

  @override
  KmCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return KmCategory.personal;
      case 1:
        return KmCategory.work;
      default:
        return KmCategory.personal;
    }
  }

  @override
  void write(BinaryWriter writer, KmCategory obj) {
    switch (obj) {
      case KmCategory.personal:
        writer.writeByte(0);
        break;
      case KmCategory.work:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KmCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
