import 'package:flutter/material.dart';

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
      color: const Color.fromARGB(255, 242, 223, 214),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/pic1.avif'),
          const SizedBox(height: 40,),
          const Text('How It Works' , style: TextStyle(
            color: Colors.black,
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
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),
                  Text('2. Buyers Purchase: Browse and buy without direct interaction.' , 
                  style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),
                  Text('3. We Deliver: We handle the delivery to ensure a smooth transaction.' , 
                  style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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