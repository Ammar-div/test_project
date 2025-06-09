import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/constants/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class Screen1 extends StatefulWidget
{
  const Screen1({super.key});


 @override
  State<Screen1> createState() {
    return _Screen1State();
  }
}

class _Screen1State extends State<Screen1>
{
  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: kBackgroundGrey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Row(
              children: [
                Image.asset('assets/images/welcome-removebg-preview.png' , width: 250.w,),
                
                 Text('To',
                style: GoogleFonts.moonDance(
                  color: kPrimaryBlue,
                  fontSize: 65,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              ],
            ),
          const SizedBox(height: 0,),
          
           Image.asset('assets/images/logo-removebg-preview.png' , width: 220.w,),
          

           Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
             child: Text('Discover a seamless way to buy and sell used items.' , 
             style: TextStyle(
              color: kPrimaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              ),
                textAlign: TextAlign.center,
            ),
           ),
            const SizedBox(height: 30,),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
             child: Text('Enjoy a hassle-free experience with our secure and efficient platform.' , 
             style: TextStyle(
              color: kPrimaryBlue,
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