import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'ai_chat_screen.dart';
import 'ai_settings_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  final bool isLawyer;

  const AIAssistantScreen({Key? key, required this.isLawyer}) : super(key: key);

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GlobalKey<AIChatScreenState> _chatScreenKey = GlobalKey<AIChatScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, // Solo Chat IA y Configuración
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startNewChat() {
    // Llamar al método de nueva conversación en el chat screen
    if (_tabController.index == 0) {
      _chatScreenKey.currentState?.startNewChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistente de IA Legal'),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        actions: [
          // Botón de nueva conversación solo visible en la pestaña de chat
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                return IconButton(
                  onPressed: _startNewChat,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Nueva conversación',
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.chat),
              text: 'Chat IA',
            ),
            Tab(
              icon: Icon(Icons.settings),
              text: 'Configuración',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chat con IA
          AIChatScreen(
            key: _chatScreenKey,
            isLawyer: widget.isLawyer,
          ),
          
          // Configuración
          AISettingsScreen(isLawyer: widget.isLawyer),
        ],
      ),
    );
  }
}

// Widget de introducción para mostrar en la parte superior
class AIIntroCard extends StatelessWidget {
  final bool isLawyer;

  const AIIntroCard({Key? key, required this.isLawyer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
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
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente Legal IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Powered by Gemini AI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            isLawyer
                ? 'Como abogado, puedes usar la IA para:\n'
                  '• Analizar consultas de clientes\n'
                  '• Clasificar casos por especialidad\n'
                  '• Detectar casos urgentes\n'
                  '• Obtener respuestas legales específicas'
                : 'Como cliente, puedes usar la IA para:\n'
                  '• Obtener orientación legal inicial\n'
                  '• Clasificar tu problema legal\n'
                  '• Preparar preguntas para abogados\n'
                  '• Entender términos legales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Respuestas instantáneas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Datos seguros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar estadísticas rápidas
class AIStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.chat_bubble_outline,
              label: 'Consultas IA',
              value: '24',
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.category,
              label: 'Clasificadas',
              value: '18',
              color: Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.warning_outlined,
              label: 'Urgentes',
              value: '3',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
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
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
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
}