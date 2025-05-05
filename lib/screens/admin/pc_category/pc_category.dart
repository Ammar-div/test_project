import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/admin/pc_category/pc_create_category.dart';
import 'package:test_project/screens/admin/pc_category/pc_edit_category.dart';

class PcCategory extends StatefulWidget {
  const PcCategory({super.key});

  @override
  State<PcCategory> createState() => _PcCategoryState();
}

class _PcCategoryState extends State<PcCategory> {
  Stream<QuerySnapshot>? categoryStream;



Future<void> deleteCategoryDetail(String id, String imageUrl) async {
  try {
    // Delete the image from Firebase Storage
    if (imageUrl.isNotEmpty) {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    }

    // Delete the category document from Firestore
    await FirebaseFirestore.instance.collection("categories").doc(id).delete();

    // Update UI and show success message
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 5),
        content: Text('Category and associated image deleted successfully.'),
      ),
    );
  } catch (e) {
    // Handle errors and show failure message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('Failed to delete category: $e'),
      ),
    );
  }
}


  Future<Stream<QuerySnapshot>> getCategoryDetails() async {
    return FirebaseFirestore.instance.collection("categories").snapshots();
  }

  void getOnTheLoad() async {
    categoryStream = await getCategoryDetails();
    setState(() {});
  }

  @override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

  Widget allCategoryDetails() {
    return StreamBuilder<QuerySnapshot>(
      stream: categoryStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No Categories, Try adding some...'),
          );
        }

        // Map Firestore data to widgets
        return GridView.builder(
          padding: const EdgeInsets.all(0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var documentSnapshot = snapshot.data!.docs[index];
            var category = documentSnapshot.data() as Map<String, dynamic>;
            String id = documentSnapshot.id; // Document ID/ Document ID
            String name = category['name'] ?? 'Unknown';
            String imageUrl = category['imageUrl'] ?? '';

            return Card(
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PcEditCategory(
                    userId: id,
                     initialName: name,
                      initialImageUrl: imageUrl,
                      )));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 7 , horizontal: 4),
                      child: Row(
                        children: [
                          Text(name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),

                          IconButton(onPressed: () {
                            // deleteCategoryDetail(id);
                             showDialog<String>(
                              context: context,
                              builder: (BuildContext context) =>  Dialog(
                                child:
                                Padding(padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text('Delete This Category?'),
                                    const SizedBox(height: 17,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [ 
                                        TextButton(onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('No'), 
                                        ),

                                        TextButton(onPressed: () async {
                                            deleteCategoryDetail(id , imageUrl);
                                        },
                                        child: const Text('Yes'),),
                                      ],
                                    ),
                                  ],
                                ),
                                ),
                              ),
                            );
                          },
                          color: Colors.redAccent,
                          icon: const Icon(Icons.delete)
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('PC Categories'),
        actions: [
          ElevatedButton(
            onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (ctx) => PcCreateCategory(),
                );
            },
            child: const Text(
              'Create Category',
              style: TextStyle(),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Expanded(
              child: allCategoryDetails(),
            ),
          ],
        ),
      ),
    );
  }
}
