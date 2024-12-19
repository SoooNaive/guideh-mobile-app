import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

part 'scaffold_event.dart';
part 'scaffold_state.dart';

class ScaffoldBloc extends Bloc<ScaffoldEvent, ScaffoldState> {
  ScaffoldBloc() : super(ScaffoldInitial()) {
    on<ScaffoldGoToTabEvent>(_onGoToTab);
    on<ScaffoldUpdateNotificationsPermissionStatusEvent>(_onUpdateNotificationsPermissionStatus);
  }

  _onGoToTab(ScaffoldGoToTabEvent event, Emitter<ScaffoldState> emit) {
    emit(state.copyWith(event.selectedTabIndex));
  }

  _onUpdateNotificationsPermissionStatus(
      ScaffoldUpdateNotificationsPermissionStatusEvent event,
      Emitter<ScaffoldState> emit
      ) async {
    emit(await state.updateNotificationsPermissionStatus(
        event.notificationsPermissionStatus
    ));
  }

}
