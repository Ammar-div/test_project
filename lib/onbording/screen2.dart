import 'package:flutter/material.dart';
import 'package:test_project/constants/colors.dart';

class Screen2 extends StatefulWidget
{
  const Screen2({super.key});


 @override
  State<Screen2> createState() {
    return _Screen2State();
  }
}

class _Screen2State extends State<Screen2>
{
  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: kBackgroundGrey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/pic1.avif'),
          const SizedBox(height: 40,),
          Text('How It Works' , style: TextStyle(
            color: kPrimaryBlue,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),),
          const SizedBox(height: 20,),
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
             child: Column(
               children: 
               [
                  Text('1. Sellers Post Items: List your items quickly and easily.' , 
                  style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),
                  Text('2. Buyers Purchase: Browse and buy without direct interaction.' , 
                  style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),
                  Text('3. We Deliver: We handle the delivery to ensure a smooth transaction.' , 
                  style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

              ]
             ),
           ),



        ],
      ),
    );
  }
}