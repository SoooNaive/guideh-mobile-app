import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final CarouselSliderController carouselController = CarouselSliderController();

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getProduct(context),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return const SizedBox.shrink();
        }
        else {
          List imageList = snapshot.data['slides'] ?? [];
          return imageList.isEmpty
            ? const SizedBox.shrink()
            : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(80),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
              ),
              height: 202,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    InkWell(
                      child: CarouselSlider(
                        items: imageList.map(
                              (item) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: GestureDetector(
                              child: Image.network(
                                item['Image'],
                                fit: BoxFit.contain,
                              ),
                              onTap: () => goUrl('${item['Url']}?token=${snapshot.data['token']}'),
                            ),
                          ),
                        ).toList(),
                        carouselController: carouselController,
                        options: CarouselOptions(
                          height: 180,
                          scrollPhysics: const BouncingScrollPhysics(),
                          autoPlay: false,
                          enlargeCenterPage: true,
                          aspectRatio: 2,
                          viewportFraction: 0.68,
                          onPageChanged: (index, reason) {
                            setState(() {
                              currentIndex = index;
                            });
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: imageList.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => carouselController.animateToPage(entry.key),
                          child: Container(
                            width: currentIndex == entry.key ? 17 : 7,
                            height: 7.0,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 3.0,
                            ),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: currentIndex == entry.key
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.secondary
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
        }
      }
    );
  }
}

// баннеры для слайдера
Future<Object> getProduct(BuildContext context) async {
  final response = await Http.mobApp(
    ApiParams('MobApp', 'MP_list_product')
  );
  return {
    'token': await Auth.token,
    'slides': response['Data'],
  };
}