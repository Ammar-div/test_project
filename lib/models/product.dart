import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Product {
  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.categoryId,
    required this.imageUrls,
    required this.publishDate,
  }) : id = uuid.v4();

  final String id;
  final String name;
  final double price;
  final String description;
  final String categoryId;
  final List<String> imageUrls;
  final DateTime publishDate;

//   // Convert Product to a Map for Firestore
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'price': price,
//       'description': description,
//       'categoryId': categoryId,
//       'imageUrls': imageUrls,
//       'publishDate': publishDate.toIso8601String(),
//     };
//   }
// }

// Future<void> seedProducts() async {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // List of 4 products
//   final List<Product> products = [
//     Product(
//       name: 'High-Performance Gaming PC',
//       price: 1200.0,
//       description: 'A powerful gaming PC with RGB lighting.',
//       categoryId: 'gaming',
//       imageUrls: [
//         'https://picsum.photos/300/200?random=1',
//         'https://picsum.photos/300/200?random=2',
//         'https://picsum.photos/300/200?random=3',
//       ],
//       publishDate: DateTime.now(),
//     ),
//     Product(
//       name: 'Ultra-Thin Laptop',
//       price: 999.0,
//       description: 'A lightweight laptop for professionals.',
//       categoryId: 'laptops',
//       imageUrls: [
//         'https://picsum.photos/300/200?random=4',
//         'https://picsum.photos/300/200?random=5',
//         'https://picsum.photos/300/200?random=6',
//       ],
//       publishDate: DateTime.now(),
//     ),
//     Product(
//       name: 'Wireless Noise-Canceling Headphones',
//       price: 299.0,
//       description: 'Premium headphones with noise-canceling technology.',
//       categoryId: 'audio',
//       imageUrls: [
//         'https://picsum.photos/300/200?random=7',
//         'https://picsum.photos/300/200?random=8',
//         'https://picsum.photos/300/200?random=9',
//       ],
//       publishDate: DateTime.now(),
//     ),
//     Product(
//       name: '4K Ultra HD Smart TV',
//       price: 799.0,
//       description: 'A smart TV with 4K resolution and HDR support.',
//       categoryId: 'tvs',
//       imageUrls: [
//         'https://picsum.photos/300/200?random=10',
//         'https://picsum.photos/300/200?random=11',
//         'https://picsum.photos/300/200?random=12',
//       ],
//       publishDate: DateTime.now(),
//     ),
//   ];

//   // Add products to Firestore
//   for (var product in products) {
//     await _firestore.collection('products').doc(product.id).set(product.toMap());
//   }

//   print('Products seeded successfully!');
// }

// void main() async {
//   // Ensure Flutter is initialized
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp();

//   // Seed products
//   await seedProducts(); // Use await here
}