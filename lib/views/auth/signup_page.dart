import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../app_images.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Uint8List? _imageBytes;
  String? _uploadedImageUrl;

  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$',
  );

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      input.onChange.listen((event) async {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        setState(() {
          _imageBytes = reader.result as Uint8List;
        });
      });
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    }
  }

  Future<void> _uploadImageToImgBB() async {
    if (_imageBytes == null) return;

    final String apiKey = 'c9eb9d416995a95e2687b3d7c72016f5';
    final String base64Image = base64Encode(_imageBytes!);

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      _uploadedImageUrl = json['data']['url'];
    } else {
      throw Exception("Échec de l'upload de l'image.");
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _uploadImageToImgBB();

      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': _uploadedImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inscription réussie !'),
          backgroundColor: AppColors.primary,
        ),
      );

      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Une erreur est survenue. Veuillez réessayer.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  _imageBytes != null
                                      ? MemoryImage(_imageBytes!)
                                      : null,
                              child:
                                  _imageBytes == null
                                      ? Icon(
                                        Icons.camera_alt,
                                        size: 30,
                                        color: Colors.grey[700],
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ajouter une photo",
                            style: TextStyle(color: Colors.grey[700]),
                          ),

                          const SizedBox(height: 25),
                          _buildField(
                            "Nom",
                            _nomController,
                            Icons.person,
                            false,
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            "Prénom",
                            _prenomController,
                            Icons.person_outline,
                            false,
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            "Téléphone",
                            _phoneController,
                            Icons.phone,
                            false,
                            keyboard: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.length < 8
                                        ? "Numéro invalide"
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            "Email",
                            _emailController,
                            Icons.email,
                            false,
                            keyboard: TextInputType.emailAddress,
                            validator:
                                (value) =>
                                    !_emailRegex.hasMatch(value!)
                                        ? "Email invalide"
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            "Mot de passe",
                            _passwordController,
                            Icons.lock,
                            obscure: _obscurePassword,
                            toggle:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                            validator:
                                (value) =>
                                    !_passwordRegex.hasMatch(value!)
                                        ? "Min. 6 caractères, maj., min., chiffre, spécial"
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            "Confirmer le mot de passe",
                            _confirmPasswordController,
                            Icons.lock_outline,
                            obscure: _obscureConfirmPassword,
                            toggle:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                            validator:
                                (value) =>
                                    value != _passwordController.text
                                        ? "Les mots de passe ne correspondent pas"
                                        : null,
                          ),
                          const SizedBox(height: 15),
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        "S'inscrire",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: "Déjà un compte ? ",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Connectez-vous",
                                    style: TextStyle(color: AppColors.darkRed),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  AppImages.petSignup,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool obscure, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator ?? (value) => value!.isEmpty ? "Champ requis" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }
}
