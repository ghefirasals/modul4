import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hive_service.dart';
import '../models/menu_item_model.dart';

class SpeedTestPage extends StatefulWidget {
  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  String result = '';

  Future<void> _testHiveWrite(int count) async {
    final sw = Stopwatch()..start();
    final list = List.generate(count, (i) => MenuItemModel(id: 'i$i', name: 'Item $i', description: 'desc', price: i.toDouble(), image: ''));
    final maps = list.map((e) => e.toMap()).toList();
    await HiveService.saveMenuList(List<Map<String, dynamic>>.from(maps));
    sw.stop();
    setState(() => result = 'Write $count items: ${sw.elapsedMilliseconds} ms');
  }

  Future<void> _testHiveRead() async {
    final sw = Stopwatch()..start();
    final r = await HiveService.loadMenuList();
    sw.stop();
    setState(() => result = 'Read ${r.length} items: ${sw.elapsedMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: () => _testHiveWrite(1000), child: Text('Write 1000 items (Hive)')),
            ElevatedButton(onPressed: _testHiveRead, child: Text('Read from Hive')),
            SizedBox(height: 12),
            Text(result),
          ],
        ),
      ),
    );
  }
}
