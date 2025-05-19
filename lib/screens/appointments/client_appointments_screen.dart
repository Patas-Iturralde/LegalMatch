import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/lawyer.dart';
import '../../services/appointment_service.dart';
import '../../services/lawyer_service.dart';
import '../home/lawyer_detail_screen.dart';

class ClientAppointmentsScreen extends StatefulWidget {
  @override
  _ClientAppointmentsScreenState createState() => _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen> with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final LawyerService _lawyerService = LawyerService();
  
  late TabController _tabController;
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _appointmentService.getClientAppointments(user.uid).listen((appointments) {
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
  
  List<Appointment> _getFilteredAppointments(String filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case 'upcoming':
        return _appointments.where((appointment) {
          return (appointment.status == 'pending' || appointment.status == 'confirmed') &&
                 appointment.startTime.isAfter(now);
        }).toList();
      case 'past':
        return _appointments.where((appointment) {
          return appointment.status == 'completed' || 
                 appointment.endTime.isBefore(now);
        }).toList();
      case 'cancelled':
        return _appointments.where((appointment) {
          return appointment.status == 'cancelled';
        }).toList();
      default:
        return _appointments;
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
                
                Text(
                  'Abogado: ${appointment.lawyerName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LawyerDetailScreen(lawyerId: appointment.lawyerId),
                  ),
                );
              },
              child: Text('Ver Perfil del Abogado'),
            ),
            if (appointment.status != 'cancelled' && appointment.status != 'completed')
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
  
  Future<void> _scheduleNewAppointment() async {
    // Navegar a la lista de abogados para programar una cita
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selecciona un abogado para agendar una cita')),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmada';
      case 'completed': return 'Completada';
      case 'cancelled': return 'Cancelada';
      default: return 'Desconocido';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Próximas'),
            Tab(text: 'Pasadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList('upcoming'),
                _buildAppointmentsList('past'),
                _buildAppointmentsList('cancelled'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scheduleNewAppointment,
        child: Icon(Icons.add),
        tooltip: 'Agendar nueva cita',
      ),
    );
  }
  
  Widget _buildAppointmentsList(String filter) {
    final filteredAppointments = _getFilteredAppointments(filter);
    
    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'upcoming' ? Icons.event_available : 
              filter == 'past' ? Icons.history : Icons.cancel,
              size: 64.0,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.0),
            Text(
              filter == 'upcoming' ? 'No tienes citas próximas' : 
              filter == 'past' ? 'No tienes citas pasadas' : 'No tienes citas canceladas',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Ordenar citas
    if (filter == 'upcoming') {
      filteredAppointments.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      filteredAppointments.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
    
    return ListView.builder(
      itemCount: filteredAppointments.length,
      padding: EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
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
                Text('${DateFormat('dd/MM/yyyy').format(appointment.startTime)} ${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}'),
                Text('Abogado: ${appointment.lawyerName}'),
              ],
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showAppointmentDetails(context, appointment),
          ),
        );
      },
    );
  }
}