import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../screens/my_estimate_screen.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  // Banner-specific data
  final List<Map<String, String>> bannerItems = [
    {
      "image": "https://picsum.photos/seed/pccom_warranty/1080/720",
      "title": "신뢰의 시작, PiCom 보증",
      "description": "엄격한 검수를 통과한 중고 컴퓨터, 안심하고 구매하세요.",
      "route": "/warranty-info"
    },
    {
      "image": "https://picsum.photos/seed/pccom_choice/1080/720",
      "title": "어떤 컴퓨터를 살지 고민되나요?",
      "description": "PiCom의 전문가가 당신에게 딱 맞는 PC를 찾아드립니다.",
      "route": "/pc-recommendation"
    },
    {
      "image": "https://picsum.photos/seed/pccom_event/1080/720",
      "title": "리뷰 남기고 포인트 받자!",
      "description": "소중한 후기를 작성해주신 모든 분들께 혜택을 드려요.",
      "route": "/review-event"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: bannerItems.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    if (item['route'] == '/pc-recommendation') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyEstimateScreen()),
                      );
                    } else {
                      // TODO: Implement navigation logic for other routes
                      print("Navigating to ${item['route']}");
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: NetworkImage(item['image']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          carouselController: _controller,
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 2.0,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerItems.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                      .withOpacity(_current == entry.key ? 0.9 : 0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}