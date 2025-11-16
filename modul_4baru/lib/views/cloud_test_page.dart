import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/menu_item_model.dart';

class CloudTestPage extends StatefulWidget {
  @override
  _CloudTestPageState createState() => _CloudTestPageState();
}

class _CloudTestPageState extends State<CloudTestPage> {
  List<MenuItemModel> items = [];
  bool busy = false;

  Future<void> _fetch() async {
    setState(() => busy = true);
    try {
      final list = await SupabaseService.fetchMenuItems();
      setState(() => items = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _upsertSample() async {
    final m = MenuItemModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: 'Test X', description: 'desc', price: 10000, image: '');
    await SupabaseService.upsertMenuItem(m);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _fetch, child: Text('Fetch from Supabase')),
          ElevatedButton(onPressed: _upsertSample, child: Text('Upsert sample to Supabase')),
          if (busy) LinearProgressIndicator(),
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
