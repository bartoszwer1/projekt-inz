import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(home: SterownikOsw()));
}

class SterownikOsw extends StatefulWidget {
  @override
  State<SterownikOsw> createState() => _SterownikOswState();
}

class _SterownikOswState extends State<SterownikOsw> {
  int selectedRoom = 0;
  double cct = 5000;
  double brightness = 50;
  String espIp = "192.168.1.77"; // Zaktualizuj na adres Twojego ESP32

  Future<void> sendData() async {
    final url = Uri.http(espIp, '/set', {
      'room': selectedRoom.toString(),
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Zmieniono parametry!')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Błąd połączenia: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sterowanie oświetleniem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: selectedRoom,
              items: List.generate(5, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text('Pomieszczenie ${index + 1}'),
                );
              }),
              onChanged: (val) {
                setState(() {
                  selectedRoom = val!;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Temperatura barwy: ${cct.toInt()}K'),
            Slider(
              min: 2300,
              max: 7500,
              value: cct,
              onChanged: (val) {
                setState(() {
                  cct = val;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Jasność: ${brightness.toInt()}%'),
            Slider(
              min: 0,
              max: 100,
              value: brightness,
              onChanged: (val) {
                setState(() {
                  brightness = val;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendData,
              child: Text('Zastosuj'),
            )
          ],
        ),
      ),
    );
  }
}
