import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ContentLineType {
  twoLines,
  threeLines,
}


Widget DashboardButtonsShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      children: [
        // First row (70% - 30%)
        _buildShimmerRow(context, firstWidth: 0.7, secondWidth: 0.3),
        const SizedBox(height: 10),
        // Second row (30% - 70%)
        _buildShimmerRow(context, firstWidth: 0.3, secondWidth: 0.7),
        const SizedBox(height: 10),
        // Third row (70% - 30%)
        _buildShimmerRow(context, firstWidth: 0.7, secondWidth: 0.3),
      ],
    ),
  );
}

Widget _buildShimmerRow(BuildContext context, {
  required double firstWidth,
  required double secondWidth,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  return Row(
    children: [
      Container(
        width: screenWidth * firstWidth - 15, // Subtract half of gap (10/2=5) and padding (10)
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: screenWidth * secondWidth - 15, // Subtract half of gap (10/2=5) and padding (10)
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ],
  );
}

Widget buildShimmerContainer({double? width, double? height}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

Widget buildShimmerMapPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
Widget buildConnectedChildsPlaceholder() {
  return SizedBox(
    width: double.infinity,
    child: Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                  List.generate(4, (index) {
                    return GestureDetector(

                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 10),
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            height: 40,
                            width: 65,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(30),

                            ),

                          ),
                          Positioned(
                            top: 2,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                //color: Colors.green,
                                color:Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1), // optional border
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
            ),
          ),
        ),
        GestureDetector(

          child: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            height: 40,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(30),

            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: Colors.grey,
                ),
                Container(
                  width: 12,
                  height: 2,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildShimmerAppUsagePlaceholder() {
  return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [

            SizedBox(height: 16.0),
            ContentPlaceholder(
              lineType: ContentLineType.threeLines,
            ),

            SizedBox(height: 16.0),
            ContentPlaceholder(
              lineType: ContentLineType.threeLines,
            ),

            SizedBox(height: 16.0),
            ContentPlaceholder(
              lineType: ContentLineType.threeLines,
            ),
          ],
        ),
      ));
}

Widget buildShimmerHistoryMapPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 16.0),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    ),
  );
}

class BannerPlaceholder extends StatelessWidget {
  const BannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200.0,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
    );
  }
}

class TitlePlaceholder extends StatelessWidget {
  final double width;

  const TitlePlaceholder({
    super.key,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: 12.0,
            color: Colors.white,
          ),
          const SizedBox(height: 8.0),
          Container(
            width: width * 0.6,
            height: 12.0,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class ContentPlaceholder extends StatelessWidget {
  final ContentLineType lineType;

  const ContentPlaceholder({
    super.key,
    required this.lineType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96.0,
            height: 72.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10.0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8.0),
                ),
                if (lineType == ContentLineType.threeLines)
                  Container(
                    width: double.infinity,
                    height: 10.0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8.0),
                  ),
                Container(
                  width: 100.0,
                  height: 10.0,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}