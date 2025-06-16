import 'package:flutter/material.dart';
import 'package:test_project/screens/admin/pc_category/pc_category.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryToBeEdited extends StatelessWidget {
  const CategoryToBeEdited({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Column(
          children: [
            // Elevated Button at the top
            Padding(
              padding:  EdgeInsets.only(top: 50),
              child: SizedBox(
                width: screenWidth * 0.75.w,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child:  Text(
                    'Back',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            
            // The GridView below
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 10),
                child: GridView(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 60,
                  ),
                  children: [
                    Card(
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => const PcCategory()),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              color: Colors.black87,
                              width: double.infinity.w,
                              child:  Padding(
                                padding: EdgeInsets.symmetric(vertical: 7),
                                child: Text(
                                  'PC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Image.asset(
                                'assets/images/pc.jpg',
                                fit: BoxFit.cover,
                                width: double.infinity.w,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                   
                  ],
                ),
              ),
            ),
          ],
        ),
      
    );
  }
}
