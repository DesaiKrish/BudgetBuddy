import 'package:flutter/material.dart';

class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final List<Map<String, dynamic>> _moodEntries = [
    {'date': DateTime.now().subtract(Duration(days: 1)), 'mood': 'Happy'},
    {'date': DateTime.now().subtract(Duration(days: 2)), 'mood': 'Sad'},
  ];

  final List<String> _moods = ['Happy', 'Sad', 'Neutral', 'Angry', 'Excited'];
  String _selectedMood = 'Happy';

  void _addMoodEntry() {
    setState(() {
      _moodEntries.insert(0, {
        'date': DateTime.now(),
        'mood': _selectedMood,
      });
    });
  }

  void _showMoodPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Your Mood'),
        content: DropdownButton<String>(
          value: _selectedMood,
          items: _moods.map((mood) {
            return DropdownMenuItem(
              value: mood,
              child: Text(mood),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedMood = newValue!;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addMoodEntry();
              Navigator.of(ctx).pop();
            },
            child: Text('Log Mood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _showMoodPicker,
              child: Text('Log Mood'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Use preferred color
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Mood History:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _moodEntries.length,
                itemBuilder: (ctx, index) {
                  return ListTile(
                    title: Text(
                      '${_moodEntries[index]['date'].toLocal()}'
                          .split(' ')[0],
                    ),
                    subtitle: Text('Mood: ${_moodEntries[index]['mood']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMoodPicker,
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple, // Use your preferred color
      ),
    );
  }
}
