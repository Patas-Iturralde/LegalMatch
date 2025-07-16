import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AISettingsScreen extends StatefulWidget {
  final bool isLawyer;

  const AISettingsScreen({Key? key, required this.isLawyer}) : super(key: key);

  @override
  _AISettingsScreenState createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  // Configuraciones de IA
  bool _autoAnalysis = true;
  bool _urgentNotifications = true;
  bool _detailedResponses = false;
  bool _followUpQuestions = true;
  bool _saveConversations = true;
  bool _contextAwareResponses = true;
  
  // Configuraciones de interfaz
  String _selectedLanguage = 'Español';
  String _responseStyle = 'Profesional';
  double _confidenceThreshold = 0.8;
  int _maxFollowUpQuestions = 3;
  
  // Estados
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Datos para analytics
  int _totalChats = 0;
  int _totalMessages = 0;
  String _lastUsed = 'Nunca';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserStats();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _autoAnalysis = prefs.getBool('ai_auto_analysis') ?? true;
        _urgentNotifications = prefs.getBool('ai_urgent_notifications') ?? true;
        _detailedResponses = prefs.getBool('ai_detailed_responses') ?? false;
        _followUpQuestions = prefs.getBool('ai_follow_up_questions') ?? true;
        _saveConversations = prefs.getBool('ai_save_conversations') ?? true;
        _contextAwareResponses = prefs.getBool('ai_context_aware') ?? true;
        _selectedLanguage = prefs.getString('ai_language') ?? 'Español';
        _responseStyle = prefs.getString('ai_response_style') ?? 'Profesional';
        _confidenceThreshold = prefs.getDouble('ai_confidence_threshold') ?? 0.8;
        _maxFollowUpQuestions = prefs.getInt('ai_max_follow_up') ?? 3;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar configuración: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('ai_chats')
          .where('userId', isEqualTo: user.uid)
          .get();

      int messageCount = 0;
      DateTime? lastActivity;

      for (var chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        messageCount += (chatData['messageCount'] as int?) ?? 0;
        
        final lastActivityTimestamp = chatData['lastActivity'] as Timestamp?;
        if (lastActivityTimestamp != null) {
          final activityDate = lastActivityTimestamp.toDate();
          if (lastActivity == null || activityDate.isAfter(lastActivity)) {
            lastActivity = activityDate;
          }
        }
      }

      setState(() {
        _totalChats = chatsSnapshot.docs.length;
        _totalMessages = messageCount;
        _lastUsed = lastActivity != null ? _formatDate(lastActivity) : 'Nunca';
      });
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool('ai_auto_analysis', _autoAnalysis),
        prefs.setBool('ai_urgent_notifications', _urgentNotifications),
        prefs.setBool('ai_detailed_responses', _detailedResponses),
        prefs.setBool('ai_follow_up_questions', _followUpQuestions),
        prefs.setBool('ai_save_conversations', _saveConversations),
        prefs.setBool('ai_context_aware', _contextAwareResponses),
        prefs.setString('ai_language', _selectedLanguage),
        prefs.setString('ai_response_style', _responseStyle),
        prefs.setDouble('ai_confidence_threshold', _confidenceThreshold),
        prefs.setInt('ai_max_follow_up', _maxFollowUpQuestions),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Configuración guardada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al guardar configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al guardar la configuración'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restablecer Configuración'),
        content: Text('¿Estás seguro de que quieres restablecer todas las configuraciones a sus valores predeterminados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Restablecer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración restablecida'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearAIHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Historial de IA'),
        content: Text('¿Estás seguro de que quieres eliminar todo tu historial de conversaciones con la IA? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final batch = FirebaseFirestore.instance.batch();
        final chatsSnapshot = await FirebaseFirestore.instance
            .collection('ai_chats')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in chatsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        await _loadUserStats();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Historial de IA eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar historial'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 16),
            Text('Cargando configuración...')
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estadísticas
            _buildHeaderCard(),
            SizedBox(height: 24),

            // Configuración de Análisis
            _buildSectionCard(
              title: 'Análisis Automático',
              icon: Icons.analytics,
              children: [
                _buildSwitchTile(
                  title: 'Análisis automático de consultas',
                  subtitle: 'Clasificar automáticamente las consultas legales por especialidad',
                  value: _autoAnalysis,
                  onChanged: (value) => setState(() => _autoAnalysis = value),
                ),
                if (widget.isLawyer)
                  _buildSwitchTile(
                    title: 'Notificaciones de casos urgentes',
                    subtitle: 'Recibir alertas cuando se detecten casos que requieren atención inmediata',
                    value: _urgentNotifications,
                    onChanged: (value) => setState(() => _urgentNotifications = value),
                  ),
                _buildSwitchTile(
                  title: 'Respuestas contextuales',
                  subtitle: 'Usar el contexto de la conversación para mejores respuestas',
                  value: _contextAwareResponses,
                  onChanged: (value) => setState(() => _contextAwareResponses = value),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Configuración de Respuestas
            _buildSectionCard(
              title: 'Respuestas de IA',
              icon: Icons.chat_bubble,
              children: [
                _buildSwitchTile(
                  title: 'Respuestas detalladas',
                  subtitle: 'Obtener respuestas más completas y explicativas',
                  value: _detailedResponses,
                  onChanged: (value) => setState(() => _detailedResponses = value),
                ),
                _buildSwitchTile(
                  title: 'Preguntas de seguimiento',
                  subtitle: 'Generar preguntas para obtener más información relevante',
                  value: _followUpQuestions,
                  onChanged: (value) => setState(() => _followUpQuestions = value),
                ),
                if (_followUpQuestions)
                  _buildSliderTile(
                    title: 'Máximo de preguntas de seguimiento',
                    value: _maxFollowUpQuestions.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => _maxFollowUpQuestions = value.toInt()),
                    displayValue: _maxFollowUpQuestions.toString(),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Configuración General
            _buildSectionCard(
              title: 'Configuración General',
              icon: Icons.settings,
              children: [
                _buildDropdownTile(
                  title: 'Idioma de respuestas',
                  subtitle: 'Idioma para las respuestas de la IA',
                  value: _selectedLanguage,
                  items: ['Español', 'English', 'Português'],
                  onChanged: (value) => setState(() => _selectedLanguage = value!),
                ),
                _buildDropdownTile(
                  title: 'Estilo de respuesta',
                  subtitle: 'Tono y estilo de las respuestas de la IA',
                  value: _responseStyle,
                  items: ['Profesional', 'Casual', 'Académico', 'Empático'],
                  onChanged: (value) => setState(() => _responseStyle = value!),
                ),
                if (widget.isLawyer)
                  _buildSliderTile(
                    title: 'Umbral de confianza',
                    subtitle: 'Nivel mínimo de confianza para mostrar análisis',
                    value: _confidenceThreshold,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) => setState(() => _confidenceThreshold = value),
                    displayValue: '${(_confidenceThreshold * 100).toInt()}%',
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Privacidad y Datos
            _buildSectionCard(
              title: 'Privacidad y Datos',
              icon: Icons.privacy_tip,
              children: [
                _buildSwitchTile(
                  title: 'Guardar conversaciones',
                  subtitle: 'Almacenar el historial de chats para mejorar la experiencia',
                  value: _saveConversations,
                  onChanged: (value) => setState(() => _saveConversations = value),
                ),
                SizedBox(height: 8),
                _buildActionTile(
                  title: 'Eliminar historial de IA',
                  subtitle: 'Borrar todas las conversaciones guardadas con la IA',
                  icon: Icons.delete_outline,
                  color: Colors.orange,
                  onTap: _clearAIHistory,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Información del Sistema
            _buildInfoSection(),
            SizedBox(height: 32),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Guardar Configuración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _resetSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade400, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.smart_toy, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personaliza tu experiencia con el asistente legal',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatChip('Chats', _totalChats.toString())),
              SizedBox(width: 12),
              Expanded(child: _buildStatChip('Mensajes', _totalMessages.toString())),
              SizedBox(width: 12),
              Expanded(child: _buildStatChip('Último uso', _lastUsed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.cyan, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.cyan,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String displayValue,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          if (subtitle != null)
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: onChanged,
            activeColor: Colors.cyan,
          ),
          Text(
            'Valor actual: $displayValue',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.cyan.shade700),
              SizedBox(width: 8),
              Text(
                'Información del Sistema IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow('Modelo de IA:', 'Google Gemini Pro'),
          _buildInfoRow('Versión:', '1.0.0'),
          _buildInfoRow('Especialidades:', '8 áreas legales'),
          _buildInfoRow('Idiomas soportados:', 'Español, English, Português'),
          _buildInfoRow('Precisión promedio:', '85%'),
          _buildInfoRow('Última actualización:', 'Julio 2025'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recordatorio: La IA proporciona orientación general. Siempre consulta con un abogado para asesoría legal específica.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}