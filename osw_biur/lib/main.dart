import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: SterownikOsw(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.white,
    ),
  ));
}

class SterownikOsw extends StatefulWidget {
  @override
  State<SterownikOsw> createState() => _SterownikOswState();
}

class _SterownikOswState extends State<SterownikOsw>
    with SingleTickerProviderStateMixin {
  String espIp = "192.168.1.77";

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
      // błąd połączenia - można pokazać snackbar
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
      // błąd połączenia
    }
  }

  Future<void> setAlarm() async {
    final url = Uri.http(espIp, '/alarm');
    await http.get(url);
  }

  Future<void> setEvacuation() async {
    final url = Uri.http(espIp, '/evacuation');
    await http.get(url);
  }

  Widget buildRoomControl(int roomIndex) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pomieszczenie ${roomIndex + 1}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Temperatura barwy: ${roomsCct[roomIndex].toInt()}K'),
            Slider(
              min: 2300,
              max: 7500,
              value: roomsCct[roomIndex],
              onChanged: (val) {
                setState(() {
                  roomsCct[roomIndex] = val;
                });
                setRoom(
                    roomIndex, roomsCct[roomIndex], roomsBrightness[roomIndex]);
              },
            ),
            SizedBox(height: 10),
            Text('Jasność: ${roomsBrightness[roomIndex].toInt()}%'),
            Slider(
              min: 0,
              max: 100,
              value: roomsBrightness[roomIndex],
              onChanged: (val) {
                setState(() {
                  roomsBrightness[roomIndex] = val;
                });
                setRoom(
                    roomIndex, roomsCct[roomIndex], roomsBrightness[roomIndex]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPomieszczeniaTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: List.generate(5, (index) => buildRoomControl(index)),
    );
  }

  Widget buildBudynekTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Temperatura barwy budynku: ${buildingCct.toInt()}K'),
          Slider(
            min: 2300,
            max: 7500,
            value: buildingCct,
            onChanged: (val) {
              setState(() {
                buildingCct = val;
              });
              setBuilding(buildingCct, buildingBrightness);
            },
          ),
          SizedBox(height: 20),
          Text('Jasność budynku: ${buildingBrightness.toInt()}%'),
          Slider(
            min: 0,
            max: 100,
            value: buildingBrightness,
            onChanged: (val) {
              setState(() {
                buildingBrightness = val;
              });
              setBuilding(buildingCct, buildingBrightness);
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setAlarm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Alarm'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setEvacuation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ewakuacja'),
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
