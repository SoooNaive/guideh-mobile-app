import 'package:flutter/material.dart';

import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';

import 'package:guideh/pages/dms/letters_of_guarantee/guarantee_letters_models.dart';
import 'package:guideh/pages/dms/dms_functions.dart';
import 'package:guideh/pages/dms/letters_of_guarantee/guarantee_letters_filter.dart';
import 'package:guideh/theme/theme.dart';


class GuaranteeLettersPage extends StatefulWidget {
  const GuaranteeLettersPage({
    required this.policyId,
    required this.policyNumber,
    super.key
  });

  final String policyId;
  final String policyNumber;

  @override
  State<GuaranteeLettersPage> createState() => _GuaranteeLettersPageState();
}

class _GuaranteeLettersPageState extends State<GuaranteeLettersPage> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
    GlobalKey<RefreshIndicatorState>();

  List<DmsLetter> _list = [];
  late Future<void> _initDataLoad;
  bool _isRefreshing = false;

  Future<List<DmsLetter>> get data async => await _getList();
  Future<void> _initData() async => _list = await _getList();
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final refreshedData = await data;
    setState(() {
      _list = refreshedData;
      _isRefreshing = false;
    });
  }

  bool showActive = true;
  bool showArchive = false;

  updateFilters(Map<String, dynamic> filtersMap) {
    setState(() {
      if (filtersMap['showActive'] != null) {
        showActive = filtersMap['showActive'];
      }
      if (filtersMap['showArchive'] != null) {
        showArchive = filtersMap['showArchive'];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  Widget showData() {
    if (_list.isEmpty) {
      return const Center(child: Text('Нет гарантийных писем'));
    }
    // фильтруем
    late final List<DmsLetter> filteredList;
    if (showActive && showArchive) {
      filteredList = _list;
    } else {
      filteredList = _list.where((item) {
        final isActive = item.isActive;
        return (showActive && isActive) || (showArchive && !isActive);
      }).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15
      ),
      shrinkWrap: true,
      itemCount: filteredList.length,
      itemBuilder: (BuildContext context, int index) {
        final DmsLetter letter = filteredList[index];
        const cardLineStyle = TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          height: 1.4,
        );
        const cardLineValueStyle = TextStyle(fontWeight: FontWeight.normal);
        return Opacity(
          opacity: _isRefreshing ? 0.25 : 1,
          child: Stack(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(5, 3, 5, 10),
                shadowColor: letter.isActive ? Color(0xBB000020) : Color(0x11000020),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 10, 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: Opacity(
                      opacity: letter.isActive ? 1 : (showActive ? 0.4 : 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (letter.isActive) Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.play_circle, color: Colors.green, size: 18),
                                SizedBox(width: 5),
                                Text('Активно', style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: 'Дата обращения: ',
                              style: cardLineStyle,
                              children: [
                                TextSpan(text: letter.date, style: cardLineValueStyle),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: 'ЛПУ: ',
                              style: cardLineStyle,
                              children: [
                                TextSpan(text: letter.lpuName, style: cardLineValueStyle),
                              ],
                            ),
                          ),
                          RichText(
                            softWrap: true,
                            maxLines: 3,
                            overflow: TextOverflow.clip,
                            text: TextSpan(
                              text: 'Тип обращения: ',
                              style: cardLineStyle,
                              children: [
                                TextSpan(text: letter.requestTypeName, style: cardLineValueStyle),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: 'Действие ГП по: ',
                              style: cardLineStyle,
                              children: [
                                TextSpan(text: letter.dateEnd, style: cardLineValueStyle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 8,
                child: MenuAnchor(
                  style: const MenuStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
                        vertical: 4, horizontal: 0
                    )),
                  ),
                  menuChildren: [

                    // [Посмотреть]
                    MenuItemButton(
                      onPressed: () => dmsShowFile(
                        context,
                        'ГарантийноеПисьмо',
                        letter.id,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.description_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Посмотреть'),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // [Скачать ГП]

                    MenuItemButton(
                      onPressed: () => dmsDownloadFile(
                        context,
                        'ГарантийноеПисьмо',
                        letter.id,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 12),
                          Text('Скачать ГП'),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // [Отправить себе]
                    MenuItemButton(
                      onPressed: () => dmsSendDataToEmail(
                        context,
                        'ГарантийноеПисьмо',
                        letter.id,
                        widget.policyId,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.email_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Отправить себе'),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // [Отправить на другой email]
                    MenuItemButton(
                      onPressed: () => dmsShowModalWithEmailInput(
                        context,
                        'ГарантийноеПисьмо',
                        letter.id,
                        widget.policyId,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mail_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Отправить на другой email'),
                        ],
                      ),
                    ),

                  ],
                  builder: (_, MenuController controller, Widget? child) {
                    return IconButton(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: letter.isActive ? primaryColor : Color(0xFF888888),
                        backgroundColor: letter.isActive ? secondaryLightColor : Color(0xFFF0F0F0),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      color: primaryColor,
                      icon: const Icon(Icons.more_vert),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гарантийные письма'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(45),
          child: Container(
            width: double.infinity,
            height: 45,
            color: Color(0xFFE6E9EF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Полис ДМС ${widget.policyNumber}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () async {
                    Map<String, dynamic>? filtersMap = await showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return GuaranteeLettersFilter(
                          showActive: showActive,
                          showArchive: showArchive,
                        );
                      },
                    );
                    if (filtersMap == null) return;
                    updateFilters(filtersMap);
                  },
                  icon: Icon(Icons.checklist),
                  label: Text('Фильтр'),
                  style: TextButton.styleFrom(
                      fixedSize: Size.fromHeight(45),
                      shape: LinearBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 16)
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder(
          future: _initDataLoad,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active: {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text('Загрузка списка'),
                    ],
                  ),
                );
              }
              case ConnectionState.done: {
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshData,
                  child: showData(),
                );
              }
            }
          }
      ),
    );
  }


  Future<List<DmsLetter>> _getList() async {
    bool isError = false;
    List<DmsLetter> letters = [];

    final response = await Http.mobApp(
      ApiParams( 'MobApp', 'MP_ExecuteDMSMethod', {
        'token': await Auth.token,
        'Method': 'MP_GuaranteeLetters',
        'PolisId': widget.policyId,
      })
    );

    try {
      if (response?['Data']?['Error'] != null && response['Data']['Error'] == '3') {
        letters.addAll((response['Data']['GuaranteeLetters'] as List).map((item) {
          return DmsLetter.fromJson(item);
        }));
      }
      else {
        isError = true;
      }
    } catch (e) {
      print(e);
      isError = true;
    }

    if (isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка получения списка гарантийных писем'),
            showCloseIcon: true,
          ),
        );
      }
    }

    return letters;
  }
}
