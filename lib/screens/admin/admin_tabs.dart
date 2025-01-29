import 'package:flutter/material.dart';
import 'package:test_project/screens/admin/crud_operations.dart';
import 'package:test_project/screens/admin/creating_delivery_account.dart';
import 'package:test_project/screens/admin/transactions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/screens/auth_screen.dart';

class AdminTabsScreen extends StatefulWidget {
  const AdminTabsScreen({super.key});
  @override
  State<AdminTabsScreen> createState() {
    return _AdminTabsScreenState();
  }
}

class _AdminTabsScreenState extends State<AdminTabsScreen> {
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }


  @override
void initState() {
  super.initState();

  // FirebaseAuth.instance.currentUser?.getIdTokenResult().then((idTokenResult) {
  //   print(idTokenResult.claims); // Should log {role: 'admin'} for admin users

  //   if (idTokenResult?.claims?['role'] != 'admin') {
  //     // If the user is not an admin, redirect to a non-admin screen
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (ctx) => const AuthScreen()),
  //     );
  //   }
  // });
}


  @override
  Widget build(BuildContext context) {
    Widget activePage = const CrudOperationsScreen();
    var activePageTitle = 'CRUD Operations';

    if (_selectedPageIndex == 1) {
      activePage = const CreatingDeliveryAccountScreen();
      activePageTitle = 'Creating Delivery Account';
    }

    if (_selectedPageIndex == 2) {
      activePage = const TransactionsScreen();
      activePageTitle = 'Transaction';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activePageTitle),
        automaticallyImplyLeading: false, // Disables the back arrow
        actions: [
          IconButton(onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const AuthScreen(),));
          }, icon: const Icon(
            Icons.exit_to_app,
            color: Colors.red,
          )),
      ],
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration_outlined),
            label: 'CRUD Operations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Delivery Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mobile_friendly),
            label: 'Transaction',
          ),
        ],
      ),
    );
  }
}