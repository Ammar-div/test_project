import 'package:flutter/material.dart';

class Screen4 extends StatefulWidget
{
  const Screen4({super.key});


 @override
  State<Screen4> createState() {
    return _Screen4State();
  }
}

class _Screen4State extends State<Screen4>
{
  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: const Color.fromARGB(255, 242, 223, 214),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/pic3.webp'),
          const SizedBox(height: 40,),
          const Text('Earn While You Sell' , style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),),
          const SizedBox(height: 20,),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
             child: Text('Let sellers know they can post items and receive payment securely once buyers confirm receipt, with a small percentage going to support the app’s services.' , 
             style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              ),
                textAlign: TextAlign.center,
            ),
           ),
        ],
      ),
    );
  }
}