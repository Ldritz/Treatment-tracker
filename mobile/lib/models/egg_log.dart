class EggLog {
  final String id;
  final String timestamp;
  final String treatment;
  final String block;
  final double weight;
  final double l1;
  final double l2;
  final double l3;
  final double length;
  final double w1;
  final double w2;
  final double w3;
  final double width;
  final double albumenHeight;
  final double shellWeight;
  final double yolkWeight;
  final double haughUnit;
  final double shapeIndex;
  final double yolkPct;

  // Sync Status Fields
  final bool isDeleted;
  final bool isSynced;
  final String lastModified;
  final String recordedby;

  EggLog({
    required this.id,
    required this.timestamp,
    required this.treatment,
    required this.block,
    required this.weight,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.length,
    required this.w1,
    required this.w2,
    required this.w3,
    required this.width,
    required this.albumenHeight,
    required this.shellWeight,
    required this.yolkWeight,
    required this.haughUnit,
    required this.shapeIndex,
    required this.yolkPct,
    this.isDeleted = false,
    this.isSynced = false,
    String? lastModified,
    this.recordedby = '',
  }) : lastModified = lastModified ?? DateTime.now().toIso8601String();

  EggLog copyWith({
    String? id,
    String? timestamp,
    String? treatment,
    String? block,
    double? weight,
    double? l1,
    double? l2,
    double? l3,
    double? length,
    double? w1,
    double? w2,
    double? w3,
    double? width,
    double? albumenHeight,
    double? shellWeight,
    double? yolkWeight,
    double? haughUnit,
    double? shapeIndex,
    double? yolkPct,
    bool? isDeleted,
    bool? isSynced,
    String? lastModified,
    String? recordedby,
  }) {
    return EggLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      treatment: treatment ?? this.treatment,
      block: block ?? this.block,
      weight: weight ?? this.weight,
      l1: l1 ?? this.l1,
      l2: l2 ?? this.l2,
      l3: l3 ?? this.l3,
      length: length ?? this.length,
      w1: w1 ?? this.w1,
      w2: w2 ?? this.w2,
      w3: w3 ?? this.w3,
      width: width ?? this.width,
      albumenHeight: albumenHeight ?? this.albumenHeight,
      shellWeight: shellWeight ?? this.shellWeight,
      yolkWeight: yolkWeight ?? this.yolkWeight,
      haughUnit: haughUnit ?? this.haughUnit,
      shapeIndex: shapeIndex ?? this.shapeIndex,
      yolkPct: yolkPct ?? this.yolkPct,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      recordedby: recordedby ?? this.recordedby,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'treatment': treatment,
      'block': block,
      'weight': weight,
      'l1': l1,
      'l2': l2,
      'l3': l3,
      'length': length,
      'w1': w1,
      'w2': w2,
      'w3': w3,
      'width': width,
      'albumenheight': albumenHeight,
      'shellweight': shellWeight,
      'yolkweight': yolkWeight,
      'haughunit': haughUnit,
      'shapeindex': shapeIndex,
      'yolkpct': yolkPct,
      'isdeleted': isDeleted,
      'issynced': isSynced,
      'lastmodified': lastModified,
      'recordedby': recordedby,
    };
  }

  factory EggLog.fromJson(Map<String, dynamic> json) {
    return EggLog(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      treatment: json['treatment'] as String,
      block: json['block'] as String,
      weight: (json['weight'] as num).toDouble(),
      l1: (json['l1'] as num?)?.toDouble() ?? 0.0,
      l2: (json['l2'] as num?)?.toDouble() ?? 0.0,
      l3: (json['l3'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num).toDouble(),
      w1: (json['w1'] as num?)?.toDouble() ?? 0.0,
      w2: (json['w2'] as num?)?.toDouble() ?? 0.0,
      w3: (json['w3'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num).toDouble(),
      albumenHeight: (json['albumenheight'] ?? json['albumen_height'] ?? json['albumenHeight'] as num?)?.toDouble() ?? 0.0,
      shellWeight: (json['shellweight'] ?? json['shell_weight'] ?? json['shellWeight'] as num?)?.toDouble() ?? 0.0,
      yolkWeight: (json['yolkweight'] ?? json['yolk_weight'] ?? json['yolkWeight'] as num?)?.toDouble() ?? 0.0,
      haughUnit: (json['haughunit'] ?? json['haugh_unit'] ?? json['haughUnit'] as num?)?.toDouble() ?? 0.0,
      shapeIndex: (json['shapeindex'] ?? json['shape_index'] ?? json['shapeIndex'] as num?)?.toDouble() ?? 0.0,
      yolkPct: (json['yolkpct'] ?? json['yolk_pct'] ?? json['yolkPct'] as num?)?.toDouble() ?? 0.0,
      isDeleted: (json['isdeleted'] ?? json['is_deleted'] ?? json['isDeleted']) as bool? ?? false,
      isSynced: (json['issynced'] ?? json['is_synced'] ?? json['isSynced']) as bool? ?? false,
      lastModified: (json['lastmodified'] ?? json['last_modified'] ?? json['lastModified'] ?? json['timestamp']) as String,
      recordedby: json['recordedby'] as String? ?? '',
    );
  }

}
