class Task {
  final String id;
  final String judul;
  final String? catatan;
  final DateTime waktuPengingat;
  final String ulangi; // 'tidak', 'harian', 'mingguan'
  final bool selesai;
  final DateTime dibuatPada;

  Task({
    required this.id,
    required this.judul,
    this.catatan,
    required this.waktuPengingat,
    this.ulangi = 'tidak',
    this.selesai = false,
    required this.dibuatPada,
  });

  int get notificationId => id.hashCode.abs() & 0x7FFFFFFF;

  Task copyWith({
    String? id,
    String? judul,
    String? catatan,
    DateTime? waktuPengingat,
    String? ulangi,
    bool? selesai,
    DateTime? dibuatPada,
  }) {
    return Task(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      catatan: catatan ?? this.catatan,
      waktuPengingat: waktuPengingat ?? this.waktuPengingat,
      ulangi: ulangi ?? this.ulangi,
      selesai: selesai ?? this.selesai,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'catatan': catatan,
      'waktu_pengingat': waktuPengingat.millisecondsSinceEpoch,
      'ulangi': ulangi,
      'selesai': selesai ? 1 : 0,
      'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      judul: map['judul'] as String,
      catatan: map['catatan'] as String?,
      waktuPengingat:
          DateTime.fromMillisecondsSinceEpoch(map['waktu_pengingat'] as int),
      ulangi: map['ulangi'] as String? ?? 'tidak',
      selesai: (map['selesai'] as int) == 1,
      dibuatPada:
          DateTime.fromMillisecondsSinceEpoch(map['dibuat_pada'] as int),
    );
  }
}
