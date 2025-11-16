import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bindings/initial_binding.dart';
import 'views/home_view.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==== INIT HIVE ====
  await Hive.initFlutter();

  // ==== INIT SUPABASE ====
  // GANTI URL DAN ANON KEY DENGAN PUNYA KAMU SENDIRI
  const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
  const SUPABASE_ANON_KEY = 'YOUR-ANON-KEY';

  await SupabaseService.init(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Modul 4 — Warung Demo',
      debugShowCheckedModeBanner: false,

      // Agar MenuController otomatis aktif
      initialBinding: InitialBinding(),

      // Halaman utama
      home: HomeView(),
    );
  }
}
