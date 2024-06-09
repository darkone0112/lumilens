import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  _NotificationPreferencesScreenState createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool newReleasesEnabled = true;
  bool remindersEnabled = true;
  bool updatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      newReleasesEnabled = prefs.getBool('newReleasesEnabled') ?? true;
      remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
      updatesEnabled = prefs.getBool('updatesEnabled') ?? true;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch (key) {
        case 'newReleasesEnabled':
          newReleasesEnabled = value;
          break;
        case 'remindersEnabled':
          remindersEnabled = value;
          break;
        case 'updatesEnabled':
          updatesEnabled = value;
          break;
      }
      prefs.setBool(key, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('New Releases', style: TextStyle(color: Colors.white)),
              value: newReleasesEnabled,
              onChanged: (value) => _updatePreference('newReleasesEnabled', value),
              activeColor: Colors.blueAccent,
            ),
            SwitchListTile(
              title: const Text('Reminders', style: TextStyle(color: Colors.white)),
              value: remindersEnabled,
              onChanged: (value) => _updatePreference('remindersEnabled', value),
              activeColor: Colors.blueAccent,
            ),
            SwitchListTile(
              title: const Text('Updates', style: TextStyle(color: Colors.white)),
              value: updatesEnabled,
              onChanged: (value) => _updatePreference('updatesEnabled', value),
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}
