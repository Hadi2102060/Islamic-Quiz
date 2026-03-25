// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:quiz_app/services/audio_services.dart';

// class AudioToggleScreen extends StatefulWidget {
//   const AudioToggleScreen({super.key});

//   @override
//   State<AudioToggleScreen> createState() => _AudioToggleScreenState();
// }

// class _AudioToggleScreenState extends State<AudioToggleScreen> {
//   final AudioService audioService = AudioService();
//   String statusMessage = "Loading...";

//   @override
//   void initState() {
//     super.initState();
//     _initAudio();
//   }

//   Future<void> _initAudio() async {
//     await audioService.init();
//     await audioService.play();
//     _updateStatus();
//   }

//   void _updateStatus() {
//     setState(() {
//       statusMessage = audioService.isSoundEnabled
//           ? "🔊 Sound ON - Music Playing"
//           : "🔇 Sound OFF - Music Paused";
//     });
//   }

//   Future<void> _toggleSound() async {
//     await audioService.toggle();
//     _updateStatus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF071B2F),
//                   Color(0xFF073E3A),
//                   Color(0xFF0A4D4A),
//                 ],
//               ),
//             ),
//           ),
//           Center(
//             child: GestureDetector(
//               onTap: _toggleSound,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: 220,
//                 height: 220,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: LinearGradient(
//                     colors: audioService.isSoundEnabled
//                         ? [Colors.green, Colors.teal]
//                         : [Colors.red, Colors.orange],
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       audioService.isSoundEnabled
//                           ? Icons.volume_up
//                           : Icons.volume_off,
//                       color: Colors.white,
//                       size: 80,
//                     ).animate().scale(duration: 400.ms),
//                     const SizedBox(height: 15),
//                     Text(
//                       audioService.isSoundEnabled ? "SOUND ON" : "SOUND OFF",
//                       style: GoogleFonts.montserrat(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: 1.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 80,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Text(
//                 statusMessage,
//                 style: GoogleFonts.inter(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ).animate().fadeIn(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
