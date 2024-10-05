import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class UserModel {
  final String email;
  final String name;
  final String phoneNumber;
  final String birthDate;
  final String password;
  final String uid;
  final String profilePic;

  const UserModel({
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.birthDate,
    required this.password,
    required this.uid,
    required this.profilePic,
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? phoneNumber,
    String? birthDate,
    String? password,
    String? uid,
    String? profilePic,
  
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      password: password ?? this.password,
      uid: uid ?? this.uid,
      profilePic: profilePic ?? this.profilePic,

    );
  }

  static UserModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return UserModel(
      email: snapshot["email"],
      name: snapshot["name"],
      phoneNumber: snapshot["phoneNumber"],
      birthDate: snapshot["birthDate"],
      password: snapshot["password"],
      uid: snapshot["uid"],
      profilePic: snapshot["profilePic"],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String documentId}) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      birthDate: map['birthDate'] ?? '',
      password: map['password'] ?? '',
      uid: documentId,
      profilePic: map['profilePic'] ?? '',
    
    );
  }

  Map<String, dynamic> toJson() => {
        "email": email,
        "name": name,
        "phoneNumber": phoneNumber,
        "birthDate": birthDate,
        "password": password,
        "uid": uid,
        "profilePic": profilePic,
      
      };
}
