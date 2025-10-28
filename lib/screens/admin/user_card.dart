import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore por API MongoDB


class UserCard extends StatelessWidget {
  final user;
  final VoidCallback onEdit;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['estado'] == 'activo';

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(child: Text(user['nombre'][0])),
        title: Text('${user['nombre']} ${user['apellido']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DNI: ${user['dni']}'),
            Text('Email: ${user['email']}'),
            Text('Rol: ${user['rango']}'),
            if (user['rango'] == 'guardia')
              Text('Puerta a Cargo: ${user['puerta_acargo']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleStatus(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
  try {
    final newStatus = user['estado'] == 'activo' ? 'inactivo' : 'activo';
    
    // 1. Actualizar Firestore
    // await user.reference.update({
    //   'estado': newStatus,
    //   'fecha_actualizacion': FieldValue.serverTimestamp(),
    // });
    // TODO: Reemplazar por llamada a API REST de MongoDB

    // 2. Opcional: Actualizar Auth (requiere backend)
    if (newStatus == 'inactivo') {
      // Esto debería hacerse desde una Cloud Function
      debugPrint('Nota: Para deshabilitar en Auth, implementa una Cloud Function');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $newStatus')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
}