import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lawyer.dart';
import '../../models/review.dart';
import '../../services/lawyer_service.dart';
import '../../services/auth_service.dart';
import 'dart:convert';

class LawyerDetailScreen extends StatefulWidget {
  final String lawyerId;

  LawyerDetailScreen({required this.lawyerId});

  @override
  _LawyerDetailScreenState createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> {
  final LawyerService _lawyerService = LawyerService();
  final AuthService _authService = AuthService();
  Lawyer? _lawyer;
  bool _isLoading = true;
  bool _isSubmittingReview = false;
  double _userRating = 3.0;
  final _reviewController = TextEditingController();
  late Future<UserType> _userTypeFuture;

  @override
  void initState() {
    super.initState();
    _loadLawyerData();
    _loadUserType();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadLawyerData() async {
    try {
      final lawyer = await _lawyerService.getLawyerById(widget.lawyerId);
      setState(() {
        _lawyer = lawyer;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del abogado: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserType() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _userTypeFuture = _authService.getUserType(user.uid);
    }
  }

  // Método para contactar al abogado por WhatsApp
  Future<void> _contactViaWhatsApp() async {
    if (_lawyer == null) return;

    try {
      // Formatear el número de teléfono (eliminar espacios, paréntesis, etc.)
      String phone = _lawyer!.phone ?? "123456789";
      phone = phone.replaceAll(RegExp(r'[^\d+]'),
          ''); // Eliminar todos los caracteres no numéricos excepto '+'

      // Si el número no tiene código de país, agregar '+' por defecto
      if (!phone.startsWith('+')) {
        phone = '+$phone';
      }

      // Mensaje predeterminado
      String message =
          "Hola, vi tu perfil en la app de abogados y me gustaría consultar sobre tus servicios.";

      // Crear la URL para abrir WhatsApp - usar URL estándar para mayor compatibilidad
      final Uri whatsappUri = Uri.parse(
          'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}');

      print('Intentando abrir WhatsApp con URI: $whatsappUri');

      // Verificar si se puede abrir la URL y mostrar logs
      if (await canLaunchUrl(whatsappUri)) {
        print('Abriendo WhatsApp...');
        // Usar launchUrl con modo externo
        final result = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );

        print('Resultado de lanzamiento: $result');

        if (!result) {
          // Si falla, mostrar un mensaje
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'No se pudo abrir WhatsApp. Inténtalo manualmente con el número: $phone')),
          );
        }
      } else {
        // Si WhatsApp no está instalado
        print('No se puede lanzar WhatsApp URL');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'WhatsApp no está instalado o no se puede abrir. El número es: $phone')),
        );
      }
    } catch (e) {
      print('Error al abrir WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir WhatsApp: $e')),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor escribe un comentario')),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user != null) {
        await _lawyerService.addReview(
          lawyerId: widget.lawyerId,
          clientId: user.uid,
          clientName: user.displayName ?? 'Cliente',
          text: _reviewController.text.trim(),
          rating: _userRating,
        );

        // Limpiar el formulario después de enviar
        _reviewController.clear();
        setState(() {
          _userRating = 3.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comentario enviado con éxito')),
        );

        // Recargar datos del abogado para actualizar calificación
        _loadLawyerData();
      }
    } catch (e) {
      print('Error al enviar comentario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar comentario')),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lawyer?.name ?? 'Detalles del Abogado'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _lawyer == null
              ? Center(
                  child: Text('No se encontró información del abogado'),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del abogado
                      _buildLawyerHeader(),
                      Divider(height: 32.0),

                      // Descripción
                      Text(
                        'Acerca de',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        _lawyer!.description.isNotEmpty
                            ? _lawyer!.description
                            : 'El abogado no ha proporcionado una descripción.',
                        style: TextStyle(
                          fontSize: 16.0,
                          height: 1.5,
                        ),
                      ),
                      Divider(height: 32.0),

                      // Comentarios
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comentarios',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '(${_lawyer!.reviewCount})',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),

                      // Formulario para agregar comentario
                      FutureBuilder<UserType>(
                        future: _userTypeFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final userType = snapshot.data ?? UserType.client;

                          // Solo mostrar el formulario si es un cliente
                          if (userType == UserType.client) {
                            return _buildReviewForm();
                          }

                          return SizedBox();
                        },
                      ),

                      // Lista de comentarios
                      _buildReviewsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReviewForm() {
    return Card(
      margin: EdgeInsets.only(bottom: 24.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deja tu opinión',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.0),

            // Calificación con estrellas
            Row(
              children: [
                Text('Calificación: '),
                SizedBox(width: 8.0),
                RatingBar.builder(
                  initialRating: _userRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 24.0,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 12.0),

            // Campo de texto para el comentario
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu comentario aquí...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // Botón para enviar comentario
            ElevatedButton(
              onPressed: _isSubmittingReview ? null : _submitReview,
              child: _isSubmittingReview
                  ? SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    )
                  : Text('Enviar comentario'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<Review>>(
      stream: _lawyerService.getLawyerReviews(widget.lawyerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar comentarios: ${snapshot.error}'),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No hay comentarios aún. ¡Sé el primero en opinar!',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8.0),
                        Text(
                          review.clientName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 16.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Text(review.text),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLawyerHeader() {
    return Column(
      children: [
        // Foto y datos básicos
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto del abogado
            Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: _lawyer!.photoBase64.isNotEmpty
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(_lawyer!.photoBase64)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _lawyer!.photoBase64.isEmpty
                  ? Icon(Icons.person, size: 48.0, color: Colors.grey[600])
                  : null,
            ),
            SizedBox(width: 16.0),

            // Información del abogado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lawyer!.name,
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    _lawyer!.specialty,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: _lawyer!.rating,
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        _lawyer!.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.0),

        // Precio de consulta
        Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.0),
              Text(
                'Precio de consulta: \$${_lawyer!.consultationPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),

        // Botón de contacto modificado para WhatsApp
        ElevatedButton.icon(
          onPressed: _contactViaWhatsApp,
          icon: Icon(Icons.message, color: Colors.white),
          label: Text('Contactar por WhatsApp'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            minimumSize: Size(double.infinity, 48.0),
            backgroundColor: Color(0xFF25D366), // Color verde de WhatsApp
          ),
        ),
      ],
    );
  }
}
