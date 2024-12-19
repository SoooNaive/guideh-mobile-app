import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/branch.dart';


class ApiData {

  Future<List<Branch>> getBranches() async {
    var request = http.Request('GET', Uri.parse('https://guidehins.ru/php/mobileApp/contacts.php'));
    http.StreamedResponse
    response = await request.send();
    var responseString = await response.stream.bytesToString();
    final jsonData = json.decode(responseString);

    List<Branch> contacts = [];
    int i = 0;
    for (var item in jsonData) {
      i++;
      Branch contact = Branch(
        index: i,
        id: item["id_branch"],
        cityId: item["idcity_branch"],
        cityName: item["namecity_branch"],
        name: item["city_branch"],
        address: item["address_branch"],
        phone: item["phone_branch"],
        timeWorkdays: item["mon_fri_time_branch"],
        timeBreak: item["break_time_branch"],
        timeSaturday: item["sat_time_branch"],
        timeSunday: item["sun_time_branch"],
        email: item["email_branch"],
        type: item["type_branch"],
        note: item["note_branch"],
        xCoordinates: item["x_coordinates_branch"],
        yCoordinates: item["y_coordinates_branch"]
      );
      contacts.add(contact);
    }
    return contacts;
  }

}