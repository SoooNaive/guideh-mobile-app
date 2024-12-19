import 'branch.dart';

class BranchCity {
  BranchCity({
    required this.index,
    required this.id,
    required this.name,
    this.isExpanded = false,
    required this.branches,
  });

  int index;
  String id;
  String name;
  bool isExpanded;
  List<Branch> branches;
}