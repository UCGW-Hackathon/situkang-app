# situkang_app

SITUKANG - Flutter marketplace connecting Users with Workers/Tukang for home
repair services.

## Safe Setup

This project is locked to the dependency versions in `pubspec.lock`. Use the
lockfile when installing packages so a fresh clone does not drift into
dependency conflicts.

Required toolchain:

- Flutter `3.44.1` recommended
- Dart `>=3.11.1 <4.0.0`

On Windows, run:

```powershell
.\tool\safe_pub_get.ps1
```

That script checks the local Dart SDK before installing packages, then runs:

```powershell
flutter pub get --enforce-lockfile
```

If you use FVM:

```powershell
dart pub global activate fvm
fvm install 3.44.1
fvm use 3.44.1
fvm flutter pub get --enforce-lockfile
```

Only update dependency versions intentionally:

```powershell
flutter pub outdated
flutter pub upgrade
```

After a deliberate upgrade, commit both `pubspec.yaml` and `pubspec.lock`.
