import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guideh/pages/dms/models/lpu.dart';
import 'package:guideh/pages/dms/models/lpu_risk.dart';

class DmsLpuListSearch extends StatefulWidget {
  final List<DmsLpuRisk> lpuRiskList;
  final int lpuCount;
  final Function(List<DmsLpuRisk>? list) updateRiskListFiltered;
  const DmsLpuListSearch({
    super.key,
    required this.lpuRiskList,
    required this.lpuCount,
    required this.updateRiskListFiltered,
  });

  @override
  State<DmsLpuListSearch> createState() => _DmsLpuListSearchState();
}

class _DmsLpuListSearchState extends State<DmsLpuListSearch> {

  bool listIsFiltered = false;
  final TextEditingController _controllerSearchLpu = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoSearchTextField(
          controller: _controllerSearchLpu,
          placeholder: 'Поиск ЛПУ',
          padding: const EdgeInsets.all(10),
          prefixInsets: const EdgeInsets.fromLTRB(8, 4, 0, 3),
          onChanged: (value) {
            if (value.length < 3) {
              if (listIsFiltered) {
                setState(() => listIsFiltered = false);
                widget.updateRiskListFiltered(null);
              }
              setState(() { });
              return;
            }
            final querySearch = value.toLowerCase().trim();
            final List<DmsLpuRisk> result = widget.lpuRiskList.map((risk) {
              return DmsLpuRisk(
                  risk.risk,
                  risk.lpu.where((DmsLpu lpu) {
                    final name = lpu.name.toLowerCase();
                    final address = lpu.address.toLowerCase();
                    return name.contains(querySearch) || address.contains(querySearch);
                  }).toList()
              );
            })
                .where((risk) => risk.lpu.isNotEmpty)
                .toList();
            setState(() => listIsFiltered = true);
            widget.updateRiskListFiltered(result);
          },
        ),
        const SizedBox(height: 5),
        Text(
            _controllerSearchLpu.text.isNotEmpty && _controllerSearchLpu.text.length < 3
                ? 'Введите минимум 3 символа'
                : (widget.lpuCount > 0 ? 'Найдено: ${widget.lpuCount}' : 'Не найдено'),
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey
            )
        ),
      ],
    );
  }

}
