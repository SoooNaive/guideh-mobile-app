part of 'checkup_kasko_bloc.dart';

@immutable
class CheckupKaskoState {
  final List<CheckupKaskoPhoto> casePhotos;
  final List<CheckupKaskoPhoto> carPhotos;
  final List<CheckupKaskoPhoto> damagePhotos;
  final List<CheckupKaskoPhoto> extraPhotos;
  final bool loadingPhotoDone;
  const CheckupKaskoState({
    this.casePhotos = const <CheckupKaskoPhoto>[],
    this.carPhotos = const <CheckupKaskoPhoto>[],
    this.damagePhotos = const <CheckupKaskoPhoto>[],
    this.extraPhotos = const <CheckupKaskoPhoto>[],
    this.loadingPhotoDone = false,
  });

  // сбросим loadingPhotoDone
  CheckupKaskoState resetPhotoDone() {
    return CheckupKaskoState(
      casePhotos: casePhotos,
      carPhotos: carPhotos,
      damagePhotos: damagePhotos,
      extraPhotos: extraPhotos,
      loadingPhotoDone: false,
    );
  }

  // храним фотки из кейса
  Future<CheckupKaskoState> copyWithCasePhotos(List<CheckupKaskoPhoto> photos) async {
    return CheckupKaskoState(casePhotos: photos);
  }

  // добавляем фотку в bloc
  Future<CheckupKaskoState> copyWithPhoto(CheckupKaskoPhoto photo, String stepName) async {

    List<CheckupKaskoPhoto> stepPhotos =
      stepName == 'car_photos'
        ? carPhotos
        : stepName == 'damage_photos'
          ? damagePhotos
          : extraPhotos;

    // удаляем фотку, если уже есть с таким типом
    final int alreadyHasPhotoIndex = stepPhotos.indexWhere((oldPhoto) {
      return oldPhoto.type == photo.type;
    });
    if (alreadyHasPhotoIndex >= 0) {
      stepPhotos.removeAt(alreadyHasPhotoIndex);
    }

    List<CheckupKaskoPhoto> newPhotos = [...stepPhotos, photo];

    return stepName == 'car_photos'
      ? CheckupKaskoState(
        casePhotos: casePhotos,
        carPhotos: newPhotos,
        damagePhotos: damagePhotos,
        extraPhotos: extraPhotos,
        loadingPhotoDone: true,
      )
      : stepName == 'damage_photos'
        ? CheckupKaskoState(
          casePhotos: casePhotos,
          carPhotos: carPhotos,
          damagePhotos: newPhotos,
          extraPhotos: extraPhotos,
          loadingPhotoDone: true,
        )
        : CheckupKaskoState(
          casePhotos: casePhotos,
          carPhotos: carPhotos,
          damagePhotos: damagePhotos,
          extraPhotos: newPhotos,
          loadingPhotoDone: true,
        );
  }

}

class CheckupKaskoInitial extends CheckupKaskoState {}
