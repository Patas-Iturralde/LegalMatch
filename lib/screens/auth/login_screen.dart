import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Navegar a la pantalla principal si la autenticación es exitosa
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'No se encontró usuario con ese email.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Contraseña incorrecta.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'El formato del email es inválido.';
          } else if (e.code == 'user-disabled') {
            _errorMessage = 'Esta cuenta ha sido deshabilitada.';
          } else if (e.code == 'too-many-requests') {
            _errorMessage = 'Demasiados intentos fallidos. Intenta más tarde.';
          } else {
            _errorMessage = 'Error al iniciar sesión: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al iniciar sesión: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🆕 Función para mostrar el diálogo de recuperación de contraseña
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();
    bool isResetting = false;
    String resetMessage = '';
    bool isSuccess = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: Color.fromARGB(255, 15, 77, 62)),
                  SizedBox(width: 8),
                  Text('Recuperar Contraseña'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSuccess) ...[
                      Text(
                        'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                    
                    if (resetMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSuccess 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSuccess 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSuccess ? Icons.check_circle : Icons.error,
                                color: isSuccess ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  resetMessage,
                                  style: TextStyle(
                                    color: isSuccess ? Colors.green[700] : Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'),
                ),
                if (!isSuccess)
                  ElevatedButton(
                    onPressed: isResetting ? null : () async {
                      if (resetEmailController.text.trim().isEmpty) {
                        setDialogState(() {
                          resetMessage = 'Por favor ingresa tu email';
                          isSuccess = false;
                        });
                        return;
                      }

                      // Validar formato de email
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(resetEmailController.text.trim())) {
                        setDialogState(() {
                          resetMessage = 'Ingresa un email válido';
                          isSuccess = false;
                        });
                        return;
                      }

                      setDialogState(() {
                        isResetting = true;
                        resetMessage = '';
                      });

                      try {
                        // Enviar email de recuperación directamente
                        // Firebase Auth se encargará de validar si el email existe
                        await _authService.sendPasswordResetEmail(
                          resetEmailController.text.trim(),
                        );

                        setDialogState(() {
                          resetMessage = 
                              '✅ Email de recuperación enviado correctamente.\n\n'
                              'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.\n\n'
                              'Si no encuentras el email, revisa tu carpeta de spam.\n\n'
                              '⚠️ Si no tienes una cuenta con este email, no recibirás ningún mensaje.';
                          isSuccess = true;
                          isResetting = false;
                        });

                      } catch (e) {
                        String errorMessage = e.toString().replaceAll('Exception: ', '');
                        
                        // Manejar específicamente el error de usuario no encontrado
                        if (errorMessage.contains('user-not-found') || 
                            errorMessage.contains('No existe una cuenta')) {
                          errorMessage = 'No existe una cuenta registrada con este email.\n\n'
                              'Verifica que el email sea correcto o regístrate primero.';
                        }
                        
                        setDialogState(() {
                          resetMessage = errorMessage;
                          isSuccess = false;
                          isResetting = false;
                        });
                      }
                    },
                    child: isResetting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Enviar Email'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 15, 77, 62),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 255, 255, 255),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o título
                  Container(
                    margin: EdgeInsets.only(bottom: 48.0),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(0, 255, 255, 255),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 50,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo_sf.png'),
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 8),
                        Text(
                          'Tu abogado de confianza a un clic',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text("Encuentra tu abogado\nAmachaq Tariyki", 
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
                      }
                      // Validación simple de formato de email
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Ingresa un email válido';
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
                  SizedBox(height: 12.0),
                  
                  // 🆕 Enlace "¿Olvidaste tu contraseña?"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  
                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Iniciando sesión...'),
                            ],
                          )
                        : Text('Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 15, 77, 62),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'o',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 24.0),
                  
                  // Enlace para registrarse
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text('¿No tienes cuenta? Regístrate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color.fromARGB(255, 255, 255, 255),
                      side: BorderSide(color: Color.fromARGB(0, 15, 77, 62)),
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}