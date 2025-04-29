import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, lawyer }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado del usuario actual
  Stream<User?> get user => _auth.authStateChanges();

  // Obtener el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // Registrar nuevo usuario
  Future<UserCredential> registerWithEmailAndPassword({
    required String email, 
    required String password, 
    required String name, 
    required UserType userType
  }) async {
    try {
      // Crear usuario con email y contraseña
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Guardar información adicional en Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'userType': userType == UserType.lawyer ? 'lawyer' : 'client',
        'createdAt': Timestamp.now(),
      });
      
      // Si es abogado, crear un documento en la colección de abogados
      if (userType == UserType.lawyer) {
        await _firestore.collection('lawyers').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'specialty': '',
          'photoBase64': '',
          'consultationPrice': 0.0,
          'description': '',
          'rating': 0.0,
          'reviewCount': 0,
        });
      }
      
      return result;
    } catch (e) {
      print('Error al registrar: $e');
      rethrow;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (e) {
      print('Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // Obtener el tipo de usuario (cliente o abogado)
  Future<UserType> getUserType(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['userType'] == 'lawyer' ? UserType.lawyer : UserType.client;
      }
      return UserType.client; // Valor predeterminado
    } catch (e) {
      print('Error al obtener tipo de usuario: $e');
      return UserType.client; // Valor predeterminado en caso de error
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}