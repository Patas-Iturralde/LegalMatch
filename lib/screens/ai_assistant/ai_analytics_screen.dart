import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIAnalyticsScreen extends StatefulWidget {
  @override
  _AIAnalyticsScreenState createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, int> _specialtyStats = {};
  int _totalConsultations = 0;
  int _urgentCases = 0;
  double _averageConfidence = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Obtener todas las consultas procesadas por IA
      final querySnapshot = await _firestore
          .collection('live_chats')
          .where('aiProcessed', isEqualTo: true)
          .get();

      Map<String, int> specialties = {};
      int urgent = 0;
      double totalConfidence = 0.0;
      int confidenceCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Contar especialidades
        final specialty = data['detectedSpecialty'] as String?;
        if (specialty != null) {
          specialties[specialty] = (specialties[specialty] ?? 0) + 1;
        }

        // Contar urgentes
        if (data['isUrgent'] == true) {
          urgent++;
        }

        // Calcular confianza promedio (simulado)
        totalConfidence += 0.85; // Valor simulado
        confidenceCount++;
      }

      setState(() {
        _specialtyStats = specialties;
        _totalConsultations = querySnapshot.docs.length;
        _urgentCases = urgent;
        _averageConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Análisis de IA Legal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Estadísticas de consultas procesadas por IA',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),

          // Tarjetas de estadísticas generales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Total Consultas',
                  value: _totalConsultations.toString(),
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.warning,
                  title: 'Casos Urgentes',
                  value: _urgentCases.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.analytics,
                  title: 'Confianza Promedio',
                  value: '${(_averageConfidence * 100).toInt()}%',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.category,
                  title: 'Especialidades',
                  value: _specialtyStats.length.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),

          // Distribución por especialidades
          Text(
            'Distribución por Especialidades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildSpecialtyChart(),
          SizedBox(height: 32),

          // Tendencias recientes
          Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChart() {
    if (_specialtyStats.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No hay datos de especialidades disponibles',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final total = _specialtyStats.values.reduce((a, b) => a + b);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return Column(
      children: _specialtyStats.entries.map((entry) {
        final index = _specialtyStats.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        final percentage = (entry.value / total * 100).toInt();

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${entry.value} ($percentage%)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('live_chats')
          .where('aiProcessed', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            height: 100,
            child: Center(
              child: Text(
                'No hay actividad reciente',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final specialty = data['detectedSpecialty'] ?? 'General';
            final isUrgent = data['isUrgent'] ?? false;
            final timestamp = (data['createdAt'] as Timestamp).toDate();
            final userName = data['userName'] ?? 'Usuario';

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: isUrgent 
                    ? Border.all(color: Colors.red.shade300, width: 2)
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.red.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isUrgent ? Icons.warning : Icons.chat_bubble_outline,
                      color: isUrgent ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                specialty,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isUrgent) ...[
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'URGENTE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}