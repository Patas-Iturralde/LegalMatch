import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/ecuador_cities.dart';
import '../../widgets/terms_conditions_widget.dart'; // Agregar nueva importación
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  UserType _selectedUserType = UserType.client;
  bool _acceptTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Campos específicos para abogados
  String _selectedCity = 'Quito'; // Ciudad por defecto
  List<String> _allCities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Cargar las ciudades del Ecuador
  void _loadCities() {
    _allCities = EcuadorCities.getAllCities();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        setState(() {
          _errorMessage = 'Debes aceptar los términos y condiciones para continuar.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          userType: _selectedUserType,
          
        );
        
        // Navegar a la pantalla principal si el registro es exitoso
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'weak-password') {
            _errorMessage = 'La contraseña es demasiado débil.';
          } else if (e.code == 'email-already-in-use') {
            _errorMessage = 'Ya existe una cuenta con este email.';
          } else {
            _errorMessage = 'Error al registrarse: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al registrarse: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para mostrar los términos y condiciones completos
  void _showTermsAndConditions() async {
    bool? accepted = await TermsAndConditionsWidget.showTermsDialog(context);
    if (accepted == true) {
      setState(() {
        _acceptTerms = true;
      });
    }
  }

  // Texto completo de términos y condiciones
  String _getTermsAndConditionsText() {
    return '''TÉRMINOS Y CONDICIONES DE USO DE LA APLICACIÓN IURISMATCH
Última actualización: 17 de junio de 2025

Estos Términos y Condiciones regulan el acceso y uso de la aplicación móvil y/o web denominada IurisMatch (en adelante, la "Aplicación"), administrada por el equipo IurisMatch, (en adelante, "Administradora").

El uso de la Aplicación implica la aceptación plena y sin reservas de los presentes Términos y Condiciones. Si no está de acuerdo con estos términos, debe abstenerse de utilizar la plataforma.

1. OBJETO DE LA APLICACIÓN
IurisMatch es una plataforma digital cuyo objetivo es facilitar el contacto entre:

• Estudiantes de Derecho y pasantes en búsqueda de experiencia profesional.
• Abogados, estudios jurídicos y organizaciones que ofrecen pasantías o vacantes legales.
• Usuarios interesados en acceder a cursos de formación jurídica, foros de debate y otros recursos del ámbito legal.

La plataforma actúa como intermediaria tecnológica, sin participar directamente en las relaciones contractuales, laborales, académicas ni profesionales entre los usuarios.

2. REGISTRO Y ACCESO
Para utilizar los servicios de la Aplicación, el usuario debe registrarse y proporcionar información veraz, completa y actualizada. El usuario es responsable de la confidencialidad de sus credenciales de acceso y del uso de su cuenta.

IurisMatch se reserva el derecho de suspender o eliminar cuentas que incumplan los presentes Términos, proporcionen información falsa o utilicen la plataforma con fines indebidos.

3. SERVICIOS DISPONIBLES
La Aplicación pone a disposición de los usuarios las siguientes funcionalidades:

• Publicación y consulta de oportunidades de pasantías o empleos jurídicos.
• Inscripción y acceso a cursos jurídicos y capacitaciones especializadas.
• Participación en foros de discusión y espacios colaborativos de carácter jurídico.
• Visualización y contacto con perfiles profesionales y académicos.

IurisMatch no garantiza el éxito de ninguna postulación ni la contratación efectiva entre las partes.

4. TARIFAS Y PAGOS
Algunos servicios y contenidos ofrecidos por la Aplicación (como cursos o eventos) pueden estar sujetos al pago de tarifas, las cuales serán informadas previamente de manera clara.

Las tarifas pagadas no son reembolsables, salvo que expresamente se indique lo contrario en casos específicos de cancelación del servicio por parte de la Administradora.

5. RESPONSABILIDADES DEL USUARIO
El usuario se compromete a:

• Usar la plataforma conforme a la ley ecuatoriana y a los principios de buena fe.
• No compartir información falsa, ofensiva, discriminatoria o que infrinja derechos de terceros.
• No utilizar la Aplicación para fines ilegales, comerciales no autorizados o de suplantación de identidad.

6. LIMITACIÓN DE RESPONSABILIDAD
IurisMatch y su representante no se hacen responsables por:

• La veracidad, legalidad o exactitud de la información publicada por usuarios.
• La calidad, duración o condiciones de pasantías, empleos o cursos ofrecidos.
• Daños o perjuicios derivados del uso indebido o inadecuado de la Aplicación.
• Incumplimientos entre usuarios, proveedores o terceros contactados a través de la plataforma.

IurisMatch es una aplicación intermediaria entre usuarios, por lo que las interacciones dependen exclusivamente de estos. La administración procurará restringir y eliminar contenido inadecuado o inapropiado tras ser detectado.

7. AUTORÍA DEL CONTENIDO Y AUSENCIA DE ASESORÍA LEGAL
Los contenidos, opiniones, comentarios, documentos, materiales, artículos, consejos, orientaciones y cualquier información publicada, compartida o divulgada por los usuarios registrados en la Aplicación, sean estos abogados, estudiantes de derecho, pasantes, profesionales del derecho o cualquier otro tipo de usuario, son de exclusiva autoría y responsabilidad de quien los publica.

IurisMatch declara expresamente que:

a) No constituye asesoría legal: Ningún contenido generado por usuarios de la plataforma constituye asesoría legal formal, consulta jurídica profesional ni opinión legal vinculante. Los usuarios que requieran asesoría legal específica deberán consultar directamente con un abogado debidamente habilitado para ejercer la profesión.

b) No representa a la Aplicación: Las opiniones, criterios, interpretaciones legales, comentarios o cualquier manifestación expresada por los usuarios no representan la posición oficial de IurisMatch, ni comprometen la responsabilidad de la Administradora, ni constituyen declaraciones institucionales de la plataforma.

c) Exención de responsabilidad profesional: IurisMatch no asume responsabilidad alguna por las consecuencias, daños, perjuicios o efectos adversos que puedan derivarse del uso, aplicación o interpretación de los contenidos publicados por usuarios en la plataforma.

d) Carácter informativo: Todo contenido disponible en la Aplicación tiene únicamente carácter informativo, educativo y de intercambio académico o profesional, sin constituir en modo alguno asesoramiento legal profesional.

Los usuarios que publiquen contenido legal se comprometen a incluir las advertencias pertinentes sobre el carácter no vinculante de sus publicaciones y la necesidad de consulta profesional especializada para casos específicos. Todo contacto profesional es externo y responsabilidad exclusiva de las partes.

8. PROPIEDAD INTELECTUAL
Todos los contenidos, diseños, logotipos, códigos y elementos visuales de la Aplicación son propiedad de IurisMatch y están protegidos por las leyes de propiedad intelectual de Ecuador. Está prohibida su reproducción, modificación o uso no autorizado.

9. PROTECCIÓN DE DATOS PERSONALES
IurisMatch recolecta y trata datos personales conforme a lo establecido en la Ley Orgánica de Protección de Datos Personales del Ecuador.

Finalidades del tratamiento:
• Gestión de usuarios registrados.
• Envío de información relevante (notificaciones, actualizaciones, cursos, oportunidades).
• Estadísticas y mejoras del servicio.

Derechos del titular de los datos:
El usuario podrá ejercer sus derechos de acceso, rectificación, eliminación, oposición y portabilidad mediante solicitud escrita al correo electrónico indicado abajo.

Los datos no serán compartidos con terceros sin consentimiento expreso, salvo obligación legal.

10. MODIFICACIONES
IurisMatch se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios se notificarán a través de la misma Aplicación o por correo electrónico. El uso continuado implica aceptación de las modificaciones.

11. SOLUCIÓN DE CONTROVERSIAS
En caso de controversias relacionadas con el uso de la Aplicación, las partes acuerdan:

• Buscar una solución amistosa mediante mediación administrada por un centro debidamente acreditado.
• Si la mediación no resulta exitosa en un plazo de 30 días, la controversia se resolverá mediante arbitraje en derecho, conforme a la Ley de Arbitraje y Mediación del Ecuador.

El tribunal arbitral estará compuesto por tres árbitros: uno designado por la parte demandante, otro por la parte demandada, y el tercero elegido por sorteo entre árbitros inscritos en el centro de arbitraje seleccionado.

El laudo arbitral será definitivo, obligatorio e inapelable.

12. LEY APLICABLE Y JURISDICCIÓN
Estos Términos se rigen por las leyes de la República del Ecuador. En todo lo no previsto, se aplicarán las disposiciones del Código Civil, Código de Comercio, Ley de Protección de Datos Personales, Ley de Arbitraje y Mediación, y demás normas aplicables.

13. CONTACTO
Para consultas, sugerencias o ejercicio de derechos en materia de protección de datos, puede contactarse a:

IurisMatch
📧 iurismatch@gmail.com''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o título
                  Text(
                    'IurisMatch',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Crea tu cuenta',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.0),
                  
                  // Campo de Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  
                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Por favor ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  
                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  
                  // Campo de Confirmar Contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  
                  // Selector de tipo de usuario
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Tipo de usuario',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        RadioListTile<UserType>(
                          title: Text('Cliente'),
                          subtitle: Text('Busco servicios legales'),
                          value: UserType.client,
                          groupValue: _selectedUserType,
                          onChanged: (UserType? value) {
                            setState(() {
                              _selectedUserType = value!;
                            });
                          },
                        ),
                        RadioListTile<UserType>(
                          title: Text('Abogado'),
                          subtitle: Text('Ofrezco servicios legales'),
                          value: UserType.lawyer,
                          groupValue: _selectedUserType,
                          onChanged: (UserType? value) {
                            setState(() {
                              _selectedUserType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Campo de ciudad solo para abogados
                  if (_selectedUserType == UserType.lawyer) ...[
                    SizedBox(height: 16.0),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_city, color: Theme.of(context).primaryColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Ciudad donde ejerce',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona la ciudad principal donde ofreces tus servicios legales.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              labelText: 'Seleccionar ciudad',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _allCities.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(
                                  city,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCity = newValue ?? 'Quito';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una ciudad';
                              }
                              return null;
                            },
                            isExpanded: true,
                            // Mostrar provincia entre paréntesis
                            selectedItemBuilder: (BuildContext context) {
                              return _allCities.map<Widget>((String city) {
                                String? province = EcuadorCities.getProvinceOfCity(city);
                                return Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    province != null ? '$city ($province)' : city,
                                    style: TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 24.0),
                  
                  // Sección de Términos y Condiciones
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Términos y Condiciones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Al crear una cuenta en IurisMatch, aceptas nuestros términos de uso y política de privacidad. Lee los términos completos para conocer tus derechos y obligaciones.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showTermsAndConditions,
                          child: Text(
                            'Ver términos y condiciones completos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (bool? value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _acceptTerms = !_acceptTerms;
                                  });
                                },
                                child: Text(
                                  'Acepto los términos y condiciones de uso de IurisMatch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage.isNotEmpty) SizedBox(height: 16.0),
                  
                  // Botón de Registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _acceptTerms ? Theme.of(context).primaryColor : Colors.grey[400],
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // Enlace para iniciar sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}