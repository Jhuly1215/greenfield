//MARKY CLOUD

class AppwriteConstants {
  static const String databaseId = '65a819dce5b47722b046';
  static const String projectId = '65a81945348d8783b000';
  static const String endPoint = 'https://cloud.appwrite.io/v1';

  static const String usersCollection = '65a819e408f14fc5045e';
  static const String tweetsCollection = '65a819f3d31132bc9620';
  static const String notificationsCollection = '65a819ecef038378e857';

  static const String imagesBucket = '65a819fb45eba441bd81';

  static String imageUrl(String imageId) =>
      '$endPoint/storage/buckets/$imagesBucket/files/$imageId/view?project=$projectId&mode=admin';
}



//LOCALHOST PARA PRUEBAS

/*class AppwriteConstants {
  static const String databaseId = '659a0e73d281ca3e305f';
  static const String projectId = '659a0921ea1d9047595d';
  static const String endPoint = 'http://192.168.1.5:80/v1';

  static const String usersCollection = '659ae0fdb8eba39579f7';
  static const String tweetsCollection = '659c6f6604176581a4d7';
  static const String notificationsCollection = '659c73b121f496ce7f1c';

  static const String imagesBucket = '659aee14f2c4d6d4c1ce';

  static String imageUrl(String imageId) =>
      '$endPoint/storage/buckets/$imagesBucket/files/$imageId/view?project=$projectId&mode=admin';
}*/