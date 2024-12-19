import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/polis/models/kasko_driver.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/theme/theme.dart';

class KaskoChangeDriversAddPage extends StatefulWidget {
  final Function(KaskoDriver driver)? addedDriver;
  const KaskoChangeDriversAddPage({
    super.key,
    this.addedDriver,
  });

  @override
  State<KaskoChangeDriversAddPage> createState() => _KaskoChangeDriversAddState();
}

class _KaskoChangeDriversAddState extends State<KaskoChangeDriversAddPage> {

  final addDriverFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController docSeriesController = TextEditingController();
  final TextEditingController docNumberController = TextEditingController();

  String? photoLicenseFrontPath;
  String? photoLicenseBackPath;

  void addPhotoLicenseFront(String imagePath) {
    setState(() { photoLicenseFrontPath = imagePath; });
  }
  void addPhotoLicenseBack(String imagePath) {
    setState(() { photoLicenseBackPath = imagePath; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить водителя'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: addDriverFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Введите данные водителя:', style: TextStyle(
                      fontWeight: FontWeight.bold
                    )),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        // prefixIcon: Icon(Icons.pin_drop),
                        border: UnderlineInputBorder(),
                        labelText: 'ФИО',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ФИО';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: birthdateController,
                      decoration: const InputDecoration(
                        // prefixIcon: Icon(Icons.pin_drop),
                        border: UnderlineInputBorder(),
                        labelText: 'Дата рождения',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [DateTextFormatter()],
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите дату рождения';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    const Text('Водительское удостоверение:', style: TextStyle(
                      fontWeight: FontWeight.bold
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: docSeriesController,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'ВУ Серия',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите серию ВУ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: docNumberController,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'ВУ Номер',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите номер ВУ';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('Сделайте фотографии ВУ:', style: TextStyle(
                      fontWeight: FontWeight.bold
                    )),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => TakePhoto(addPhoto: addPhotoLicenseFront),
                                ));
                              },
                              child: photoLicenseFrontPath == null
                                ? Container(
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffd6dbdf),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(borderRadiusBig)
                                    ),
                                  ),
                                  child: const Text(
                                    'Фото лицевой стороны',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FittedBox(
                                    clipBehavior: Clip.antiAlias,
                                    fit: BoxFit.cover,
                                    child: Image.file(File(photoLicenseFrontPath!)),
                                  ),
                                ),
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => TakePhoto(addPhoto: addPhotoLicenseBack),
                                  ));
                                },
                                child: photoLicenseBackPath == null
                                  ? Container(
                                    padding: const EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: Color(0xffd6dbdf),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8)
                                      ),
                                    ),
                                    child: const Text(
                                      'Фото оборотной стороны',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FittedBox(
                                      clipBehavior: Clip.antiAlias,
                                      fit: BoxFit.cover,
                                      child: Image.file(File(photoLicenseBackPath!)),
                                    ),
                                  ),
                              )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                icon: const Icon(Icons.done),
                label: const Text('Добавить водителя'),
                style: getTextButtonStyle(),
                onPressed: () {
                  if (addDriverFormKey.currentState!.validate()) {
                    if (photoLicenseFrontPath == null || photoLicenseBackPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Добавьте фотографии водительского удостоверения'),
                        ),
                      );
                      return;
                    }
                    widget.addedDriver!(KaskoDriver(
                      name: nameController.text,
                      birthdate: birthdateController.text,
                      docSeries: docSeriesController.text,
                      docNumber: docNumberController.text,
                      docPhotoPaths: [
                        photoLicenseFrontPath!,
                        photoLicenseBackPath!,
                      ],
                    ));
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

  }
}
