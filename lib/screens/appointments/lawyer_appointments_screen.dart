import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../services/lawyer_service.dart';

class LawyerAppointmentsScreen extends StatefulWidget {
  @override
  _LawyerAppointmentsScreenState createState() => _LawyerAppointmentsScreenState();
}

class _LawyerAppointmentsScreenState extends State<LawyerAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final LawyerService _lawyerService = LawyerService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _appointmentService.getLawyerAppointments(user.uid).listen((appointments) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return _appointments.where((appointment) {
      return isSameDay(appointment.startTime, day);
    }).toList();
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }
  
  Future<void> _showAddAppointmentDialog(BuildContext context) async {
    if (_selectedDay == null) return;

    // Restablecer los valores del formulario
    _titleController.text = 'Consulta';
    _notesController.text = '';
    _startTime = TimeOfDay(hour: 9, minute: 0);
    _endTime = TimeOfDay(hour: 10, minute: 0);
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agendar espacio en calendario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha: ${DateFormat('EEEE d MMMM, yyyy', 'es').format(_selectedDay!)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text('Hora de inicio:'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                _startTime = time;
                                // Si la hora de fin es anterior a la hora de inicio, ajustarla
                                if (_endTime.hour < _startTime.hour || 
                                   (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
                                  _endTime = TimeOfDay(
                                    hour: _startTime.hour + 1,
                                    minute: _startTime.minute,
                                  );
                                }
                              });
                            }
                          },
                          child: Text(
                            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text('Hora de fin:'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              // Verificar que la hora de fin sea después de la hora de inicio
                              if (time.hour > _startTime.hour || 
                                 (time.hour == _startTime.hour && time.minute > _startTime.minute)) {
                                setState(() {
                                  _endTime = time;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('La hora de fin debe ser posterior a la hora de inicio')),
                                );
                              }
                            }
                          },
                          child: Text(
                            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _saveAppointment(context),
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _saveAppointment(BuildContext context) async {
    if (_selectedDay == null) return;
    
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;
    
    // Convertir la fecha seleccionada y la hora de inicio/fin a DateTime
    final startDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    try {
      // Verificar disponibilidad
      bool isAvailable = await _appointmentService.checkAvailability(
        user.uid,
        startDateTime,
        endDateTime,
      );
      
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya existe una cita en ese horario')),
        );
        return;
      }
      
      // Crear la cita
      final lawyer = await _lawyerService.getLawyerById(user.uid);
      if (lawyer == null) throw Exception('No se encontró información del abogado');
      
      final appointment = Appointment(
        id: '',
        lawyerId: user.uid,
        lawyerName: lawyer.name,
        clientId: '', // Espacio reservado, sin cliente asignado
        clientName: '',
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'reserved', // Espacio reservado
        notes: _notesController.text.trim(),
        title: _titleController.text.trim(),
      );
      
      await _appointmentService.createAppointment(appointment);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Espacio reservado en el calendario')),
      );
    } catch (e) {
      print('Error al guardar cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar espacio: $e')),
      );
    }
  }
  
  Future<void> _showAppointmentDetails(BuildContext context, Appointment appointment) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appointment.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${DateFormat('EEEE d MMMM, yyyy', 'es').format(appointment.startTime)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                
                Text(
                  'Horario: ${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                
                if (appointment.clientId.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cliente: ${appointment.clientName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                    ],
                  ),
                
                Text(
                  'Estado: ${_getStatusText(appointment.status)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(appointment.status),
                  ),
                ),
                SizedBox(height: 16.0),
                
                if (appointment.notes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.0),
                      Text(appointment.notes),
                      SizedBox(height: 16.0),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            if (appointment.status != 'cancelled')
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _appointmentService.cancelAppointment(appointment.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cita cancelada')),
                  );
                },
                child: Text('Cancelar Cita', style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmada';
      case 'completed': return 'Completada';
      case 'cancelled': return 'Cancelada';
      case 'reserved': return 'Espacio Reservado';
      default: return 'Desconocido';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'reserved': return Colors.purple;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Citas'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendario
                Card(
                  margin: EdgeInsets.all(8.0),
                  elevation: 2.0,
                  child: TableCalendar(
                    locale: 'es_ES',
                    firstDay: DateTime.now().subtract(Duration(days: 365)),
                    lastDay: DateTime.now().add(Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: {
                      CalendarFormat.month: 'Mes',
                      CalendarFormat.twoWeeks: '2 Semanas',
                      CalendarFormat.week: 'Semana',
                    },
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    // Marcadores para los días con citas
                    eventLoader: (day) {
                      return _getAppointmentsForDay(day);
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, appointments) {
                        if (appointments.isEmpty) return SizedBox.shrink();
                        
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                            width: 16.0,
                            height: 16.0,
                            child: Center(
                              child: Text(
                                '${appointments.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Lista de citas para el día seleccionado
                Expanded(
                  child: _selectedDay == null
                      ? Center(child: Text('Selecciona un día para ver las citas'))
                      : _buildAppointmentsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointmentDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Agendar espacio',
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    final appointmentsForDay = _getAppointmentsForDay(_selectedDay!);
    
    if (appointmentsForDay.isEmpty) {
      return Center(
        child: Text('No hay citas para este día'),
      );
    }
    
    // Ordenar por hora de inicio
    appointmentsForDay.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return ListView.builder(
      itemCount: appointmentsForDay.length,
      padding: EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final appointment = appointmentsForDay[index];
        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Container(
              width: 10.0,
              color: _getStatusColor(appointment.status),
            ),
            title: Text(appointment.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}'),
                if (appointment.clientId.isNotEmpty)
                  Text('Cliente: ${appointment.clientName}'),
                Text('Estado: ${_getStatusText(appointment.status)}'),
              ],
            ),
            onTap: () => _showAppointmentDetails(context, appointment),
          ),
        );
      },
    );
  }
}