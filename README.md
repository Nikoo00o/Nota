# Nota

## About the App
- Nota is a Cross-Platform Note-Taking App designed to work both offline locally, or synchronized with a server across 
  all devices 
- the users notes will be securely encrypted and the server stores them, but can't decrypt them
- the notes can be accessed in a folder like structure
- currently the app is still in development

## Using The App

## Technical Details on building the projects 

- just import the project in android studio and have the flutter and dart sdks installed and the android studio flutter 
  plugin
  - instead of android studio, you can also use visual studio code with the flutter plugin
- **first run** `dart pub get` inside of each subfolder "shared", "server" and "app"! 
- **then edit the config** like explained [below](#configure-the-projects)
- and afterwards you can use the run configurations in android studio to start the app and the server in debug mode
- This project contains the sub projects **shared**, **server** and **app**

### Building Release Versions 

- when building the release version, you should set the `acceptSelfSignedCertificates` config option to `false` inside of 
  the app and use a trusted tls/ssl certificate instead of a self signed certificate!

#### Server

```
dart compile exe server/lib/main.dart
```

- of course the trusted tls/ssl certificates have to be put into a folder named "notaRes" which has to be put next to the 
  exe!

#### App 

- first navigate into the `nota/app`folder and then use one of the following depending on the platform

```
flutter build windows --release 
flutter build linux --release       
flutter build apk --release           # android 
flutter build ipa --release           # ios 
```


### Configure the projects

- you have to run the run configuration "Create New Keys" at least once, because it will create the "sensitive_data.dart" 
  files with new random salts and keys
  - then you have to set the server hostname in `/shared/lib/core/config/sensitive_data.dart`
- you also have to add a RSA private key named `key.pem` and the matching certificate named `certificate.pem`in the 
  folder `nota/server/notaRes` for debug mode, or inside of a folder named `data` next to the server exe in release mode
    - if your private key is password protected, you can pass the password to the server exe as a command line argument 
      with `-r "password"`, or `--rsaPassword="password"`
- you can also adjust the log level with `-l "number"`, or `--loglevel="number"` where the number can be 0 for errors 
  only, 1 for warning, 2 for info, 3 for debug and 4 for verbose

### Creating a Self-Signed OpenSSL Certificate and Private Key

- first install openssl 
- then open a terminal and navigate to the folder `server/notaRes`
- now enter the command `openssl req -x509 -sha256 -nodes -days 36500 -newkey rsa:4096 -keyout key.pem -out 
  certificate.pem`
- always enter `.` except for the common name, where you can enter anything you want

### Project Structure

#### Server

- contains the server specific code (dart project)
- in the scope of the whole project and in relation to the app, the server is mostly written in the data layer without 
  many use cases
- the server will be build as a command line tool with no gui

#### Shared

- contains the shared code used in server and app (dart project) and should not be used on its own
- this also contains a shared config and shared sensitive data for both projects

#### App

- contains the app specific code (flutter project) written with the "clean architecture"
- this will build the final app for the device with the gui that the user interacts with

### Testing

- some of the server tests can fail on a slow processor, because of some time critical operations
- if this happens, just increase the delays inside of the affected tests

### Server

- navigate to the `nota/server` folder with the terminal and run `dart test`, or just start the "All Server Tests" run
  configuration
- the default log level for the tests can be changed inside of the file `nota/server/test/helper/server_test_helper.dart` in
  the method `createCommonTestObjects`

### App

- navigate to the `nota/app` folder with the terminal and run `flutter test`, or just start the "All App Tests" run
  configuration
- the tests of the app also directly use the server tests for the real server responses instead of mocks!
  - because of this, the app tests also don't have to care about the server errors, because they are already tested in
    the server tests
- the default log level for the tests can be changed inside of the file `nota/app/test/helper/app_test_helper.dart` in 
the method `createCommonTestObjects`

<!--- // todo: screenshots of the app should follow here -->