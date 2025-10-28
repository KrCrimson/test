import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore y FirebaseAuth por API MongoDB

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  // Ejemplo de función que usaba Firestore:
  // final currentUser = FirebaseAuth.instance.currentUser;
  // TODO: Reemplazar por llamada a API REST de MongoDB

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: Center(
        child: Text('Pantalla de notificaciones'), // Placeholder
      ),
    );
  }
}
