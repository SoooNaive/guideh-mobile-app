import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:guideh/pages/checkup_kasko/photo_model.dart';

part 'checkup_kasko_event.dart';
part 'checkup_kasko_state.dart';

class CheckupKaskoBloc extends Bloc<CheckupKaskoEvent, CheckupKaskoState> {
  CheckupKaskoBloc() : super(CheckupKaskoInitial()) {
    on<CheckupKaskoResetPhotoDone>(_onResetPhotoDone);
    on<CheckupKaskoAddCasePhotos>(_onAddCasePhotos);
    on<CheckupKaskoAddCarPhoto>(_onAddCarPhoto);
    on<CheckupKaskoAddDamagePhoto>(_onAddDamagePhoto);
    on<CheckupKaskoAddExtraPhoto>(_onAddExtraPhoto);
  }

  _onResetPhotoDone(CheckupKaskoResetPhotoDone event, Emitter<CheckupKaskoState> emit) {
    emit(state.resetPhotoDone());
  }
  _onAddCasePhotos(CheckupKaskoAddCasePhotos event, Emitter<CheckupKaskoState> emit) async {
    emit(await state.copyWithCasePhotos(event.photos));
  }
  _onAddCarPhoto(CheckupKaskoAddCarPhoto event, Emitter<CheckupKaskoState> emit) async {
    emit(await state.copyWithPhoto(event.photo, 'car_photos'));
  }
  _onAddDamagePhoto(CheckupKaskoAddDamagePhoto event, Emitter<CheckupKaskoState> emit) async {
    emit(await state.copyWithPhoto(event.photo, 'damage_photos'));
  }
  _onAddExtraPhoto(CheckupKaskoAddExtraPhoto event, Emitter<CheckupKaskoState> emit) async {
    emit(await state.copyWithPhoto(event.photo, 'extra_photos'));
  }

}
