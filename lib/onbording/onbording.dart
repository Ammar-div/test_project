import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/onbording/screen1.dart';
import 'package:test_project/onbording/screen2.dart';
import 'package:test_project/onbording/screen3.dart';
import 'package:test_project/onbording/screen4.dart';
//import 'package:test_project/screens/test_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:test_project/screens/HomeScreen.dart';
class OnBording extends StatefulWidget {
  const OnBording({super.key});

  @override
  State<OnBording> createState() {
    return _OnBordingState();
  }
}

class _OnBordingState extends State<OnBording> {
  PageController pageController = PageController();
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            children: const [
              Screen1(),
              Screen2(),
              Screen3(),
              Screen4(),
            ],
          ),
          Positioned(
            bottom: 40, // Adjust this value to move the row further down
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentPageIndex > 0) // Show "Back" button on pages 2, 3, and 4
                    ElevatedButton(
                      onPressed: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text("Back"),
                    ),
                  SmoothPageIndicator(
                    controller: pageController,
                    count: 4,
                    effect: ExpandingDotsEffect(
                      activeDotColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      dotColor: Colors.grey,
                      dotHeight: 8.0,
                      dotWidth: 8.0,
                      expansionFactor: 3,
                    ),
                  ),
                  currentPageIndex == 3
                      ? ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('onboarding_completed', true); // Save flag
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const HomeScreen())); // Navigate to the home page
                          },
                          child: const Text("Get Started"),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeIn,
                            );
                          },
                          child: const Text("Next"),
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




