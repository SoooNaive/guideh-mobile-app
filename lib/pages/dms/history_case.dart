import 'package:flutter/material.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';


class HistoryCase extends StatefulWidget {
  final String historyCaseId;

  const HistoryCase({super.key, required this.historyCaseId});

  @override
  State<HistoryCase> createState() => _HistoryCaseState();
}

class _HistoryCaseState extends State<HistoryCase> {
  late Map<String, dynamic>? item;

  Future<void> _loadHistoryCase() async {
    bool isError = false;

    final response = await Http.mobApp(
      ApiParams( 'MobApp', 'MP_ExecuteDMSMethod', {
        'token': await Auth.token,
        'Method': 'MP_DoctorRequestView',
        'DoctorRequestId': widget.historyCaseId,
      })
    );
    try {
      if (response?['Error'] == 0 && response['Data']['Error'] == '3') {
        item = response['Data'];
      }
      else {
        isError = true;
      }
    } catch (e) {
      print(e);
      isError = true;
    }

    if (isError) {
      item = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка получения информации об обращении'),
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обращение'),
      ),
      body: FutureBuilder(
        future: _loadHistoryCase(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active: {
              return const Center(child: CircularProgressIndicator());
            }
            case ConnectionState.done: {
              if (item == null) return Center(child: Text('Ошибка'));

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                
                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Желательная дата',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      initialValue: item!['Date'],
                      readOnly: true,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Желательное время',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      maxLines: 4,
                      minLines: 1,
                      initialValue: item!['Time'],
                      readOnly: true,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'ЛПУ',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                        helperText: ((item!['LPUId'] ?? '') != '')
                            ? item!['LPUAddress'] : null,
                        helperMaxLines: 3,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      initialValue: ((item!['LPUId'] ?? '') != '')
                          ? item!['LPUName'] : 'не указано',
                      readOnly: true,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Вид обращения',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      maxLines: 4,
                      minLines: 1,
                      initialValue: item!['DmsLetterRequestCountTypeName'],
                      readOnly: true,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Тип обращения',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      maxLines: 4,
                      minLines: 1,
                      initialValue: item!['DmsLetterRequestTypeName'],
                      readOnly: true,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Тип обратной связи',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      maxLines: 4,
                      minLines: 1,
                      initialValue: item!['DmsLetterContactTypeName'],
                      readOnly: true,
                    ),

                    if (item!['DmsLetterContactTypeCode'] != null && item!['DmsLetterContactTypeCode'] != '02') Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Контакт',
                          labelStyle: TextStyle(color: Color(0xFF999999)),
                          counterText: '',
                        ),
                        maxLines: 4,
                        minLines: 1,
                        initialValue: item!['Email'] ?? ((item!['Phone'] ?? '') != '') ? '+7${item!['Phone']}' : '',
                        readOnly: true,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Комментарий',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        counterText: '',
                      ),
                      maxLines: 10,
                      minLines: 1,
                      initialValue: item!['Description'],
                      readOnly: true,
                    ),

                    const SizedBox(height: 20),

                    Text('Файлы', textAlign: TextAlign.start, style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    )),

                    if ((item!['Files'] as List).isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: filesBuilder(item!['Files']),
                    ),

                    if ((item!['Files'] as List).isEmpty) Text('нет файлов', style: TextStyle(
                      fontSize: 16,
                      height: 1.7
                    )),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget filesBuilder(files) => ListView.builder(
    itemCount: files.length,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) => _buildFileItem(files[index]),
  );

  Widget _buildFileItem(Map<String, dynamic> file) {
    final fileName = file['FileName'];
    final fileExtension = fileName.split('.').last.toLowerCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Миниатюра изображения или расширение файла
        Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(right: 10, top: 3, bottom: 3),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Center(
            child: Text(
              fileExtension.toUpperCase(),
              style: TextStyle(color: Color(0xFF444444), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Название файла
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

}
