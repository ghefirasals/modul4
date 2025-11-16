import 'package:flutter/material.dart';
import '../services/shared_prefs_service.dart';

class LocalTestPage extends StatefulWidget {
  @override
  _LocalTestPageState createState() => _LocalTestPageState();
}

class _LocalTestPageState extends State<LocalTestPage> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final val = await SharedPrefsService.isDarkTheme();
    setState(() => isDark = val);
  }

  Future<void> _toggle() async {
    await SharedPrefsService.setDarkTheme(!isDark);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SharedPreferences Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Dark mode: $isDark'),
            SizedBox(height: 12),
            ElevatedButton(onPressed: _toggle, child: Text('Toggle & Save')),
          ],
        ),
      ),
    );
  }
}
