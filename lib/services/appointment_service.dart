import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear una nueva cita
  Future<void> createAppointment(Appointment appointment) async {
    // Verificar si ya existe una cita en el mismo horario para el abogado
    QuerySnapshot existingAppointments = await _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: appointment.lawyerId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    // Verificar si hay solapamiento de horarios
    bool hasOverlap = existingAppointments.docs.any((doc) {
      final existing = Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Verificar si la nueva cita se solapa con alguna existente
      return (appointment.startTime.isBefore(existing.endTime) && 
              appointment.endTime.isAfter(existing.startTime));
    });

    if (hasOverlap) {
      throw Exception('Ya existe una cita en ese horario');
    }

    // Crear la cita
    await _firestore.collection('appointments').add(appointment.toMap());
  }

  // Obtener citas de un abogado
  Stream<List<Appointment>> getLawyerAppointments(String lawyerId) {
    return _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener citas de un cliente
  Stream<List<Appointment>> getClientAppointments(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener todas las citas de un abogado para un mes específico
  Future<List<Appointment>> getLawyerAppointmentsForMonth(String lawyerId, DateTime month) async {
    // Crear fecha de inicio (primer día del mes) y fin (primer día del mes siguiente)
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNextMonth = DateTime(month.year, month.month + 1, 1);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('startTime', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .get();

    return snapshot.docs.map((doc) {
      return Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Actualizar el estado de una cita
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
    });
  }

  // Actualizar notas de una cita
  Future<void> updateAppointmentNotes(String appointmentId, String notes) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'notes': notes,
    });
  }

  // Cancelar una cita
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'cancelled',
    });
  }

  // Verificar disponibilidad de horario
  Future<bool> checkAvailability(String lawyerId, DateTime startTime, DateTime endTime) async {
    QuerySnapshot existingAppointments = await _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    // Verificar si hay solapamiento de horarios
    bool hasOverlap = existingAppointments.docs.any((doc) {
      final existing = Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Verificar si el horario propuesto se solapa con alguna cita existente
      return (startTime.isBefore(existing.endTime) && 
              endTime.isAfter(existing.startTime));
    });

    return !hasOverlap; // Retorna true si está disponible (no hay solapamiento)
  }

  // Obtener los horarios disponibles para un día específico
  Future<List<TimeSlot>> getAvailableTimeSlots(String lawyerId, DateTime date) async {
  // Define los horarios estándar (9 AM a 5 PM, citas de 1 hora)
  final List<TimeSlot> standardSlots = [];
  
  // Crear horarios de 9 AM a 5 PM con intervalos de 1 hora
  DateTime startHour = DateTime(date.year, date.month, date.day, 9, 0);
  DateTime endWorkDay = DateTime(date.year, date.month, date.day, 17, 0);
  
  while (startHour.isBefore(endWorkDay)) {
    DateTime endHour = startHour.add(Duration(hours: 1));
    standardSlots.add(TimeSlot(start: startHour, end: endHour));
    startHour = endHour;
  }
  
  // Obtener citas existentes para ese día
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(Duration(days: 1));
  
  QuerySnapshot snapshot = await _firestore
      .collection('appointments')
      .where('lawyerId', isEqualTo: lawyerId)
      .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
      .get();
  
  List<Appointment> existingAppointments = snapshot.docs.map((doc) {
    return Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }).toList();
  
  // Filtrar horarios no disponibles
  List<TimeSlot> availableSlots = standardSlots.where((slot) {
    return !existingAppointments.any((appointment) {
      // Una cita se solapa si:
      // 1. El inicio de la cita está dentro del slot, o
      // 2. El fin de la cita está dentro del slot, o
      // 3. La cita comienza antes y termina después del slot
      bool overlaps = (appointment.startTime.isAtSameMomentAs(slot.start) || 
                        (appointment.startTime.isAfter(slot.start) && 
                         appointment.startTime.isBefore(slot.end))) ||
                       (appointment.endTime.isAfter(slot.start) && 
                        appointment.endTime.isBefore(slot.end)) ||
                       (appointment.startTime.isBefore(slot.start) && 
                        appointment.endTime.isAfter(slot.end));
      
      // Solo filtramos citas que no estén canceladas
      return overlaps && appointment.status != 'cancelled';
    });
  }).toList();
  
  return availableSlots;
}

  // En AppointmentService
Future<void> initializeAvailableHours(String lawyerId) async {
  // Obtener la fecha actual
  final now = DateTime.now();
  
  // Para los próximos 30 días
  for (int i = 0; i < 30; i++) {
    final date = now.add(Duration(days: i));
    
    // Solo días laborables (lunes a viernes)
    if (date.weekday >= 1 && date.weekday <= 5) {
      // Horarios de 9 AM a 5 PM con citas de 1 hora
      for (int hour = 9; hour < 17; hour++) {
        final startTime = DateTime(date.year, date.month, date.day, hour, 0);
        final endTime = startTime.add(Duration(hours: 1));
        
        // Verificar si el horario ya existe
        bool exists = await _checkIfTimeSlotExists(lawyerId, startTime, endTime);
        
        if (!exists) {
          // Crear horario disponible
          final appointment = Appointment(
            id: '',
            lawyerId: lawyerId,
            lawyerName: '', // Se actualizará en el servicio
            clientId: '', // Vacío porque está disponible
            clientName: '',
            startTime: startTime,
            endTime: endTime,
            status: 'available', // Estado especial para horarios disponibles
            notes: '',
            title: 'Disponible',
          );
          
          await _firestore.collection('appointments').add(appointment.toMap());
        }
      }
    }
  }
}

// Método auxiliar para verificar si un horario ya existe
Future<bool> _checkIfTimeSlotExists(String lawyerId, DateTime startTime, DateTime endTime) async {
  final QuerySnapshot snapshot = await _firestore
      .collection('appointments')
      .where('lawyerId', isEqualTo: lawyerId)
      .where('startTime', isEqualTo: Timestamp.fromDate(startTime))
      .where('endTime', isEqualTo: Timestamp.fromDate(endTime))
      .get();
  
  return snapshot.docs.isNotEmpty;
}
}

// Clase auxiliar para representar un horario disponible
class TimeSlot {
  final DateTime start;
  final DateTime end;
  
  TimeSlot({required this.start, required this.end});
}