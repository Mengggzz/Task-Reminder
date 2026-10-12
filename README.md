<div align="center">

# ⏱️ Pengingat (Task Reminder)

**Aplikasi Pengingat Tugas Android Berbasis Offline-First dengan Penjadwalan Alarm Tepat Waktu (Exact Alarm) & Desain Dark Maskulin.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%208.0%2B%20(API%2026%2B)-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-ChangeNotifier%20%2B%20Repository-orange)](#arsitektur)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<br/>

<img src="logo.png" alt="Pengingat Logo" width="140" height="140" />

</div>

---

## 📌 Ringkasan

**Pengingat** adalah aplikasi Android pelacak dan pengingat tugas yang memprioritaskan privasi dan keandalan sistem alarm. Berjalan sepenuhnya di perangkat (*local-first*) tanpa server/backend pihak ketiga.

Dirancang khusus dengan estetika **Dark Masculine**:
- Latar arang pekat (*Deep Charcoal* `#121212`)
- Kartu permukaan terangkat (*Dark Grey Surface* `#1E1E1E`)
- Aksen dinamis *Amber* (`#FF9800`) untuk kontras tinggi dan kenyamanan mata.

---

## ✨ Fitur Utama

- 🔔 **Exact Alarm & While Idle Scheduling**: Menggunakan `AndroidScheduleMode.exactAllowWhileIdle` via `flutter_local_notifications` dan zona waktu lokal `timezone`, memastikan alarm tetap berbunyi tepat waktu meskipun layar mati atau perangkat dalam mode Doze.
- 🔄 **Resiliensi Pasca-Reboot**: Dilengkapi penanganan izin `RECEIVE_BOOT_COMPLETED` dan sinkronisasi otomatis seluruh tugas *pending* saat aplikasi dibuka, mencegah alarm terlewat setelah perangkat dimulai ulang.
- 🎯 **Kategorisasi Tugas Cerdas**:
  - **Mendesak**: Sorotan tugas hari ini yang belum selesai dengan hitungan ringkasan kontekstual.
  - **Berikutnya**: Daftar tugas mendatang dengan tampilan teredup untuk menjaga fokus pengguna.
- 🔁 **Pengulangan Fleksibel**: Dukungan alarm berkala (*Tidak Berulang*, *Harian*, atau *Mingguan*).
- 🛡️ **Penanganan Izin Adaptif**: Pengecekan otomatis `POST_NOTIFICATIONS` (Android 13+) dan `SCHEDULE_EXACT_ALARM` (Android 12+). Jika exact alarm dinonaktifkan sistem, aplikasi otomatis *fallback* ke `inexactAllowWhileIdle` dan menampilkan banner peringatan ramah pengguna.
- 💾 **Penyimpanan SQLite Cepat**: Database relasional lokal menggunakan `sqflite` dengan indeks teroptimasi untuk pemuatan data instan.
- 🇮🇩 **Lokalisasi Penuh**: Format penanggalan dan waktu Indonesia (`id_ID`) menggunakan pustaka `intl`.

---

## 🛠️ Tech Stack & Dependensi

| Komponen | Pustaka / Versi | Kegunaan |
|---|---|---|
| **Framework** | Flutter 3.47+ (Dart 3.13+) | Fondasi aplikasi mobile lintas-versi |
| **Database** | `sqflite` ^2.4.4 | Penyimpanan lokal SQLite terenkapsulasi |
| **Notification** | `flutter_local_notifications` ^22.3.1 | Penjadwalan notification channel & alarm native |
| **Timezone** | `timezone` ^0.11.1 | Pustaka kalkulasi zona waktu global (`Asia/Jakarta`, dll) |
| **Permission** | `permission_handler` ^13.0.2 | Manajemen izin runtime Android 12/13/14+ |
| **Formatting** | `intl` ^0.20.3 | Lokalisasi format tanggal dan jam Indonesia |

---

## 🏛️ Arsitektur Proyek

Aplikasi menerapkan pola **Model-Repository-Controller (ChangeNotifier)** untuk pemisahan tanggung jawab yang bersih:

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Palet warna charcoal, surface, amber
│   │   └── app_theme.dart           # Konfigurasi ThemeData Dark M3
│   └── services/
│       ├── database_service.dart    # Singleton inisialisasi SQLite & migrasi tabel
│       ├── notification_service.dart# Orkestrasi channel notifikasi & zonedSchedule
│       └── permission_service.dart  # Handler izin POST_NOTIFICATIONS & exact alarm
├── controllers/
│   └── task_controller.dart         # State manager (partisi Mendesak vs Berikutnya)
├── models/
│   └── task_model.dart              # Data class Task, toMap/fromMap, copyWith, 31-bit ID
├── repositories/
│   └── task_repository.dart        # Abstraksi kueri SQLite CRUD
├── views/
│   ├── form/
│   │   └── task_form_screen.dart    # Form tugas: Date/Time picker 2-kolom, dropdown ulangi
│   └── home/
│       ├── home_screen.dart         # Layar utama
│       └── widgets/
│           ├── empty_state.dart     # Tampilan saat belum ada tugas
│           ├── permission_banner.dart # Banner peringatan izin exact alarm
│           ├── summary_header.dart  # Header ringkasan jumlah tugas hari ini
│           └── task_card.dart       # Kartu tugas dengan tombol centang lingkaran
└── main.dart                        # Inisialisasi binding, timezone, locale & boot reschedule
```

---

## 🔒 Izin Android (`AndroidManifest.xml`)

Aplikasi hanya meminta izin yang relevan dengan fungsionalitas inti alarm:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## 🚀 Panduan Memulai & Kompilasi

### Prasyarat
- Flutter SDK `^3.47.0`
- Android SDK Platform `34` / `37` (minSdk 26)
- Java Runtime (JDK 17+)

### 1. Pasang Dependensi
```bash
flutter pub get
```

### 2. Jalankan Pengujian Otomatis
```bash
# Menjalankan seluruh unit test
flutter test

# Memeriksa kualitas kode statis (0 issue)
flutter analyze
```

### 3. Jalankan Aplikasi di Perangkat / Emulator
```bash
flutter run
```

### 4. Build APK Rilis (Split-ABI + Obfuscate)
Untuk menghasilkan APK ringan terpisah berdasarkan arsitektur CPU target:
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```

Hasil kompilasi APK akan berada di folder:
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk      # Untuk mayoritas smartphone Android modern (64-bit)
├── app-armeabi-v7a-release.apk    # Untuk smartphone Android lama (32-bit)
└── app-x86_64-release.apk         # Untuk emulator Android PC
```

---

## 🧪 Skenario Pengujian HP Fisik

- [x] **Alarm 1 Menit**: Notifikasi muncul tepat waktu saat layar mati.
- [x] **Edit Pengingat**: Jadwal lama dibatalkan dan jadwal baru terdaftar (tanpa notifikasi ganda).
- [x] **Selesai / Hapus**: Notifikasi otomatis dibatalkan saat status diubah menjadi selesai atau dihapus.
- [x] **Reboot Device**: Sinkronisasi ulang mendaftarkan kembali seluruh tugas yang masih aktif.
- [x] **Izin Ditolak**: Penanganan fallback halus tanpa *crash*, disertai banner panduan pengaturan.

---

## 📄 Lisensi

Didistribusikan di bawah lisensi MIT. Silakan lihat berkas `LICENSE` untuk informasi lebih lanjut.
