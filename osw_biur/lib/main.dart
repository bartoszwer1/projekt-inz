import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: SterownikOsw(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      primaryColor: Colors.tealAccent,
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal, // Kolor główny przycisku
          foregroundColor: Colors.white, // Kolor tekstu
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Zaokrąglone rogi
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardColor: Color(0xFF1E1E1E),
      dividerColor: Colors.grey[700],
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.tealAccent,
        inactiveTrackColor: Colors.grey,
        thumbColor: Colors.tealAccent,
        overlayColor: Colors.tealAccent.withAlpha(32),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
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

  // Kontrolery tekstowe dla pomieszczeń
  List<TextEditingController> cctControllers = [];

  // Kontroler tekstowy dla budynku
  TextEditingController buildingCctController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Inicjalizacja kontrolerów tekstowych
    for (int i = 0; i < roomsCct.length; i++) {
      cctControllers
          .add(TextEditingController(text: roomsCct[i].toInt().toString()));
    }
    buildingCctController.text = buildingCct.toInt().toString();
  }

  @override
  void dispose() {
    // Zwolnienie kontrolerów tekstowych
    for (var controller in cctControllers) {
      controller.dispose();
    }
    buildingCctController.dispose();
    super.dispose();
  }

  Future<void> setRoom(int room, double cct, double brightness) async {
    final url = Uri.http(espIp, '/set', {
      'room': room.toString(),
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        showError('Błąd: ${response.body}');
      }
    } catch (e) {
      showError('Błąd połączenia: $e');
    }
  }

  Future<void> setBuilding(double cct, double brightness) async {
    final url = Uri.http(espIp, '/setBuilding', {
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        showError('Błąd: ${response.body}');
      }
    } catch (e) {
      showError('Błąd połączenia: $e');
    }
  }

  Future<void> setAlarm() async {
    final url = Uri.http(espIp, '/alarm');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        showMessage('Alarm włączony');
      } else {
        showError('Błąd: ${response.body}');
      }
    } catch (e) {
      showError('Błąd połączenia: $e');
    }
  }

  Future<void> setEvacuation() async {
    final url = Uri.http(espIp, '/evacuation');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        showMessage('Ewakuacja włączona');
      } else {
        showError('Błąd: ${response.body}');
      }
    } catch (e) {
      showError('Błąd połączenia: $e');
    }
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sukces'),
        content: Text(msg),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Błąd'),
        content: Text(msg),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Funkcja do wyświetlania dialogu z polem tekstowym do wprowadzenia CCT
  void showCctInputDialog(int roomIndex) {
    TextEditingController controller =
        TextEditingController(text: roomsCct[roomIndex].toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Wprowadź temperaturę barwy (K)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "2300 - 7500",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Anuluj"),
            ),
            TextButton(
              onPressed: () {
                int? entered = int.tryParse(controller.text);
                if (entered != null && entered >= 2300 && entered <= 7500) {
                  setState(() {
                    roomsCct[roomIndex] = entered.toDouble();
                    cctControllers[roomIndex].text =
                        roomsCct[roomIndex].toInt().toString();
                  });
                  setRoom(roomIndex, roomsCct[roomIndex],
                      roomsBrightness[roomIndex]);
                  Navigator.pop(context);
                } else {
                  showError("Wprowadź wartość w zakresie 2300 - 7500 K");
                }
              },
              child: Text("Zatwierdź"),
            ),
          ],
        );
      },
    );
  }

  // Funkcja do wyświetlania dialogu z polem tekstowym do wprowadzenia CCT dla budynku
  void showBudynekCctInputDialog() {
    TextEditingController controller =
        TextEditingController(text: buildingCct.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Wprowadź temperaturę barwy budynku (K)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "2300 - 7500",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Anuluj"),
            ),
            TextButton(
              onPressed: () {
                int? entered = int.tryParse(controller.text);
                if (entered != null && entered >= 2300 && entered <= 7500) {
                  setState(() {
                    buildingCct = entered.toDouble();
                    buildingCctController.text = buildingCct.toInt().toString();
                  });
                  setBuilding(buildingCct, buildingBrightness);
                  Navigator.pop(context);
                } else {
                  showError("Wprowadź wartość w zakresie 2300 - 7500 K");
                }
              },
              child: Text("Zatwierdź"),
            ),
          ],
        );
      },
    );
  }

  Widget buildRoomControl(int roomIndex) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
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
                // Temperatura barwy
                Row(
                  children: [
                    Text(
                      'Temperatura barwy: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showCctInputDialog(roomIndex),
                        child: Text(
                          "${roomsCct[roomIndex].toInt()}K",
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Suwak Temperatura barwy
                Slider(
                  activeColor: Colors.tealAccent,
                  inactiveColor: Colors.grey,
                  min: 2300,
                  max: 7500,
                  value: roomsCct[roomIndex],
                  label: "${roomsCct[roomIndex].toInt()}K",
                  onChanged: (val) {
                    setState(() {
                      roomsCct[roomIndex] = val;
                      cctControllers[roomIndex].text =
                          roomsCct[roomIndex].toInt().toString();
                    });
                    setRoom(roomIndex, roomsCct[roomIndex],
                        roomsBrightness[roomIndex]);
                  },
                ),
                SizedBox(height: 10),
                // Jasność
                Text(
                  'Jasność: ${roomsBrightness[roomIndex].toInt()}%',
                  style: TextStyle(fontSize: 16),
                ),
                Slider(
                  activeColor: Colors.tealAccent,
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
      ),
    );
  }

  Widget buildBudynekTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Color(0xFF1E1E1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Temperatura barwy budynku
                  Row(
                    children: [
                      Text(
                        'Temperatura barwy budynku: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => showBudynekCctInputDialog(),
                          child: Text(
                            "${buildingCct.toInt()}K",
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Suwak Temperatura barwy budynku
                  Slider(
                    activeColor: Colors.tealAccent,
                    inactiveColor: Colors.grey,
                    min: 2300,
                    max: 7500,
                    value: buildingCct,
                    label: "${buildingCct.toInt()}K",
                    onChanged: (val) {
                      setState(() {
                        buildingCct = val;
                        buildingCctController.text =
                            buildingCct.toInt().toString();
                      });
                      setBuilding(buildingCct, buildingBrightness);
                    },
                  ),
                  SizedBox(height: 20),
                  // Jasność budynku
                  Text(
                    'Jasność budynku: ${buildingBrightness.toInt()}%',
                    style: TextStyle(fontSize: 16),
                  ),
                  Slider(
                    activeColor: Colors.tealAccent,
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
                icon: Icon(Icons.warning, color: Colors.white),
                label: Text('Alarm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Czerwony przycisk
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: setEvacuation,
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                label: Text('Ewakuacja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Zielony przycisk
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

  Widget buildPomieszczeniaTab() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 16),
      itemCount: 5,
      itemBuilder: (context, index) => buildRoomControl(index),
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
            indicatorColor: Colors.tealAccent,
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
