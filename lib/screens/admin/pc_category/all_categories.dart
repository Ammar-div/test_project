import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/products_of_category.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';


class AllCategories extends StatefulWidget {
  const AllCategories({super.key});

  @override
  State<AllCategories> createState() => _AllCategoriesState();
}

class _AllCategoriesState extends State<AllCategories> {

  Stream? categoriesStream;

    Future<Stream<QuerySnapshot>> getCategoryDetails() async {
   return await FirebaseFirestore.instance
        .collection("categories")
        .where("deleted_at", isNull: true)
        .snapshots();
}

getOnTheLoad() async {
  categoriesStream = await getCategoryDetails();
  setState(() {
    
  });
}

@override
  void initState() {
    getOnTheLoad();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return  Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
             child: Column(
               children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                    ),
                    TextButton(
                     onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => VerticalAllCategories()));
                     },
                     child:  Text('See All',style: TextStyle(fontSize: 11.sp),),
                     ),
                  ],
                ),
           
                  SizedBox(
                    height: 120.h, // Limit the height to fit 4 categories
                    child: StreamBuilder(
                        stream: categoriesStream,
                        builder: (context , AsyncSnapshot snapshot) {
                          return snapshot.hasData ? ListView.builder(
                          scrollDirection: Axis.horizontal, // Set the scroll direction to horizontal
                          itemCount: snapshot.data.docs.length,
                          itemBuilder: (ctx, index) {
                            DocumentSnapshot db = snapshot.data.docs[index];
                            return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5.0), // Add spacing between items
                            width: 90, // Set a fixed width for each item to fit 4 items in the screen
                            child: GestureDetector(
                              onTap: () {
                                var categoryId = db.id; 
                                var categoryName = db["name"];
                                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => ProductsOfCategory(
                                  categoryId : categoryId,
                                  categoryName,
                                ) ,));
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(db["imageUrl"]),
                                  ),
                                   SizedBox(height: 8.h), // Add spacing between image and text
                                  Text(
                                    db["name"],
                                    textAlign: TextAlign.center, // Center the text
                                    style:  TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                          }
                        ): const Text('No Available Categories');
                        },
                        
                      ),
                  ),            
               ],
             ),
           );
  }
}



class VerticalAllCategories extends StatefulWidget {
  VerticalAllCategories({super.key});

  @override
  State<VerticalAllCategories> createState() => _VerticalAllCategoriesState();
}

class _VerticalAllCategoriesState extends State<VerticalAllCategories> {
  Stream? categoriesStream;

  Future<Stream<QuerySnapshot>> getCategoryDetails() async {
  return await FirebaseFirestore.instance.collection("categories").snapshots();
}

  getOnTheLoad() async {
  categoriesStream = await getCategoryDetails();
  setState(() {
    
  });
}

@override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    appBar: AppBar(
      title: const Text('Categories'),
    ),
    body: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: categoriesStream,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(child: Text('No Available Categories'));
                }
                return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (ctx, index) {
                    DocumentSnapshot db = snapshot.data.docs[index];
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                             var categoryId = db.id; 
                                var categoryName = db["name"];
                                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => ProductsOfCategory(
                                  categoryId : categoryId,
                                  categoryName,
                                )
                                )
                                );
                          },
                          child:Card(
                            margin: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: kPrimaryBlue,
                                width: 2.w,
                              ),
                            ),
                            clipBehavior: Clip.hardEdge,
                            elevation: 2,
                            child: Column(
                              children: [
                                // Image with individual loading indicator
                                Image.network(
                                  db["imageUrl"],
                                  height: 300.h,
                                  width: double.infinity.w,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, size: 50, color: Colors.red),
                                    );
                                  },
                                ),
                                 SizedBox(height: 8.h),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0,0,0,6),
                                  child: Text(
                                    db["name"],
                                    textAlign: TextAlign.center,
                                    style:  TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                         SizedBox(height: 25.h), // Add vertical space after each card
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}