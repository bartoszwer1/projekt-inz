import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: SterownikOsw(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      primaryColor: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.black54,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
        ),
      ),
    ),
  ));
}

class SterownikOsw extends StatefulWidget {
  @override
  State<SterownikOsw> createState() => _SterownikOswState();
}

class _SterownikOswState extends State<SterownikOsw>
    with SingleTickerProviderStateMixin {
  String espIp = "192.168.1.77"; // Zaktualizuj na adres Twojego ESP32

  // Dane pomieszczeń
  List<double> roomsCct = [3000, 4000, 5000, 6000, 7000];
  List<double> roomsBrightness = [50, 50, 50, 50, 50];

  // Dane budynku
  double buildingCct = 5000;
  double buildingBrightness = 50;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> setRoom(int room, double cct, double brightness) async {
    final url = Uri.http(espIp, '/set', {
      'room': room.toString(),
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      await http.get(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia: $e')),
      );
    }
  }

  Future<void> setBuilding(double cct, double brightness) async {
    final url = Uri.http(espIp, '/setBuilding', {
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      await http.get(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia: $e')),
      );
    }
  }

  Future<void> setAlarm() async {
    final url = Uri.http(espIp, '/alarm');
    try {
      await http.get(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm włączony')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia: $e')),
      );
    }
  }

  Future<void> setEvacuation() async {
    final url = Uri.http(espIp, '/evacuation');
    try {
      await http.get(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ewakuacja włączona')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia: $e')),
      );
    }
  }

  Widget buildRoomControl(int roomIndex) {
    return ExpansionTile(
      title: Text(
        "Pomieszczenie ${roomIndex + 1}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Temperatura barwy: ${roomsCct[roomIndex].toInt()}K'),
              Slider(
                activeColor: Colors.blueGrey,
                inactiveColor: Colors.grey,
                min: 2300,
                max: 7500,
                divisions: 5200,
                value: roomsCct[roomIndex],
                label: "${roomsCct[roomIndex].toInt()}K",
                onChanged: (val) {
                  setState(() {
                    roomsCct[roomIndex] = val;
                  });
                  setRoom(roomIndex, roomsCct[roomIndex],
                      roomsBrightness[roomIndex]);
                },
              ),
              SizedBox(height: 10),
              Text('Jasność: ${roomsBrightness[roomIndex].toInt()}%'),
              Slider(
                activeColor: Colors.blueGrey,
                inactiveColor: Colors.grey,
                min: 0,
                max: 100,
                divisions: 100,
                value: roomsBrightness[roomIndex],
                label: "${roomsBrightness[roomIndex].toInt()}%",
                onChanged: (val) {
                  setState(() {
                    roomsBrightness[roomIndex] = val;
                  });
                  setRoom(roomIndex, roomsCct[roomIndex],
                      roomsBrightness[roomIndex]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPomieszczeniaTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => buildRoomControl(index),
    );
  }

  Widget buildBudynekTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.grey[850],
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperatura barwy budynku: ${buildingCct.toInt()}K',
                    style: TextStyle(fontSize: 16),
                  ),
                  Slider(
                    activeColor: Colors.blueGrey,
                    inactiveColor: Colors.grey,
                    min: 2300,
                    max: 7500,
                    divisions: 5200,
                    value: buildingCct,
                    label: "${buildingCct.toInt()}K",
                    onChanged: (val) {
                      setState(() {
                        buildingCct = val;
                      });
                      setBuilding(buildingCct, buildingBrightness);
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Jasność budynku: ${buildingBrightness.toInt()}%',
                    style: TextStyle(fontSize: 16),
                  ),
                  Slider(
                    activeColor: Colors.blueGrey,
                    inactiveColor: Colors.grey,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    value: buildingBrightness,
                    label: "${buildingBrightness.toInt()}%",
                    onChanged: (val) {
                      setState(() {
                        buildingBrightness = val;
                      });
                      setBuilding(buildingCct, buildingBrightness);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: setAlarm,
                icon: Icon(Icons.warning),
                label: Text('Alarm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: setEvacuation,
                icon: Icon(Icons.exit_to_app),
                label: Text('Ewakuacja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sterowanie oświetleniem'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Pomieszczenia'),
              Tab(text: 'Budynek'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            buildPomieszczeniaTab(),
            buildBudynekTab(),
          ],
        ),
      ),
    );
  }
}
