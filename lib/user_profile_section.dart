import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class UserProfileSection extends StatelessWidget {
  final User user; // Ahora User está correctamente definido
  final String userName;
  final String email;
  final String cedula;
  final String phoneNumber;  // Asegúrate de tener este parámetro
  final TextEditingController nameController;
  final TextEditingController phoneController;  // Y este también
  final VoidCallback onUpdate;
  final ValueChanged<String> onPhoneUpdate;  // Y este callback
  final VoidCallback onResetPassword;
  final VoidCallback onLogout;

    const UserProfileSection({
    super.key,
    required this.user,
    required this.userName,
    required this.email,
    required this.cedula,
    required this.phoneNumber,
    required this.nameController,
    required this.phoneController,
    required this.onUpdate,
    required this.onPhoneUpdate,
    required this.onResetPassword,
    required this.onLogout,
  });

   @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Reemplazamos el CircleAvatar con Lottie
          SizedBox(height: 20),
          _buildInfoRow('Nombre', userName),
          _buildInfoRow('Correo', email),
          _buildInfoRow('Cédula', cedula),
          SizedBox(height: 30),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 20),
          _buildActionButton(
            text: 'Actualizar Nombre',
            icon: Icons.update,
            onPressed: onUpdate,
          ),
          SizedBox(height: 15),
          _buildActionButton(
            text: 'Restablecer Contraseña',
            icon: Icons.lock_reset,
            onPressed: onResetPassword,
          ),
          SizedBox(height: 15),
          _buildActionButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout,
            onPressed: onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : Colors.black, // Cambiado de primary a backgroundColor
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}