import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _fullnameController;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _profileImage;

  
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    _nameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _fullnameController = TextEditingController(text: user?.fullName ?? '');
    _profileImage = user?.photoURL != null ? File(user!.photoURL!) : null;

    _profileImage = null; 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _fullnameController.dispose();
    super.dispose();
  }

  ImageProvider? _getProfileImage() {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  if (_isEditing && _profileImage != null) {
    return FileImage(_profileImage!);
  }
  
  if (authProvider.profileImageUrl != null && authProvider.profileImageUrl!.isNotEmpty) {
    return NetworkImage(authProvider.profileImageUrl!);
  }
  
  if (authProvider.userModel?.photoURL != null) {
    return NetworkImage(authProvider.userModel!.photoURL!);
  }
  
  return null;
  
  
}

  Widget? _showProfileIcon() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if ((_isEditing && _profileImage == null) || 
        (!_isEditing && (authProvider.profileImageUrl == null || authProvider.profileImageUrl!.isEmpty))) {
      return const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      );
    }
    return null;
  }

  void _clearImageCache() {
  if (_profileImage != null) {
    final imageProvider = FileImage(_profileImage!);
    imageProvider.evict().then<void>((bool success) {
      if (success && mounted) {
        setState(() {});
      }
    });
  }
}

Future<void> _updateProfile() async {
  if (_formKey.currentState!.validate()) {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final hasChanges = _fullnameController.text.trim() != user?.fullName || 
                        _profileImage != null;

      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay cambios para guardar')),
        );
        return;
      }

      final success = await Provider.of<AuthProvider>(context, listen: false)
        .updateProfile(
          fullName: _fullnameController.text.trim(),
          profileImage: _profileImage,
        );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        setState(() {
          _isEditing = false;
          _isLoading = false;
          _profileImage = null; 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
  try {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (!mounted) return;

    if (pickedFile != null ) {

      final imageFile = File(pickedFile.path);
      final fileExists = await imageFile.exists();
      if (!mounted) {
        return; 
      }
      
      if (fileExists) {
        setState(() {
          _profileImage = imageFile;
        });
        _clearImageCache(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a la imagen')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

 

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final isGuest = !authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (!isGuest && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: isGuest
          ? _buildGuestView(context)
          : _buildUserProfile(context, user),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Estas navegando como invitado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia sesión para acceder a tu perfil y reservas',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('INICIAR SESIÓN'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('CREAR UNA CUENTA'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, dynamic user) {
    // final authProvider = Provider.of<AuthProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_isEditing) {
                      _showImagePicker(context);
                    }
                  },
                  child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: _getProfileImage(), 
                  child: _showProfileIcon(),
                ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing)
                  Text(
                    user?.fullName ?? user?.username ?? 'Usuario',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing)
                  CustomTextField(
                    controller: _fullnameController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person_outline,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  )
                else
                  _buildProfileItem('Nombre completo', user?.fullName ?? user?.username ?? 'No establecido'),
                const SizedBox(height: 16),

                _buildProfileItem('Correo electrónico', user?.email ?? 'No establecido', isEditable: false),

                const SizedBox(height: 16),

                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = user?.username ?? '';
                              _emailController.text = user?.email ?? '';
                              _fullnameController.text = user?.fullName ?? '';
                              _profileImage = user?.photoURL != null ? File(user!.photoURL!) : null;
                               
                            });
                          },
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text('GUARDAR'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            'Mis Reservas',
            Icons.confirmation_number_outlined,
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente, la función de reservas estará disponible')),
              );
            },
          ),
          _buildActionItem(
            'Métodos de pago guardados',
            Icons.credit_card_outlined,
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente se añadirá la función de métodos de pago')),
              );
            },
          ),
          _buildActionItem(
            'Cambiar la contraseña',
            Icons.lock_outline,
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente se añadirá la función de cambio de contraseña')),
              );
            },
          ),
          _buildActionItem(
            'Desconectar',
            Icons.logout,
            _signOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, {bool isEditable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isEditable && !_isEditing)
              Icon(
                Icons.edit,
                size: 16,
                color: Colors.grey.shade600,
              ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey.shade700,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}