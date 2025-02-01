import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user authentication



class MyFavorites extends StatefulWidget {
  @override
  State<MyFavorites> createState() => _MyFavoritesState();
}

class _MyFavoritesState extends State<MyFavorites> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('favorites')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorites found.'));
          }

          final favorites = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(favorite['imageUrl']),
                title: Text(favorite['productName']),
                subtitle: Text('${favorite['productPrice']} JOD'),
              );
            },
          );
        },
      ),
    );
  }
}