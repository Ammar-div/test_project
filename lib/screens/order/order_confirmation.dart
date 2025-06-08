import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/user/my_orders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class OrderConfirmation extends StatelessWidget {
  const OrderConfirmation({super.key});

     // Helper method to create a bullet point
Widget _buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          '• ',
          style: TextStyle(fontSize: 30.sp),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
              text,
              style:  TextStyle(fontSize: 14.sp),
            ),
          
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: kPrimaryBlue.withOpacity(0.2),
                              width: 1.0.w,
                            ),
                          ),
                        ),
                        child: Text(
                          'Order Confirmed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ),
                       SizedBox(height: 22.h),


                      Padding(padding:const EdgeInsets.all(10),
                      child: Icon(Icons.check_circle_outline,
                        color: kPrimaryBlue,
                        size: 160,
                        ),
                       ),

                        SizedBox(height: 16.h),

                        Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                       child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                          Icon(Icons.delivery_dining_sharp , color: kPrimaryBlue,size: 28,),
                           SizedBox(width: 6.w),
                            Text('Your Delivery captin will contact you soon.',
                           style: TextStyle(
                            fontSize: 12.sp,
                            color: kPrimaryBlue,
                           ),
                           textAlign: TextAlign.center,
                              ),
                         ],
                       ),
                        ),



                        SizedBox(height: 16.h),

                       const Text('You can see your order status in the "my orders" screen.' , 
                       textAlign: TextAlign.center,
                       style: TextStyle(color: kPrimaryBlue),
                       ),

                         SizedBox(height: 13.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Back Button
                          Flexible(
                            flex: 3, // 3 parts of the available space
                            child: SizedBox(
                              width: double.infinity.w, // Take full width of the Flexible
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const HomeScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryBlue,
                                  foregroundColor: kWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child:  Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center contents horizontally
                                    children: [
                                      Icon(Icons.arrow_back_ios_new, color: kWhite),
                                      SizedBox(width: 4.w),
  
                                      Text('Home Screen', style: TextStyle(fontSize: 10.sp)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                           SizedBox(width: 16.w), // Add spacing between buttons
                          // Checkout Button
                          Flexible(
                            flex: 3, // 3 parts of the available space
                            child: SizedBox(
                              width: double.infinity.w, // Take full width of the Flexible
                              child: ElevatedButton(
                                onPressed: () {
                                  final user = FirebaseAuth.instance.currentUser;
                                  final userId = user!.uid;
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => MyOrders(userId: userId,)));

                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryBlue,
                                  foregroundColor: kWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child:  Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center contents horizontally
                                    children: [
                                      Icon(Icons.local_shipping, color: kWhite),
                                      SizedBox(width: 6.w),
                                      Text('Order Status', style: TextStyle(fontSize: 10.sp)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}