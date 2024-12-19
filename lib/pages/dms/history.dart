import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';
import 'package:intl/intl.dart';


class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История обращений'), //police.DocNumber
      ),
      body: FutureBuilder(
        future: getDmsRequestHistory(context),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Загрузка истории'),
                ],
              ),
            );
          }
          else {
            if (snapshot.data.length == 0) {
              return const Center(
                child: Text('Обращений не было'),
              );
            }
            return ListView.separated(
              separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                final DmsRequestHistoryItem item = snapshot.data[index];
                return ListTile(
                  title: Text(item.service),
                  contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Номер полиса: ${item.polisNumber}'),
                      Text('Дата: ${item.date.substring(0, 10)}'),
                    ],
                  ),
                  trailing: Text(item.status),
                  onTap: () => context.goNamed('history_case', queryParameters: {
                    'history_case_id': item.id,
                  }),
                );
              },
            );
          }
        }
      ),
    );
  }
}


Future<List> getDmsRequestHistory(BuildContext context) async {
  final response = await Http.mobApp(
    ApiParams('MobApp', 'MP_dms_doctor_req_list', { 'token': await Auth.token })
  );
  if (response['Error'] == 2) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['Message'] ?? 'Ошибка'),
        ),
      );
    }
    return [];
  }
  else if (response['Error'] == 1) {
    if (context.mounted) {
      Auth.logout(context, true);
    }
    return [];
  }
  else if (response['Error'] == 0) {
    return (response['Data'] as List).map((json) {
      return DmsRequestHistoryItem.formJson(json);
    }).toList();
  }
  else {
    return [];
  }
}

class DmsRequestHistoryItem {
  final String id;
  final String date;
  final String polisNumber;
  final String service;
  final String status;

  factory DmsRequestHistoryItem.formJson(Map<String, dynamic> json) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    return DmsRequestHistoryItem(
      id: json['DoctorRequestId'] as String,
      date: DateFormat('dd.MM.yyyy').format(dateFormat.parse(json['Date'])),
      polisNumber: json['Polis'] as String,
      service: json['Service'] as String,
      status: json['Status'] as String,
    );
  }

  DmsRequestHistoryItem({
    required this.id,
    required this.date,
    required this.polisNumber,
    required this.service,
    required this.status,
  });
}
