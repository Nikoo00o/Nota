import 'package:shared/domain/entities/entity.dart';

/// The base shared account class used in both server and client
class Account extends Entity {
  final String userName;
  final String passwordHash;

  Account({required this.userName, required this.passwordHash})
      : super(<String, dynamic>{"userName": userName, "passwordHash": passwordHash});
}
