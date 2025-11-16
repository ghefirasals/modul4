import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../bindings/initial_binding.dart';
import '../controllers/menu_app_controller.dart';
import 'local_test_page.dart';
import 'hive_test_page.dart';
import 'cloud_test_page.dart';
import 'speed_test_page.dart';

class HomeView extends StatelessWidget {
  final MenuAppController ctrl = Get.find<MenuAppController>();

  @override
  Widget build(BuildContext context) {
    // if you already have module2 data, you may set it here
    return Scaffold(
      appBar: AppBar(title: Text('Modul 4 — Penyimpanan Lokal & Cloud')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              child: Text('Test SharedPreferences (Tema)'),
              onPressed: () => Get.to(() => LocalTestPage()),
            ),
            ElevatedButton(
              child: Text('Test Hive (Local Data)'),
              onPressed: () => Get.to(() => HiveTestPage()),
            ),
            ElevatedButton(
              child: Text('Test Supabase (Cloud)'),
              onPressed: () => Get.to(() => CloudTestPage()),
            ),
            ElevatedButton(
              child: Text('Speed Test (Baca/Tulis)'),
              onPressed: () => Get.to(() => SpeedTestPage()),
            ),
          ],
        ),
      ),
    );
  }
}
