import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Data class representing user information.
@freezed
abstract class UserData with _$UserData {
  const UserData._();

  const factory UserData({
    /// Unique user ID
    required String id,

    /// User's name
    required String name,

    /// User's phone number
    String? phone,

    /// User's email
    String? email,

    /// URL to user's profile image (optional)
    String? imageUrl,

    // Timestamps
    /// User's account creation timestamp
    required int createdAt,

    /// Timestamp for user profile updates
    required int updatedAt,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
