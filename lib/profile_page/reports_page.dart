import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AttendanceReportsPage extends StatefulWidget {
  const AttendanceReportsPage({super.key});

  @override
  _AttendanceReportsPageState createState() => _AttendanceReportsPageState();
}

class _AttendanceReportsPageState extends State<AttendanceReportsPage> {
  DateTime selectedDate = DateTime.now();
  String selectedSection = 'A'; // Default section
  String selectedCourse = 'Discrete Math'; // Default course

  final List<String> courses = [
    'Discrete Math',
    'Digital Logic Design',
    'Humanities',
    'Mathematics',
    'Electrical and Electronic Engineering',
  ];

  final List<Map<String, dynamic>> students = [
    {"roll": "2203001", "name": "ABHISHEK CHOWDHURY DIPTA", "status": AttendanceStatus.Pending},
    {"roll": "2203002", "name": "HAMONTA BISWAS", "status": AttendanceStatus.Pending},
    {"roll": "2203003", "name": "MD. REJONE AHMED", "status": AttendanceStatus.Pending},
    {"roll": "2203004", "name": "NAHYAN YASIR IBTEE", "status": AttendanceStatus.Pending},
    {"roll": "2203005", "name": "MD. SADIKUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203006", "name": "ARONNO KUMAR GHOSH", "status": AttendanceStatus.Pending},
    {"roll": "2203007", "name": "KAZI MD. TAMZID SHIKTO", "status": AttendanceStatus.Pending},
    {"roll": "2203008", "name": "HUMAYRA ISLAM MAYSHA", "status": AttendanceStatus.Pending},
    {"roll": "2203009", "name": "MD. ROHANUL HASAN RIJON", "status": AttendanceStatus.Pending},
    {"roll": "2203010", "name": "ANONNOY ONIKET", "status": AttendanceStatus.Pending},
    {"roll": "2203011", "name": "MD. SHAMS SHAHARIAR", "status": AttendanceStatus.Pending},
    {"roll": "2203012", "name": "ANTU BISWAS", "status": AttendanceStatus.Pending},
    {"roll": "2203013", "name": "MD. ZAHID HASAN", "status": AttendanceStatus.Pending},
    {"roll": "2203014", "name": "ABDULLAH HAL KAFI NAFEES", "status": AttendanceStatus.Pending},
    {"roll": "2203015", "name": "ZUHAYER TAJBID", "status": AttendanceStatus.Pending},
    {"roll": "2203016", "name": "MD. SHIFAT HASAN", "status": AttendanceStatus.Pending},
    {"roll": "2203017", "name": "ANIK GHOSH", "status": AttendanceStatus.Pending},
    {"roll": "2203018", "name": "MD. FARDIN KHAN", "status": AttendanceStatus.Pending},
    {"roll": "2203019", "name": "APON DATTA", "status": AttendanceStatus.Pending},
    {"roll": "2203020", "name": "EMON ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203021", "name": "SANJIDA TABASSUM", "status": AttendanceStatus.Pending},
    {"roll": "2203022", "name": "MUBASHIR AHAMED SIAM", "status": AttendanceStatus.Pending},
    {"roll": "2203023", "name": "MOSTAFA MARUF IFTY", "status": AttendanceStatus.Pending},
    {"roll": "2203024", "name": "MD. ADNAN TOWHID", "status": AttendanceStatus.Pending},
    {"roll": "2203025", "name": "RAHUL CHANDRAW DASH", "status": AttendanceStatus.Pending},
    {"roll": "2203026", "name": "MD. NAYEM", "status": AttendanceStatus.Pending},
    {"roll": "2203027", "name": "MD.YEANUR HOSSAIN PARVEZ", "status": AttendanceStatus.Pending},
    {"roll": "2203028", "name": "MD. MOZAHID ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203029", "name": "AFIUJJAMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203030", "name": "SADIA FARHANA", "status": AttendanceStatus.Pending},
    {"roll": "2203031", "name": "MD. MHAFUZ TARAQ FARAZI", "status": AttendanceStatus.Pending},
    {"roll": "2203032", "name": "FATEMA TUZ ZOHORA BINTE AHASAN", "status": AttendanceStatus.Pending},
    {"roll": "2203033", "name": "ABHISHEK BHATTACHARJEE", "status": AttendanceStatus.Pending},
    {"roll": "2203034", "name": "ASHIQUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203035", "name": "MD. TALHA JUBAIR", "status": AttendanceStatus.Pending},
    {"roll": "2203036", "name": "MD. ROFAZ HASAN RAFIU", "status": AttendanceStatus.Pending},
    {"roll": "2203037", "name": "MD. NAZMUL HUDA", "status": AttendanceStatus.Pending},
    {"roll": "2203038", "name": "SUHAIL AHMED TOHA", "status": AttendanceStatus.Pending},
    {"roll": "2203039", "name": "SHAYM IMRAN", "status": AttendanceStatus.Pending},
    {"roll": "2203040", "name": "M. M. SAKLAIN", "status": AttendanceStatus.Pending},
    {"roll": "2203041", "name": "MD. RUBAIAT ISLAM SIAM", "status": AttendanceStatus.Pending},
    {"roll": "2203042", "name": "MAHAMUD-URR-RASHEED", "status": AttendanceStatus.Pending},
    {"roll": "2203043", "name": "MD. TAUFIQUR ISLAM RABBI", "status": AttendanceStatus.Pending},
    {"roll": "2203044", "name": "MD. ISTEAK AHAMED IMON", "status": AttendanceStatus.Pending},
    {"roll": "2203045", "name": "MD. EYAMIN HOSSAN MOLLA", "status": AttendanceStatus.Pending},
    {"roll": "2203046", "name": "SHOUMITRO DUTTA ORGHO", "status": AttendanceStatus.Pending},
    {"roll": "2203047", "name": "TAUSIF UL HUDA", "status": AttendanceStatus.Pending},
    {"roll": "2203048", "name": "MD.RUHUL AMIN PAPPO", "status": AttendanceStatus.Pending},
    {"roll": "2203049", "name": "SUPTI PAL", "status": AttendanceStatus.Pending},
    {"roll": "2203050", "name": "MIRZA WAJIH ALI", "status": AttendanceStatus.Pending},
    {"roll": "2203051", "name": "SANJIDA AFRIN", "status": AttendanceStatus.Pending},
    {"roll": "2203052", "name": "MD.SHUVO MIA", "status": AttendanceStatus.Pending},
    {"roll": "2203053", "name": "MAHDI HOSEN RUAN", "status": AttendanceStatus.Pending},
    {"roll": "2203054", "name": "TANZIRUL ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203055", "name": "ZARIN TASNIM ELAHI", "status": AttendanceStatus.Pending},
    {"roll": "2203056", "name": "MUHAMMAD BADRUDDIN TASNIM", "status": AttendanceStatus.Pending},
    {"roll": "2203057", "name": "FABLIHA NAOWAR NIZAM DEYA", "status": AttendanceStatus.Pending},
    {"roll": "2203058", "name": "SONGRAM BISWAS", "status": AttendanceStatus.Pending},
    {"roll": "2203059", "name": "MD.GOLAM RABBANI", "status": AttendanceStatus.Pending},
    {"roll": "2203060", "name": "MD. ABDULLAH ASH SHAFI", "status": AttendanceStatus.Pending},
    {"roll": "2203061", "name": "LUBNA SADIA", "status": AttendanceStatus.Pending},
    {"roll": "2203062", "name": "MAHMUDUL HASAN MAHMUD", "status": AttendanceStatus.Pending},
    {"roll": "2203063", "name": "SAIF HOSEN", "status": AttendanceStatus.Pending},
    {"roll": "2203064", "name": "MD. RIFAT HOSSAIN", "status": AttendanceStatus.Pending},
    {"roll": "2203065", "name": "MD. RADOUNUL ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203066", "name": "MD. MOSAROF HOSSAIN", "status": AttendanceStatus.Pending},
    {"roll": "2203067", "name": "MD. FAHIM FAYSAL RAFI", "status": AttendanceStatus.Pending},
    {"roll": "2203068", "name": "MD. NUSHAD JAMAN RAJ", "status": AttendanceStatus.Pending},
    {"roll": "2203069", "name": "MD TANJID HOSEN RIFAT", "status": AttendanceStatus.Pending},
    {"roll": "2203070", "name": "MASRUR MAHIN", "status": AttendanceStatus.Pending},
    {"roll": "2203071", "name": "ZAYED AHMED ANSARY", "status": AttendanceStatus.Pending},
    {"roll": "2203072", "name": "MD. SHANJID HASAN", "status": AttendanceStatus.Pending},
    {"roll": "2203073", "name": "MD. JAED HASAN RONI", "status": AttendanceStatus.Pending},
    {"roll": "2203074", "name": "MD. RAFIUL ISLAM OVI", "status": AttendanceStatus.Pending},
    {"roll": "2203075", "name": "MD. ABDUS SALAM", "status": AttendanceStatus.Pending},
    {"roll": "2203076", "name": "MD. RIDUAN ISLAM RIDU", "status": AttendanceStatus.Pending},
    {"roll": "2203077", "name": "MAHIR HAMI ABRAR", "status": AttendanceStatus.Pending},
    {"roll": "2203078", "name": "MD. ZUNAID KHAN NAIB", "status": AttendanceStatus.Pending},
    {"roll": "2203079", "name": "FARZANA FAIZA BORNO", "status": AttendanceStatus.Pending},
    {"roll": "2203080", "name": "AHMED ANDALEEF ARAFAT KIBRIA SADAB", "status": AttendanceStatus.Pending},
    {"roll": "2203081", "name": "ANIRUDDHA ROY", "status": AttendanceStatus.Pending},
    {"roll": "2203082", "name": "PARTHO PROTIM DAS", "status": AttendanceStatus.Pending},
    {"roll": "2203083", "name": "HRIDIKA MEJABIN AROBI", "status": AttendanceStatus.Pending},
    {"roll": "2203084", "name": "MUNTASIR ALL MAMUN BADHAN", "status": AttendanceStatus.Pending},
    {"roll": "2203085", "name": "SHIRSHEN DASGUPTA SHUVRA", "status": AttendanceStatus.Pending},
    {"roll": "2203086", "name": "SHAHRIAR HASAN SHANTO", "status": AttendanceStatus.Pending},
    {"roll": "2203087", "name": "MD. RIYON CHOWDHURY", "status": AttendanceStatus.Pending},
    {"roll": "2203088", "name": "UMMEY RUKAIYA", "status": AttendanceStatus.Pending},
    {"roll": "2203089", "name": "EVANGEL PURI", "status": AttendanceStatus.Pending},
    {"roll": "2203090", "name": "MD. NAJMUL ISLAM NAHID", "status": AttendanceStatus.Pending},
    {"roll": "2203091", "name": "S. M. SHORIFUL ISLAM SAJID", "status": AttendanceStatus.Pending},
    {"roll": "2203092", "name": "REDWON AHMED EMRAN", "status": AttendanceStatus.Pending},
    {"roll": "2203093", "name": "MEZBA UDDIN RUBAB", "status": AttendanceStatus.Pending},
    {"roll": "2203094", "name": "OMI CHOWDHURY", "status": AttendanceStatus.Pending},
    {"roll": "2203095", "name": "SAMIR YEASIR ALI", "status": AttendanceStatus.Pending},
    {"roll": "2203096", "name": "MD. RUBAYAT AHSAN", "status": AttendanceStatus.Pending},
    {"roll": "2203097", "name": "TAIZUL ISLAM ABIR", "status": AttendanceStatus.Pending},
    {"roll": "2203098", "name": "SIFAT AHASAN", "status": AttendanceStatus.Pending},
    {"roll": "2203099", "name": "MD. ASADULLAH-HIL GALIB", "status": AttendanceStatus.Pending},
    {"roll": "2203100", "name": "AYON DHAR", "status": AttendanceStatus.Pending},
    {"roll": "2203101", "name": "SHEIKH FAHMIDA OMI", "status": AttendanceStatus.Pending},
    {"roll": "2203102", "name": "MD. RUBAYET HASAN MUGDHO", "status": AttendanceStatus.Pending},
    {"roll": "2203103", "name": "FARIHA RAHMAN SNEHA", "status": AttendanceStatus.Pending},
    {"roll": "2203104", "name": "DIGBIJOY BHATTACHARJEE SHUVO", "status": AttendanceStatus.Pending},
    {"roll": "2203105", "name": "SABIKUNNAHER SHAILA", "status": AttendanceStatus.Pending},
    {"roll": "2203106", "name": "SOUVIK MOLLIK", "status": AttendanceStatus.Pending},
    {"roll": "2203107", "name": "NAFISA ANJUM", "status": AttendanceStatus.Pending},
    {"roll": "2203108", "name": "ANNIE AKTER", "status": AttendanceStatus.Pending},
    {"roll": "2203109", "name": "MASHRAFI MAHERIN RUMPA MONI", "status": AttendanceStatus.Pending},
    {"roll": "2203110", "name": "ASHIKUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203111", "name": "RAKIB SARKAR", "status": AttendanceStatus.Pending},
    {"roll": "2203112", "name": "RAF - RAFIN MAHMUD", "status": AttendanceStatus.Pending},
    {"roll": "2203113", "name": "JUHYER AL TAUSIF", "status": AttendanceStatus.Pending},
    {"roll": "2203114", "name": "SUMYEA BINTE ALADIN", "status": AttendanceStatus.Pending},
    {"roll": "2203115", "name": "SHOHARAB HOSSAIN RAMIM", "status": AttendanceStatus.Pending},
    {"roll": "2203116", "name": "MD. MIZANUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203117", "name": "SEFAT PERVEZ", "status": AttendanceStatus.Pending},
    {"roll": "2203118", "name": "JAHIDUL ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203119", "name": "INDRONIL ROY", "status": AttendanceStatus.Pending},
    {"roll": "2203120", "name": "TAYEF HASAN RAZIN", "status": AttendanceStatus.Pending},
    {"roll": "2203121", "name": "WAHID GALIB", "status": AttendanceStatus.Pending},
    {"roll": "2203122", "name": "MST. SEJUTI MONA", "status": AttendanceStatus.Pending},
    {"roll": "2203123", "name": "ANIKA TASNIM JASIA", "status": AttendanceStatus.Pending},
    {"roll": "2203124", "name": "ISHTIAK AHMAD ANAN", "status": AttendanceStatus.Pending},
    {"roll": "2203125", "name": "SAYED SHAFAQUE BIN NUR", "status": AttendanceStatus.Pending},
    {"roll": "2203126", "name": "MD. LABIB SHAHRIAR MAHI", "status": AttendanceStatus.Pending},
    {"roll": "2203127", "name": "JIT BANERJEE MITHUN", "status": AttendanceStatus.Pending},
    {"roll": "2203128", "name": "M.S. SAYEM", "status": AttendanceStatus.Pending},
    {"roll": "2203129", "name": "MD. ASHIKUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203130", "name": "SRAYOSHI MAHBUB", "status": AttendanceStatus.Pending},
    {"roll": "2203131", "name": "MD. ASIF SARKER", "status": AttendanceStatus.Pending},
    {"roll": "2203132", "name": "MST. LAMIA ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203133", "name": "MD. ABDULLAH AL AHAD", "status": AttendanceStatus.Pending},
    {"roll": "2203134", "name": "NIPU DAS", "status": AttendanceStatus.Pending},
    {"roll": "2203135", "name": "MD. HARUN-AR-RASHID", "status": AttendanceStatus.Pending},
    {"roll": "2203136", "name": "SHAHRIAR AHMED SOHAN", "status": AttendanceStatus.Pending},
    {"roll": "2203137", "name": "MD. IBN SINAN MAHDI", "status": AttendanceStatus.Pending},
    {"roll": "2203138", "name": "MD. AMANUR RAHMAN AKASH", "status": AttendanceStatus.Pending},
    {"roll": "2203139", "name": "ABDULLAH AL KAFI", "status": AttendanceStatus.Pending},
    {"roll": "2203140", "name": "MD. MARUFUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203141", "name": "MOST. SAKILA AKTER", "status": AttendanceStatus.Pending},
    {"roll": "2203142", "name": "SUVRO DEV ROY", "status": AttendanceStatus.Pending},
    {"roll": "2203143", "name": "MD. SULTANUL ARIFIN BAYEZEED", "status": AttendanceStatus.Pending},
    {"roll": "2203144", "name": "ANUP SARKER", "status": AttendanceStatus.Pending},
    {"roll": "2203145", "name": "MD. MUSHFIQUR RAHMAN MRIDUL", "status": AttendanceStatus.Pending},
    {"roll": "2203146", "name": "SHEIKH SIAM NAJAT", "status": AttendanceStatus.Pending},
    {"roll": "2203147", "name": "NAZIFA ANJUM", "status": AttendanceStatus.Pending},
    {"roll": "2203148", "name": "SAYAD MD. ABDULLAH", "status": AttendanceStatus.Pending},
    {"roll": "2203149", "name": "MD. IFTEKHAR HOSSAIN", "status": AttendanceStatus.Pending},
    {"roll": "2203150", "name": "MD. SUMON REZA", "status": AttendanceStatus.Pending},
    {"roll": "2203151", "name": "ANIK BARAL RONY", "status": AttendanceStatus.Pending},
    {"roll": "2203152", "name": "MD. ALVI ARAF", "status": AttendanceStatus.Pending},
    {"roll": "2203153", "name": "S.M MUSFIKUR RAHMAN", "status": AttendanceStatus.Pending},
    {"roll": "2203154", "name": "A. B. M. RISALAT", "status": AttendanceStatus.Pending},
    {"roll": "2203155", "name": "NAEEM", "status": AttendanceStatus.Pending},
    {"roll": "2203156", "name": "MST. SANJIDA NAHAR SHISHIR", "status": AttendanceStatus.Pending},
    {"roll": "2203157", "name": "AFSHARA TASNIM", "status": AttendanceStatus.Pending},
    {"roll": "2203158", "name": "HUMAIRA KHATUN", "status": AttendanceStatus.Pending},
    {"roll": "2203159", "name": "MD.YEASIN ARAFAT", "status": AttendanceStatus.Pending},
    {"roll": "2203160", "name": "A.N.M. SHARZIL IZAZ MAHMUD", "status": AttendanceStatus.Pending},
    {"roll": "2203161", "name": "MD. ASHFAQ AHAMED", "status": AttendanceStatus.Pending},
    {"roll": "2203162", "name": "MD. AJHARUL ISLAM JOBAER", "status": AttendanceStatus.Pending},
    {"roll": "2203163", "name": "NIYAJ MORSHADIN", "status": AttendanceStatus.Pending},
    {"roll": "2203164", "name": "RAFIUL ISLAM TUTUL", "status": AttendanceStatus.Pending},
    {"roll": "2203165", "name": "SADIA HOQUE", "status": AttendanceStatus.Pending},
    {"roll": "2203166", "name": "TAREQ ABRAR", "status": AttendanceStatus.Pending},
    {"roll": "2203167", "name": "SHRABANTI SAHA MITHI", "status": AttendanceStatus.Pending},
    {"roll": "2203168", "name": "SHUVO DIP KAR", "status": AttendanceStatus.Pending},
    {"roll": "2203169", "name": "KHAN MD. TANZIM ASHIQUE", "status": AttendanceStatus.Pending},
    {"roll": "2203170", "name": "AAB-E-KOWSOR DIP", "status": AttendanceStatus.Pending},
    {"roll": "2203171", "name": "NAFIS AHMED JISHAN", "status": AttendanceStatus.Pending},
    {"roll": "2203172", "name": "MD. SOYEB AZAM SEFAT", "status": AttendanceStatus.Pending},
    {"roll": "2203173", "name": "MD. NEWAJ SHARIF", "status": AttendanceStatus.Pending},
    {"roll": "2203174", "name": "SHEMANTA DEBNATH", "status": AttendanceStatus.Pending},
    {"roll": "2203175", "name": "SUSMOY DEBNATH", "status": AttendanceStatus.Pending},
    {"roll": "2203176", "name": "MD. ASHSHAHRIL LABIB", "status": AttendanceStatus.Pending},
    {"roll": "2203177", "name": "MD. ISTIAK AHMED IFTI", "status": AttendanceStatus.Pending},
    {"roll": "2203178", "name": "A. T. M. ZOBAYERUL ISLAM", "status": AttendanceStatus.Pending},
    {"roll": "2203179", "name": "SAMIN YASAR SHASSO", "status": AttendanceStatus.Pending},
    {"roll": "2203180", "name": "SHAFAH TASFIA", "status": AttendanceStatus.Pending},
    {"roll": "2203181", "name": "BINOY KUMAR CHAKMA", "status": AttendanceStatus.Pending},
  ];

  // Function to pick a date
  void _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to mark attendance
  void _markAttendance(int index, AttendanceStatus status) {
    setState(() {
      students[index]["status"] = status;
    });
  }

  // Function to filter students by section
  List<Map<String, dynamic>> _getStudentsBySection(String section) {
    int startRoll, endRoll;
    switch (section) {
      case 'A':
        startRoll = 2203001;
        endRoll = 2203060;
        break;
      case 'B':
        startRoll = 2203061;
        endRoll = 2203120;
        break;
      case 'C':
        startRoll = 2203121;
        endRoll = 2203181;
        break;
      default:
        startRoll = 2203001;
        endRoll = 2203181;
    }
    return students.where((student) {
      int roll = int.parse(student["roll"]);
      return roll >= startRoll && roll <= endRoll;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sectionStudents = _getStudentsBySection(selectedSection);

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Report"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: selectedCourse,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCourse = newValue!;
                        });
                      },
                      items: courses.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    DropdownButton<String>(
                      value: selectedSection,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSection = newValue!;
                        });
                      },
                      items: <String>['A', 'B', 'C']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text("Section $value"),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: sectionStudents.length,
              itemBuilder: (context, index) {
                final student = sectionStudents[index];
                final status = student["status"] as AttendanceStatus;
                return _StudentCard(
                  roll: student["roll"],
                  name: student["name"],
                  status: status,
                  onStatusChanged: (newStatus) {
                    // Find the original index in the full students list
                    int originalIndex = students.indexWhere((s) => s["roll"] == student["roll"]);
                    _markAttendance(originalIndex, newStatus);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String roll;
  final String name;
  final AttendanceStatus status;
  final Function(AttendanceStatus) onStatusChanged;

  const _StudentCard({
    required this.roll,
    required this.name,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          status.icon,
          color: status.color,
          size: 30,
        ),
        title: Text(
          "$roll - $name",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Status: ${status.displayName}",
          style: TextStyle(color: status.color, fontSize: 16),
        ),
        trailing: PopupMenuButton<AttendanceStatus>(
          icon: Icon(Icons.more_vert),
          onSelected: onStatusChanged,
          itemBuilder: (BuildContext context) => AttendanceStatus.values.map((status) {
            return PopupMenuItem(
              value: status,
              child: Text("Mark ${status.displayName}"),
            );
          }).toList(),
        ),
      ),
    );
  }
}

enum AttendanceStatus {
  Present,
  Absent,
  Late,
  Pending,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.Present:
        return "Present";
      case AttendanceStatus.Absent:
        return "Absent";
      case AttendanceStatus.Late:
        return "Late";
      case AttendanceStatus.Pending:
        return "Pending";
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.Present:
        return Icons.check_circle;
      case AttendanceStatus.Absent:
        return Icons.cancel;
      case AttendanceStatus.Late:
        return Icons.access_time;
      case AttendanceStatus.Pending:
        return Icons.hourglass_empty;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.Present:
        return Colors.green;
      case AttendanceStatus.Absent:
        return Colors.red;
      case AttendanceStatus.Late:
        return Colors.orange;
      case AttendanceStatus.Pending:
        return Colors.grey;
    }
  }
}