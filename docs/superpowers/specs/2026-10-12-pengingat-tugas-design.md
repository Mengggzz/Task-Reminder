# Desain Arsitektur & Spesifikasi — Aplikasi Pengingat Tugas (Android)

Tanggal: 12 Oktober 2026  
Status: Approved  
Package ID: `com.taskreminder`  
Target Platform: Android (minSdk 26, targetSdk 34+)  
Tech Stack: Flutter, sqflite, flutter_local_notifications, timezone, permission_handler, intl  

---

## 1. Ringkasan & Tujuan Proyek

Aplikasi Android pengingat tugas berbasis *local-first* (berjalan sepenuhnya luring tanpa backend/server).  
Fokus utama:
1. **Keandalan Alarm**: Notifikasi pengingat tepat waktu menggunakan *exact alarm* (`AndroidScheduleMode.exactAllowWhileIdle`).
2. **Desain Maskulin**: Nuansa *dark masculine* dengan warna latar *charcoal* (`#121212`), kartu permukaan (`#1E1E1E`), serta aksen *amber* (`#FF9800`).
3. **Resiliensi Sistem**: Penanganan izin Android modern (Android 12+ dan Android 13+), sinkronisasi ulang jadwal otomatis saat booting/membuka aplikasi.

---

## 2. Desain Tampilan & Tema (UI/UX)

### 2.1 Palet Warna & Tipografi
- **Background Utama**: `#121212` (Deep Charcoal)
- **Card Surface**: `#1E1E1E` (Dark Grey Elevated)
- **Primary Accent**: `#FF9800` (Amber / Oranye Pekat)
- **Teks Primer**: `#E0E0E0` (Off-White, High Contrast)
- **Teks Sekunder/Muted**: `#757575` (Muted Grey)
- **Border / Divider**: `#2C2C2C`
- **Error / Danger**: `#CF6679`
- **Status Success / Done**: `#4CAF50`

### 2.2 Layar Utama (`HomeScreen`)
Mengacu pada mockup `desain-pengingat-home.png`:
1. **Header Sapaan & Ringkasan**:
   - Sapaan kontekstual ("Halo,").
   - Teks sorotan: *"Kamu memiliki X tugas mendesak hari ini"* dengan angka dan aksen amber.
2. **Banner Peringatan Izin (Kondisional)**:
   - Muncul hanya jika izin *Exact Alarm* belum diberikan.
   - Peringatan: *"Izin alarm tepat waktu dinonaktifkan. Pengingat dapat tertunda."* beserta tombol *"Buka Pengaturan"*.
3. **Seksi "Mendesak"**:
   - Menampilkan daftar tugas hari ini yang belum selesai.
   - Setiap kartu tugas memuat:
     - Checkbox lingkaran di sisi kiri (tap untuk tandai selesai).
     - Judul tugas tebal (`#E0E0E0`).
     - Waktu pengingat (`HH:mm` untuk hari ini, atau format `dd MMM HH:mm`).
     - Badge pengulangan tugas (chip kecil: *Harian* / *Mingguan*).
     - Aksi edit (tap pada area kartu) dan aksi hapus dengan konfirmasi dialog.
4. **Seksi "Berikutnya"**:
   - Menampilkan tugas untuk hari-hari mendatang dengan kontras lebih redup (opacity ~0.7) untuk memusatkan fokus pengguna pada tugas hari ini.
5. **Empty State**:
   - Tampil jika belum ada tugas: Icon kalender/jam minimalis, teks *"Belum ada pengingat"*, dan tombol ajakan *"Tambah Pengingat"*.
6. **Floating Action Button (FAB)**:
   - Tombol bulat berwarna amber (`#FF9800`) dengan icon `+` berwarna hitam pekat di pojok kanan bawah.

### 2.3 Layar Form Tugas (`TaskFormScreen`)
Mengacu pada mockup `desain-pengingat-form.png`:
1. **App Bar**: Judul *"Tugas Baru"* (atau *"Ubah Tugas"* jika mode edit).
2. **Field Judul**:
   - Label: Judul Tugas (Wajib).
   - Placeholder / Hint: `cth: Bayar listrik`.
3. **Field Catatan**:
   - Label: Catatan (Opsional).
   - Placeholder / Hint: `opsional`.
   - Multiline (maksimal 3 baris tampilan).
4. **Input Waktu (Dua Kolom Sejajar)**:
   - **Kolom Kiri**: Pemilih Tanggal (menampilkan tanggal terpilih, tap membuka `showDatePicker`).
   - **Kolom Kanan**: Pemilih Jam (menampilkan jam terpilih format 24 jam, tap membuka `showTimePicker`).
5. **Dropdown Pengulangan**:
   - Opsi: `Tidak`, `Harian`, `Mingguan`.
6. **Tombol Simpan**:
   - Tombol selebar layar (full width) dengan latar amber (`#FF9800`), sudut rounded 12px, teks hitam tebal: *"Simpan Pengingat"*.
7. **Validasi Form**:
   - Jika judul kosong: Border field berubah merah dan muncul SnackBar: *"Judul tugas tidak boleh kosong"*.
   - Jika waktu pengingat tugas non-berulang diatur di masa lalu: SnackBar peringatan *"Waktu pengingat harus berada di masa mendatang"*.

---

## 3. Model Data & Skema Database (SQLite)

### 3.1 Model Task (`Task`)
Field model:
- `id`: `String` (UUID v4) — Primary Key.
- `judul`: `String` (Judul tugas, wajib).
- `catatan`: `String?` (Catatan tambahan, opsional).
- `waktuPengingat`: `DateTime` (Waktu alarm dijadwalkan).
- `ulangi`: `String` (Nilai enum: `'tidak'`, `'harian'`, `'mingguan'`).
- `selesai`: `bool` (`true` jika sudah tuntas, default `false`).
- `dibuatPada`: `DateTime` (Waktu pencatatan tugas).

### 3.2 Skema Tabel `tasks`
```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    judul TEXT NOT NULL,
    catatan TEXT,
    waktu_pengingat INTEGER NOT NULL,
    ulangi TEXT NOT NULL DEFAULT 'tidak',
    selesai INTEGER NOT NULL DEFAULT 0,
    dibuat_pada INTEGER NOT NULL
);
```

### 3.3 Indeks Query
- Index pada `waktu_pengingat ASC` dan `selesai` untuk mempercepat query sorting daftar Mendesak dan Berikutnya.

---

## 4. Arsitektur Layanan & Penjadwalan Notifikasi

### 4.1 Modul Layanan
1. **`DatabaseService`**:
   - Singleton pengelola koneksi SQLite via `sqflite`.
   - Menangani pembuatan database `task_reminder.db` dan migrasi skema.
2. **`NotificationService`**:
   - Inisialisasi plugin `FlutterLocalNotificationsPlugin`.
   - Konfigurasi `tz.initializeTimeZones()` dan pengaturan timezone lokal perangkat.
   - Konfigurasi Notification Channel Android:
     - ID: `task_reminder_channel`
     - Nama: `Pengingat Tugas`
     - Importance: `Importance.max`
     - Priority: `Priority.high`
     - Sound & Vibration aktif.
3. **`PermissionService`**:
   - Pengecekan dan permintaan izin `Permission.notification` (`POST_NOTIFICATIONS` Android 13+).
   - Pengecekan izin `Permission.scheduleExactAlarm` (Android 12+).
   - Pengarah buka pengaturan sistem via `openAppSettings()`.
4. **`TaskRepository`**:
   - Abstraksi CRUD ke tabel `tasks`.
   - Mengambil task aktif/pending, task selesai, dan pengelompokan hari ini vs mendatang.
5. **`TaskController` (`ChangeNotifier`)**:
   - State manager terpusat.
   - Mengorkestrasi penyimpanan database dan pemanggilan penjadwalan/pembatalan alarm notifikasi.
   - Mengawasi status izin alarm untuk menampilkan banner peringatan bila perlu.

### 4.2 Logika Penjadwalan Alarm
1. **Notification ID Calculation**:
   - ID integer unik 31-bit: `task.id.hashCode.abs() & 0x7FFFFFFF`.
2. **Pemicu Jadwal (Insert / Update)**:
   - Jika `task.selesai == false` dan waktu belum kedaluwarsa:
     - Mode alarm: `AndroidScheduleMode.exactAllowWhileIdle` (jika exact alarm diizinkan), atau fallback `inexactAllowWhileIdle`.
     - Pengulangan:
       - `'harian'`: `matchDateTimeComponents: DateTimeComponents.time`.
       - `'mingguan'`: `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`.
       - `'tidak'`: Satu kali pemicu pada waktu yang ditentukan.
3. **Pemicu Pembatalan (Delete / Selesai)**:
   - Memanggil `notificationsPlugin.cancel(notificationId)`.
4. **Sinkronisasi Ulang (Boot & Start Reschedule)**:
   - Setiap aplikasi dijalankan (`TaskController.init()`):
     - Membaca semua task yang belum selesai dari database.
     - Membatalkan dan mendaftarkan ulang jadwal ke notifikasi lokal.
     - Menjamin jadwal alarm tetap sinkron setelah perangkat di-restart.

---

## 5. Konfigurasi Sistem Android

### 5.1 Android Build Settings
- **`minSdkVersion`**: 26 (Android 8.0 Oreo — batas minimum notification channel & exact alarm yang stabil).
- **`compileSdkVersion`**: 34+
- **`targetSdkVersion`**: 34+

### 5.2 Izin di `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## 6. Penanganan Masalah & Edge Cases

1. **Izin Exact Alarm Ditolak / Dicabut Pengguna**:
   - Aplikasi tidak boleh melempar unhandled exception.
   - Otomatis gunakan fallback `AndroidScheduleMode.inexactAllowWhileIdle`.
   - Tampilkan banner informatif di layar utama dengan tautan ke pengaturan sistem.
2. **Zona Waktu & Format Tanggal**:
   - Panggil `initializeDateFormatting('id_ID', null)` di `main.dart`.
   - Gunakan format waktu Indonesia (misal: "Senin, 12 Okt 14:00").
3. **Reboot Perangkat**:
   - Receiver `RECEIVE_BOOT_COMPLETED` didaftarkan, ditambah sinkronisasi otomatis saat aplikasi pertama kali dibuka kembali.

---

## 7. Rencana Pengujian & Verifikasi (Quality Gates)

1. **Unit Testing**:
   - `test/models/task_model_test.dart`: Serialization `toMap()` / `fromMap()`, konversi DateTime, penanganan nilai default.
   - `test/repositories/task_repository_test.dart` / Logic testing: Validasi pemisahan status Mendesak vs Berikutnya.
2. **Static Analysis**:
   - Menjalankan `flutter analyze` dengan target: **0 error, 0 warning**.
3. **Unit Test Execution**:
   - Menjalankan `flutter test` dengan hasil lulus 100%.
4. **Build APK Release (Fase B)**:
   - `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info`.
   - Verifikasi artefak APK berhasil digenerate di folder `build/app/outputs/flutter-apk/`.
