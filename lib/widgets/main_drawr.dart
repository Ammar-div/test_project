import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:test_project/user/account_management.dart';
import 'package:test_project/user/my_advertisings.dart';
import 'package:test_project/user/my_favorites.dart';
import 'package:test_project/user/my_orders.dart';
import 'package:test_project/user/sell_product.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';  // Import for color constants

class MainDrawr extends StatefulWidget {
  const MainDrawr({super.key});

  @override
  State<MainDrawr> createState() => _MainDrawrState();
}


 void _handleAccountManagement(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
     final userId = user.uid;
     final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
     final username = userDoc['username'] ?? 'N/A';
     final email = userDoc['email'] ?? 'N/A';
     final phoneNumber = userDoc['phone_number'] ?? 'N/A';
     final fullName = userDoc['name'] ?? 'N/A';
     final imageUrl = userDoc['image_url'] ;
    // User is logged in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>  AccountManagementScreen(
          userId : user.uid,
          initialUsername : username,
          initialEmail : email,
          initialPhoneNumber : phoneNumber,
          initialName : fullName,
          initialImageUrl: imageUrl,
          ),
      ),
    );
  } else {
    _loginDialog(context , "1");
  }
}


void _handleSellProduct(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
     final userId = user.uid;
     final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
     final email = userDoc['email'] ?? 'N/A';
     final fullName = userDoc['name'] ?? 'N/A';
    // User is logged in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>  SellProduct(
          sellerUserId : user.uid,
          sellerEmail : email,
          sellerlName : fullName,
          ),
      ),
    );
  } else {
    _loginDialog(context , "5");
  }
}


void _handleMyAdvertisings(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {

    // User is logged in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>  MyAdvertisings(
          sellerUserId : user.uid,
          ),
      ),
    );
  } else {
    _loginDialog(context , "4");
  }
}

void _handleMyFavorites(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    // User is logged in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>  MyFavorites(),
      ),
    );
  } else {
    _loginDialog(context , "2");
  }
}


void _handleMyOrders(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    // User is logged in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>  MyOrders(
          userId : user.uid,
          ),
      ),
    );
  } else {
    _loginDialog(context , "3");
  }
}



void _loginDialog(BuildContext context , String x) 
{
     showDialog<String>(
      context: context,
      builder: (BuildContext context) =>  Dialog(
        child:
         Padding(padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding:  EdgeInsets.only(top: 12),
                child: Text('You need to log in.'),
              ),
               SizedBox(height: 17.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [ 
                  TextButton(onPressed: () {
                    Navigator.pop(context);
                  },
                   child: const Text('Close'), 
                   ),
          
                  TextButton(onPressed: () async {
                        // User is not logged in
                      final result = await Navigator.of(context).push<Map<String , dynamic>>(
                        MaterialPageRoute(
                          builder: (ctx) => const AuthScreen(),
                        ),
                      );
          
                      if (result != null && result['success'] == true) {
                        final userId = result['userId'];
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                        final username = userDoc['username'] ?? 'N/A';
                        final email = userDoc['email'] ?? 'N/A';
                        final phoneNumber = userDoc['phone_number'] ?? 'N/A';
                        final fullName = userDoc['name'] ?? 'N/A';
                        final imageUrl = userDoc['image_url'] ;
                        
          
          
                        if(x == "1")
                        {
                        // User finished logging in or signing up
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AccountManagementScreen(
                            userId : userId,
                            initialUsername : username,
                            initialEmail : email,
                            initialPhoneNumber : phoneNumber,
                            initialName : fullName,
                            initialImageUrl: imageUrl,
                             ),
                           ),
                         );
                        }
          
          
                        if(x == "5")
                        {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => SellProduct(
                              sellerUserId: userId,
                              sellerEmail: email,
                              sellerlName: fullName),
                            )
                          );
                        }
          
                        if(x == "4")
                        {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => MyAdvertisings(
                              sellerUserId: userId,
                              ),
                            )
                          );
                        }
          
          
                        if(x == "2")
                        {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => MyFavorites(),
                            )
                          );
                        }
          
          
                        if(x == "3")
                        {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) =>  MyOrders(
                                userId : userId,
                                ),
                            ),
                          );
                        }
          
                      }
                  },
                   child: const Text('Login/Sign up'),),
              ],
             ),
            ],
           ),
        ),
        ),
      ),
    );
}



class _MainDrawrState extends State<MainDrawr> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kBackgroundGrey,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryBlue,
                  kPrimaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      kWhite,
                      kWhite.withOpacity(0.5),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.settings,
                    size: 48,
                    color: kWhite,
                  ),
                ),
                 SizedBox(width: 18.w),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      kWhite.withOpacity(0.5),
                      kWhite,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child:  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.manage_accounts,
              size: 26,
              color: kPrimaryBlue,
            ),
            title: Text(
              'Account Management',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
              ),
            ),
            onTap: () => _handleAccountManagement(context),
          ),
           SizedBox(height: 12.h),
          ListTile(
            leading: Icon(
              Icons.favorite,
              size: 26,
              color: kPrimaryBlue,
            ),
            title: Text(
              'My Favorites',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
              ),
            ),
            onTap: () {
              _handleMyFavorites(context);
            },
          ),
           SizedBox(height: 12.h),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              size: 26,
              color: kPrimaryBlue,
            ),
            title: Text(
              'My Orders',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
              ),
            ),
            onTap: () {
             _handleMyOrders(context);
            },
          ),
           SizedBox(height: 12.h),
          ListTile(
            leading: Icon(
              Icons.sell,
              size: 26,
              color: kPrimaryBlue,
            ),
            title: Text(
              'My Advertisings',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
              ),
            ),
            onTap: () {
               _handleMyAdvertisings(context);
            },
          ),
           SizedBox(height: 12.h),
          ListTile(
            leading: Icon(
              Icons.attach_money,
              size: 26,
              color: kPrimaryBlue,
            ),
            title: Text(
              'Sell Product',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
              ),
            ),
            onTap: () {
             _handleSellProduct(context);
            },
          ),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return ListTile(
                  leading: Icon(
                    Icons.logout,
                    size: 26,
                    color: kPrimaryBlue,
                  ),
                  title: Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18.sp,
                    ),
                  ),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => const HomeScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink(); // Return empty widget if user is not logged in
            },
          ),
        ],
      ),
    );
  }
}
