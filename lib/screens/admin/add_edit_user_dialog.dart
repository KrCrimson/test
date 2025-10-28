import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class AddEditUserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String userRole;

  const AddEditUserDialog({Key? key, this.user, required this.userRole})
      : super(key: key);

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedPuerta;
  String _status = 'activo'; // Default status
  bool _isEditing = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _isEditing = true;
      _nombreController.text = widget.user!['nombre'] ?? '';
      _apellidoController.text = widget.user!['apellido'] ?? '';
      _dniController.text = widget.user!['dni'] ?? '';
      _emailController.text = widget.user!['email'] ?? '';
      _selectedPuerta = widget.user!['puerta_acargo'];
      _status = widget.user!['estado'] ?? 'activo';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final nombre = _nombreController.text.trim();
      final apellido = _apellidoController.text.trim();
      final dni = _dniController.text.trim();
      final email = _emailController.text.trim();
      final password = _isEditing ? null : _passwordController.text.trim();

      final userData = {
        'nombre': nombre,
        'apellido': apellido,
        'dni': dni,
        'email': email,
        'rango': widget.userRole,
        'puerta_acargo': _selectedPuerta,
        'estado': _isEditing ? widget.user!['estado'] : _status,
        'fecha_modificacion': DateTime.now().toIso8601String(),
      };

      if (!_isEditing) {
        userData['fecha_creacion'] = DateTime.now().toIso8601String();
        userData['password'] = password;
      }

      try {
        if (_isEditing) {
          // Actualizar usuario existente
          final id = widget.user!['_id'];
          final response = await http.put(
            Uri.parse('${Config.apiBaseUrl}/usuarios/$id'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          );
          if (response.statusCode == 200) {
            Navigator.of(context).pop();
          } else {
            throw Exception('Error al actualizar usuario');
          }
        } else {
          // Crear usuario nuevo
          final response = await http.post(
            Uri.parse('${Config.apiBaseUrl}/usuarios'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          );
          if (response.statusCode == 200) {
            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Usuario creado'),
                  content: SelectableText('La contraseña del usuario es: $password'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              Navigator.of(context).pop();
            }
          } else {
            throw Exception('Error al crear usuario');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: Text(
        _isEditing ? 'Editar ${widget.userRole}' : 'Agregar ${widget.userRole}',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.indigo,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un apellido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un DNI' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un Email' : null,
              ),
              const SizedBox(height: 8),
              if (!_isEditing)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese una contraseña' : null,
                ),
              if (!_isEditing) const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 8),
              if (widget.userRole == 'guardia')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Puerta a Cargo',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedPuerta,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Sin asignar')),
                    DropdownMenuItem(value: 'faing', child: Text('FAING')),
                    DropdownMenuItem(value: 'facsa', child: Text('FACSA')),
                    DropdownMenuItem(value: 'facem', child: Text('FACEM')),
                    DropdownMenuItem(value: 'faedcoh', child: Text('FAEDCOH')),
                    DropdownMenuItem(value: 'fade', child: Text('FADE')),
                    DropdownMenuItem(value: 'fau', child: Text('FAU')),
                  ],
                  onChanged: (value) => setState(() => _selectedPuerta = value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

void showAddEditUserDialog(BuildContext context,
    {Map<String, dynamic>? user, required String userRole}) {
  showDialog(
    context: context,
    builder: (context) =>
        AddEditUserDialog(user: user, userRole: userRole),
  );
}

// TODO: Reemplazar Firestore y FirebaseAuth por API MongoDB
// Ejemplo de función que usaba Firestore:
// await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(data);
// TODO: Reemplazar por llamada a API REST de MongoDB