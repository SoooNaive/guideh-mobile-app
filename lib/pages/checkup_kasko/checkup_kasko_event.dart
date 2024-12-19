part of 'checkup_kasko_bloc.dart';

@immutable
abstract class CheckupKaskoEvent {}

class CheckupKaskoResetPhotoDone extends CheckupKaskoEvent {
  CheckupKaskoResetPhotoDone();
}

class CheckupKaskoAddCasePhotos extends CheckupKaskoEvent {
  final List<CheckupKaskoPhoto> photos;
  CheckupKaskoAddCasePhotos(this.photos);
}

class CheckupKaskoAddCarPhoto extends CheckupKaskoEvent {
  final CheckupKaskoPhoto photo;
  CheckupKaskoAddCarPhoto(this.photo);
}

class CheckupKaskoAddDamagePhoto extends CheckupKaskoEvent {
  final CheckupKaskoPhoto photo;
  CheckupKaskoAddDamagePhoto(this.photo);
}

class CheckupKaskoAddExtraPhoto extends CheckupKaskoEvent {
  final CheckupKaskoPhoto photo;
  CheckupKaskoAddExtraPhoto(this.photo);
}
