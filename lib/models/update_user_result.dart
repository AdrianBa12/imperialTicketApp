import '../models/strapi_user_model.dart';

class UpdateUserResult {
  final bool success;
  final StrapiUserModel? updatedUser;
  final String? errorMessage;

  UpdateUserResult({
    required this.success,
    this.updatedUser,
    this.errorMessage,
  });
}