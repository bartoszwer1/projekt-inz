import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert'; // Import for JSON parsing

void main() {
  runApp(MaterialApp(
    home: SterownikOsw(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      primaryColor: Colors.tealAccent,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Smaller rounding
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), // Smaller padding
          textStyle: const TextStyle(
            fontSize: 14, // Smaller font size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.grey[700],
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.tealAccent,
        inactiveTrackColor: Colors.grey,
        thumbColor: Colors.tealAccent,
        overlayColor: Colors.tealAccent.withAlpha(32),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
    ),
  ));
}

class SterownikOsw extends StatefulWidget {
  const SterownikOsw({super.key});

  @override
  State<SterownikOsw> createState() => _SterownikOswState();
}

class _SterownikOswState extends State<SterownikOsw>
    with SingleTickerProviderStateMixin {
  String espIp = "192.168.1.81"; // Change to your ESP32 IP

  List<double> roomsCct = [3000, 4000, 5000, 6000, 7000];
  List<double> roomsBrightness = [50, 50, 50, 50, 50];

  double buildingCct = 5000;
  double buildingBrightness = 50;

  late TabController _tabController;

  // Fotorezystor
  int lightPercent = 50;
  Timer? lightTimer;

  // System time
  Timer? timeTimer;

  // Harmonogram
  TimeOfDay? buildingOnTime;
  TimeOfDay? buildingOffTime;
  List<TimeOfDay?> roomsOnTime = [null, null, null, null, null];
  List<TimeOfDay?> roomsOffTime = [null, null, null, null, null];
  Timer? scheduleTimer;

  // Schedule enabled flags
  bool scheduleEnabledBuilding = false;
  List<bool> scheduleEnabledRooms = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs

    fetchLight();

    lightTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchLight();
    });

    timeTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      setState(() {}); // Update UI to show current time
    });

    scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkSchedule();
    });
  }

  @override
  void dispose() {
    lightTimer?.cancel();
    timeTimer?.cancel();
    scheduleTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchLight() async {
    try {
      final url = Uri.http(espIp, '/light');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = response.body;
        // Parse JSON correctly
        final jsonBody = json.decode(body);
        setState(() {
          lightPercent = jsonBody['light'];
        });
      }
    } catch (e) {
      // Handle error silently or show error
      // print("Błąd podczas pobierania odczytu światła: $e");
    }
  }

  Future<void> setRoom(int room, double cct, double brightness) async {
    final url = Uri.http(espIp, '/set', {
      'room': room.toString(),
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      await http.get(url);
      // Optionally show a message or handle response
    } catch (e) {
      // Handle error silently or show error
      // print("Błąd podczas ustawiania pomieszczenia: $e");
    }
  }

  Future<void> setBuilding(double cct, double brightness) async {
    final url = Uri.http(espIp, '/setBuilding', {
      'cct': cct.toInt().toString(),
      'brightness': brightness.toInt().toString()
    });
    try {
      await http.get(url);
      // Optionally show a message or handle response
    } catch (e) {
      // Handle error silently or show error
      // print("Błąd podczas ustawiania budynku: $e");
    }
  }

  Future<void> setAlarm() async {
    final url = Uri.http(espIp, '/alarm');
    try {
      await http.get(url);
      // Optionally show a message or handle response
    } catch (e) {
      // Handle error silently or show error
      // print("Błąd podczas ustawiania trybu Alarm: $e");
    }
  }

  Future<void> setEvacuation() async {
    final url = Uri.http(espIp, '/evacuation');
    try {
      await http.get(url);
      // Optionally show a message or handle response
    } catch (e) {
      // Handle error silently or show error
      // print("Błąd podczas ustawiania trybu Ewakuacja: $e");
    }
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sukces'),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text('OK'),
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
        title: const Text('Błąd'),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showCctInputDialog(int roomIndex) {
    TextEditingController controller =
        TextEditingController(text: roomsCct[roomIndex].toInt().toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Wprowadź temperaturę barwy (K)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "2300 - 7500"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Anuluj")),
            TextButton(
              onPressed: () {
                int? entered = int.tryParse(controller.text);
                if (entered != null && entered >= 2300 && entered <= 7500) {
                  setState(() {
                    roomsCct[roomIndex] = entered.toDouble();
                  });
                  setRoom(roomIndex, roomsCct[roomIndex],
                      roomsBrightness[roomIndex]);
                  Navigator.pop(context);
                } else {
                  showError("Wprowadź wartość w zakresie 2300 - 7500 K");
                }
              },
              child: const Text("Zatwierdź"),
            ),
          ],
        );
      },
    );
  }

  void showBudynekCctInputDialog() {
    TextEditingController controller =
        TextEditingController(text: buildingCct.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Wprowadź temperaturę barwy budynku (K)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "2300 - 7500"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Anuluj")),
            TextButton(
              onPressed: () {
                int? entered = int.tryParse(controller.text);
                if (entered != null && entered >= 2300 && entered <= 7500) {
                  setState(() {
                    buildingCct = entered.toDouble();
                  });
                  setBuilding(buildingCct, buildingBrightness);
                  Navigator.pop(context);
                } else {
                  showError("Wprowadź wartość w zakresie 2300 - 7500 K");
                }
              },
              child: const Text("Zatwierdź"),
            ),
          ],
        );
      },
    );
  }

  Widget buildRoomControl(int roomIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          "Pomieszczenie ${roomIndex + 1}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CCT
                Row(
                  children: [
                    const Text('Temperatura barwy: ',
                        style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showCctInputDialog(roomIndex),
                        child: Text(
                          "${roomsCct[roomIndex].toInt()}K",
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                    });
                    setRoom(roomIndex, roomsCct[roomIndex],
                        roomsBrightness[roomIndex]);
                  },
                ),
                const SizedBox(height: 10),
                // Brightness
                Text('Jasność: ${roomsBrightness[roomIndex].toInt()}%',
                    style: const TextStyle(fontSize: 16)),
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

  Widget buildOswiezenieTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Kafelek Budynek
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text(
              "Budynek",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CCT
                    Row(
                      children: [
                        const Text('Temperatura barwy: ',
                            style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: GestureDetector(
                            onTap: showBudynekCctInputDialog,
                            child: Text(
                              "${buildingCct.toInt()}K",
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                        });
                        setBuilding(buildingCct, buildingBrightness);
                      },
                    ),
                    const SizedBox(height: 20),
                    // Brightness
                    Text('Jasność: ${buildingBrightness.toInt()}%',
                        style: const TextStyle(fontSize: 16)),
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
            ],
          ),
        ),
        // Listowanie pomieszczeń
        ...List.generate(roomsCct.length, (index) => buildRoomControl(index)),
        // Kafelek Dodatkowe
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text(
              "Dodatkowe",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: setAlarm,
                      icon: const Icon(Icons.warning, color: Colors.white),
                      label: const Text('Alarm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: setEvacuation,
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text('Ewakuacja'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHarmonogramTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Harmonogram dla budynku
        Card(
          color: const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedule toggle and time pickers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Harmonogram dla budynku',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Switch(
                      value: scheduleEnabledBuilding,
                      onChanged: (bool value) {
                        setState(() {
                          scheduleEnabledBuilding = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Włącz o: ', style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                      onPressed: scheduleEnabledBuilding
                          ? () => pickTime(context, true, true, null)
                          : null,
                      child: Text(buildingOnTime != null
                          ? buildingOnTime!.format(context)
                          : "Ustaw"),
                    ),
                    const SizedBox(width: 20),
                    const Text('Wyłącz o: ', style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                      onPressed: scheduleEnabledBuilding
                          ? () => pickTime(context, false, true, null)
                          : null,
                      child: Text(buildingOffTime != null
                          ? buildingOffTime!.format(context)
                          : "Ustaw"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Harmonogram dla wszystkich pomieszczeń
        ...List.generate(roomsCct.length, (index) {
          return Card(
            color: const Color(0xFF1E1E1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule toggle and time pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pomieszczenie ${index + 1}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Switch(
                        value: scheduleEnabledRooms[index],
                        onChanged: (bool value) {
                          setState(() {
                            scheduleEnabledRooms[index] = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Włącz o: ', style: TextStyle(fontSize: 16)),
                      ElevatedButton(
                        onPressed: scheduleEnabledRooms[index]
                            ? () => pickTime(context, true, false, index)
                            : null,
                        child: Text(roomsOnTime[index] != null
                            ? roomsOnTime[index]!.format(context)
                            : "Ustaw"),
                      ),
                      const SizedBox(width: 20),
                      const Text('Wyłącz o: ', style: TextStyle(fontSize: 16)),
                      ElevatedButton(
                        onPressed: scheduleEnabledRooms[index]
                            ? () => pickTime(context, false, false, index)
                            : null,
                        child: Text(roomsOffTime[index] != null
                            ? roomsOffTime[index]!.format(context)
                            : "Ustaw"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void checkSchedule() {
    // Get current system time
    DateTime now = DateTime.now();
    TimeOfDay currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Sprawdzenie harmonogramu dla budynku
    if (scheduleEnabledBuilding) {
      if (buildingOnTime != null &&
          buildingOnTime!.hour == currentTime.hour &&
          buildingOnTime!.minute == currentTime.minute) {
        setBuilding(buildingCct, 100);
      }
      if (buildingOffTime != null &&
          buildingOffTime!.hour == currentTime.hour &&
          buildingOffTime!.minute == currentTime.minute) {
        setBuilding(buildingCct, 0);
      }
    }

    // Sprawdzenie harmonogramu dla wszystkich pomieszczeń
    for (int i = 0; i < roomsCct.length; i++) {
      if (scheduleEnabledRooms[i]) {
        if (roomsOnTime[i] != null &&
            roomsOnTime[i]!.hour == currentTime.hour &&
            roomsOnTime[i]!.minute == currentTime.minute) {
          setRoom(i, roomsCct[i], 100);
        }
        if (roomsOffTime[i] != null &&
            roomsOffTime[i]!.hour == currentTime.hour &&
            roomsOffTime[i]!.minute == currentTime.minute) {
          setRoom(i, roomsCct[i], 0);
        }
      }
    }
  }

  Future<void> pickTime(BuildContext context, bool isOnTime, bool isBuilding,
      int? roomIndex) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBuilding) {
          if (isOnTime) {
            buildingOnTime = picked;
          } else {
            buildingOffTime = picked;
          }
        } else {
          if (isOnTime && roomIndex != null) {
            roomsOnTime[roomIndex] = picked;
          } else if (!isOnTime && roomIndex != null) {
            roomsOffTime[roomIndex] = picked;
          }
        }
      });
    }
  }

  void showLightDialog() {
    int proponowana = 100 - lightPercent;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odczyt światła'),
        content: Text(
            'Odczyt światła: $lightPercent%\nProponowana moc oświetlenia: $proponowana%'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void showInfoDialog() {
    DateTime now = DateTime.now();
    String formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informacje'),
        content: Text(
            'Połączono z ESP32 pod adresem: $espIp\nSterownik oświetlenia - projekt-inz\nCzas systemowy: $formattedTime'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ikona pogody w zależności od lightPercent
    Widget weatherIcon;
    if (lightPercent > 80) {
      weatherIcon = const Icon(Icons.wb_sunny, color: Colors.yellowAccent);
    } else if (lightPercent > 60) {
      weatherIcon = const Icon(Icons.wb_sunny_outlined, color: Colors.yellow);
    } else if (lightPercent > 40) {
      weatherIcon = const Icon(Icons.cloud_outlined, color: Colors.blueAccent);
    } else if (lightPercent > 20) {
      weatherIcon = const Icon(Icons.cloud, color: Colors.white54);
    } else {
      weatherIcon = const Icon(Icons.nights_stay, color: Colors.blueGrey);
    }

    return DefaultTabController(
      length: 3, // 3 tabs: Oświetlenie, Harmonogram, Asystent
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                icon: weatherIcon,
                onPressed:
                    showLightDialog, // Open light dialog on weather icon click
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sterowanie oświetleniem',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: showInfoDialog,
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.tealAccent,
            tabs: const [
              Tab(text: 'Oświetlenie'),
              Tab(text: 'Harmonogram'),
              Tab(text: 'Asystent'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            buildOswiezenieTab(),
            buildHarmonogramTab(),
            buildAsystentTab(), // Empty Asystent tab
          ],
        ),
      ),
    );
  }

  Widget buildAsystentTab() {
    // Currently empty, for future use
    return const Center(
      child: Text(
        'Asystent',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
