import 'package:flutter/material.dart';

class Screen3 extends StatefulWidget
{
  const Screen3({super.key});


 @override
  State<Screen3> createState() {
    return _Screen3State();
  }
}

class _Screen3State extends State<Screen3>
{
  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: const Color.fromARGB(255, 242, 223, 214),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/pic2.png'),
          const SizedBox(height: 40,),
          const Text('Secure Transactions' , style: TextStyle(
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
                  Text('1. Your payment is held securely by us until you receive your order.' , 
                  style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),
                  Text('2. Once confirmed, the payment is released to the seller, minus a small fee for our service.' , 
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