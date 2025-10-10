// AnimatedSwitcher(
//   duration: const Duration(milliseconds: 500),
//   transitionBuilder: (child, animation) => FadeTransition(
//     opacity: animation,
//     child: SlideTransition(
//       position: Tween<Offset>(
//         begin: const Offset(0.2, 0), // slight slide from right
//         end: Offset.zero,
//       ).animate(animation),
//       child: child,
//     ),
//   ),
//   child: userChoice == null
//       ? Column(
//           key: const ValueKey('chooseOddEven'),
//           children: [
//             Text("Choose Odd or Even",
//                 style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white)),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: ["Odd", "Even"].map((e) {
//                 return GestureDetector(
//                   onTap: () => setState(() => userChoice = e),
//                   child: Container(
//                     margin: const EdgeInsets.all(10),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 40, vertical: 15),
//                     decoration: BoxDecoration(
//                       color: userChoice == e
//                           ? Colors.white
//                           : AppColors.boxYellow,
//                       borderRadius: BorderRadius.circular(25),
//                       border: Border.all(color: Colors.black, width: 3),
//                     ),
//                     child: Text(e,
//                         style: AppFonts.bebasNeue(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black)),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         )
//       : Column(
//           key: const ValueKey('chooseNumber'),
//           children: [
//             const Text("Select a number (1-6)",
//                 style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white)),
//             GridView.builder(
//               shrinkWrap: true,
//               gridDelegate:
//                   const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//               ),
//               itemCount: 6,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () => setState(() => userNumber = index + 1),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       border: userNumber == index + 1
//                           ? Border.all(color: Colors.yellowAccent, width: 5)
//                           : Border.all(color: Colors.black, width: 5),
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Image.asset(
//                           'assets/gestures/${index + 1}.png',
//                           fit: BoxFit.cover),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: performToss,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.yellow,
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 60, vertical: 20),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30)),
//                 elevation: 12,
//               ),
//               child: Text("Toss",
//                   style: AppFonts.bebasNeue(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black)),
//             ),
//           ],
//         ),
// )


// if (!isTossing && !tossDone) ...[
//   AnimatedSwitcher(
//     duration: const Duration(milliseconds: 500),
//     transitionBuilder: (child, animation) => FadeTransition(
//       opacity: animation,
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0.2, 0),
//           end: Offset.zero,
//         ).animate(animation),
//         child: child,
//       ),
//     ),
//     child: userChoice == null
//         ? Column(
//             key: const ValueKey('chooseOddEven'),
//             children: [
//               const Text("Choose Odd or Even",
//                   style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: ["Odd", "Even"].map((e) {
//                   return GestureDetector(
//                     onTap: () => setState(() => userChoice = e),
//                     child: Container(
//                       margin: const EdgeInsets.all(10),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 40, vertical: 15),
//                       decoration: BoxDecoration(
//                         color: userChoice == e
//                             ? Colors.white
//                             : AppColors.boxYellow,
//                         borderRadius: BorderRadius.circular(25),
//                         border: Border.all(color: Colors.black, width: 3),
//                       ),
//                       child: Text(e,
//                           style: AppFonts.bebasNeue(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black)),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           )
//         : Column(
//             key: const ValueKey('chooseNumber'),
//             children: [
//               const Text("Select a number (1-6)",
//                   style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white)),
//               GridView.builder(
//                 shrinkWrap: true,
//                 gridDelegate:
//                     const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemCount: 6,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () => setState(() => userNumber = index + 1),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: userNumber == index + 1
//                             ? Border.all(color: Colors.yellowAccent, width: 5)
//                             : Border.all(color: Colors.black, width: 5),
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.asset(
//                             'assets/gestures/${index + 1}.png',
//                             fit: BoxFit.cover),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: performToss,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.yellow,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 60, vertical: 20),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30)),
//                   elevation: 12,
//                 ),
//                 child: Text("Toss",
//                     style: AppFonts.bebasNeue(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black)),
//               ),
//             ],
//           ),
//   ),
// ],
