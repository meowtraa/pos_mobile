# Macho's POS

Macho's POS adalah aplikasi Point of Sales (Kasir) berbasis mobile yang dibangun menggunakan Flutter. Aplikasi ini dirancang khusus untuk penggunaan landscape (Tablet/Desktop mode) dengan fokus pada performa, offline-first capability, dan kemudahan penggunaan.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Architecture:** MVVM (Model-View-ViewModel) dengan prinsip Clean Architecture.
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Networking:** [Dio](https://pub.dev/packages/dio)
- **Backend/Database:** [Firebase Realtime Database](https://firebase.google.com/docs/database)
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Printing:** [Bluetooth Print Plus](https://pub.dev/packages/bluetooth_print_plus) (Thermal Printer)

## 📂 Struktur Project

Struktur folder disusun mengikuti pola Clean Architecture untuk memisahkan concern antara UI, Business Logic, dan Data.

```
lib/
├── core/                   # Komponen inti yang digunakan di seluruh aplikasi
│   ├── constants/          # Konstanta (Colors, Strings, Assets)
│   ├── services/           # Service global (Session, Connectivity, Navigation)
│   ├── utils/              # Utility helper classes
│   └── firebase/           # Konfigurasi Firebase
│
├── data/                   # Layer Data (API, Database, Models)
│   ├── datasources/        # Remote & Local Data Sources
│   ├── models/             # Data Models (JSON Serialization)
│   └── repositories/       # Implementasi Repository
│
├── presentation/           # Layer UI (Views & ViewModels)
│   ├── pages/              # Halaman / Screen aplikasi
│   │   ├── auth/           # Login & Authentication screens
│   │   ├── pos/            # Halaman utama Point of Sales
│   │   └── ...
│   ├── widgets/            # Reusable Widgets
│   └── providers/          # Global State Providers
│
├── routes/                 # Konfigurasi Routing/Navigasi
├── app.dart                # Widget Root (MaterialApp Config)
└── main.dart               # Entry Point
```

## ✨ Fitur Utama

- **Point of Sales (POS):** Antarmuka kasir yang responsif dan intuitif.
- **Manajemen Produk:** Sinkronisasi produk dari database.
- **Keranjang Belanja:** Pengelolaan item pesanan real-time.
- **Thermal Printing:** Mencetak struk belanja via Bluetooth Printer.
- **Offline & Sync:** Indikator konektivitas dan sinkronisasi data saat online.
- **Authentication:** Login aman untuk staff/kasir.
- **Landscape Mode:** Dioptimalkan untuk orientasi landscape.

## 📦 Key Packages

| Package | Kegunaan |
|BC|---|
| `provider` | State Management dasar aplikasi |
| `dio` | HTTP Client untuk request API |
| `firebase_core` & `firebase_database` | Backend realtime database |
| `bluetooth_print_plus` | Koneksi ke printer thermal bluetooth |
| `connectivity_plus` | Cek status internet (Online/Offline) |
| `shared_preferences` | Penyimpanan data lokal sederhana (Session) |
| `intl` | Formatting tanggal dan mata uang |
| `flutter_native_splash` | Native Splash Screen |

## 🚀 Setup & Installation

1.  **Clone Repository**
    ```bash
    git clone <repository-url>
    cd pos_mobile
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Setup Firebase**
    -   Pastikan file `google-services.json` (Android) atau `GoogleService-Info.plist` (iOS) sudah ada di folder masing-masing jika diperlukan, atau gunakan konfigurasi manual di `FirebaseConfig`.

4.  **Run Application**
    ```bash
    flutter run
    ```

## 📝 Rules & Conventions

-   **Naming:** Gunakan `camelCase` untuk variabel/fungsi, `PascalCase` untuk kelas, dan `snake_case` untuk nama file.
-   **State:** Gunakan `ChangeNotifier` untuk ViewModel. Pisahkan logic dari UI.
-   **Immutability:** Gunakan `final` sebisa mungkin pada field widget dan model.
