import 'dart:io';

import 'package:flutter/material.dart';

class PinWithAvatar extends StatelessWidget {
  final String imageUrl;
  const PinWithAvatar({
    super.key,
    required this.imageUrl,
  });


  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PinPainter(),
      child: SizedBox(
        height: 184,
        width: 119,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -15), // Move up by 10 pixels
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2), // Optional: white border effect
              child: ClipOval(
                child: imageUrl!=" "?Image.file(File(imageUrl),fit: BoxFit.cover,): Image.asset(
                  'assets/images/child.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF2D6F78)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.quadraticBezierTo(
        0, size.height * 0.6, size.width * 0.1, size.height * 0.3);
    path.arcToPoint(
      Offset(size.width * 0.9, size.height * 0.3),
      radius: Radius.circular(50),
      clockwise: true,
    );
    path.quadraticBezierTo(
        size.width, size.height * 0.6, size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
