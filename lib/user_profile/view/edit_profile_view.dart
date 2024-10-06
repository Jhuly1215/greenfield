import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/core/utils.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/user_profile/controller/user_profile_controller.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const EditProfileView(),
      );
  const EditProfileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController nameController;
  late TextEditingController phoneNumberController;
  late TextEditingController birthDateController;
  File? profileFile;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserDetailsProvider).value;
    nameController = TextEditingController(text: user?.name ?? '');
    phoneNumberController = TextEditingController(text: user?.phoneNumber ?? '');
    birthDateController = TextEditingController(text: user?.birthDate ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneNumberController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  void selectProfileImage() async {
    final profileImage = await pickImage();
    if (profileImage != null) {
      setState(() {
        profileFile = profileImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailsProvider).value;
    final isLoading = ref.watch(userProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(userProfileControllerProvider.notifier)
                  .updateUserProfile(
                    userModel: user!.copyWith(
                      name: nameController.text,
                      phoneNumber: phoneNumberController.text,
                      birthDate: birthDateController.text,
                    ),
                    context: context,
                    profileFile: profileFile,
                  );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: isLoading || user == null
          ? const Loader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: selectProfileImage,
                    child: profileFile != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(profileFile!),
                            radius: 40,
                          )
                        : CircleAvatar(
                            backgroundImage: NetworkImage(user.profilePic),
                            radius: 40,
                          ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      contentPadding: EdgeInsets.all(18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      contentPadding: EdgeInsets.all(18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Nacimiento',
                      hintText: 'YYYY-MM-DD',
                      contentPadding: EdgeInsets.all(18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                ],
              ),
            ),
    );
  }
}
