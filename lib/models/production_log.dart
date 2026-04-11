class ProductionLog {
  final String id;
  final String timestamp;
  final String treatment;
  final String block;
  final double eggs;
  final double eggMass;
  final double quails;
  final double days;
  final double feedGiven;
  final double feedRefusal;
  final double vfi;
  final double fcr;
  final double hdep;
  
  // Sync Status Fields
  final bool isDeleted;
  final bool isSynced;
  final String lastModified;

  ProductionLog({
    required this.id,
    required this.timestamp,
    required this.treatment,
    required this.block,
    required this.eggs,
    required this.eggMass,
    required this.quails,
    required this.days,
    required this.feedGiven,
    required this.feedRefusal,
    required this.vfi,
    required this.fcr,
    required this.hdep,
    this.isDeleted = false,
    this.isSynced = false,
    String? lastModified,
  }) : lastModified = lastModified ?? DateTime.now().toIso8601String();

  ProductionLog copyWith({
    String? id,
    String? timestamp,
    String? treatment,
    String? block,
    double? eggs,
    double? eggMass,
    double? quails,
    double? days,
    double? feedGiven,
    double? feedRefusal,
    double? vfi,
    double? fcr,
    double? hdep,
    bool? isDeleted,
    bool? isSynced,
    String? lastModified,
  }) {
    return ProductionLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      treatment: treatment ?? this.treatment,
      block: block ?? this.block,
      eggs: eggs ?? this.eggs,
      eggMass: eggMass ?? this.eggMass,
      quails: quails ?? this.quails,
      days: days ?? this.days,
      feedGiven: feedGiven ?? this.feedGiven,
      feedRefusal: feedRefusal ?? this.feedRefusal,
      vfi: vfi ?? this.vfi,
      fcr: fcr ?? this.fcr,
      hdep: hdep ?? this.hdep,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'treatment': treatment,
      'block': block,
      'eggs': eggs,
      'eggmass': eggMass,
      'quails': quails,
      'days': days,
      'feedgiven': feedGiven,
      'feedrefusal': feedRefusal,
      'vfi': vfi,
      'fcr': fcr,
      'hdep': hdep,
      'isdeleted': isDeleted,
      'issynced': isSynced,
      'lastmodified': lastModified,
    };
  }

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      treatment: json['treatment'] as String,
      block: json['block'] as String,
      eggs: (json['eggs'] as num).toDouble(),
      eggMass: (json['eggmass'] ?? json['egg_mass'] ?? json['eggMass'] as num?)?.toDouble() ?? 0.0,
      quails: (json['quails'] as num).toDouble(),
      days: (json['days'] as num).toDouble(),
      feedGiven: (json['feedgiven'] ?? json['feed_given'] ?? json['feedGiven'] as num?)?.toDouble() ?? 0.0,
      feedRefusal: (json['feedrefusal'] ?? json['feed_refusal'] ?? json['feedRefusal'] as num?)?.toDouble() ?? 0.0,
      vfi: (json['vfi'] as num).toDouble(),
      fcr: (json['fcr'] as num?)?.toDouble() ?? 0.0,
      hdep: (json['hdep'] as num).toDouble(),
      isDeleted: (json['isdeleted'] ?? json['is_deleted'] ?? json['isDeleted']) as bool? ?? false,
      isSynced: (json['issynced'] ?? json['is_synced'] ?? json['isSynced']) as bool? ?? false,
      lastModified: (json['lastmodified'] ?? json['last_modified'] ?? json['lastModified'] ?? json['timestamp']) as String,
    );
  }
}
