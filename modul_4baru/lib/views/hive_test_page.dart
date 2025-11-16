import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../models/menu_item_model.dart';

class HiveTestPage extends StatefulWidget {
  @override
  _HiveTestPageState createState() => _HiveTestPageState();
}

class _HiveTestPageState extends State<HiveTestPage> {
  List<MenuItemModel> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _saveSample() async {
    final sample = [
      MenuItemModel(id: 'm1', name: 'Rendang', description: '...', price: 25000, image: ''),
      MenuItemModel(id: 'm2', name: 'Ayam', description: '...', price: 15000, image: ''),
    ];
    final maps = sample.map((e) => e.toMap()).toList();
    await HiveService.saveMenuList(List<Map<String, dynamic>>.from(maps));
    await _load();
  }

  Future<void> _load() async {
    final list = await HiveService.loadMenuList();
    setState(() {
      items = list.map((m) => MenuItemModel.fromMap(Map<String, dynamic>.from(m))).toList();
    });
  }

  Future<void> _clear() async {
    await HiveService.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hive Test')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _saveSample, child: Text('Save Sample to Hive')),
          ElevatedButton(onPressed: _load, child: Text('Load from Hive')),
          ElevatedButton(onPressed: _clear, child: Text('Clear Hive')),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(items[i].name),
                subtitle: Text('Rp ${items[i].price.toInt()}'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
