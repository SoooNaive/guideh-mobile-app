part of 'scaffold_bloc.dart';

@immutable
class ScaffoldState {
  final int selectedTabIndex;
  final PermissionStatus notificationsPermissionStatus;
  final PageController pageController = PageController(initialPage: 0);

  ScaffoldState({
    this.selectedTabIndex = 0,
    this.notificationsPermissionStatus = PermissionStatus.denied,
  });

  ScaffoldState copyWith(int selectedTabIndex) {
    pageController.jumpToPage(selectedTabIndex);
    return ScaffoldState(
      selectedTabIndex: selectedTabIndex,
      notificationsPermissionStatus: notificationsPermissionStatus,
    );
  }

  Future<ScaffoldState> updateNotificationsPermissionStatus(
      PermissionStatus status
      ) async {
    return ScaffoldState(
      selectedTabIndex: selectedTabIndex,
      notificationsPermissionStatus: status,
    );
  }

}

class ScaffoldInitial extends ScaffoldState {}
