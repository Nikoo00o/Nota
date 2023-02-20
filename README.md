# Nota

## About the App
- Nota is a Cross-Platform Note-Taking App designed to work both offline locally, or synchronized with a server across 
  all devices 
- The users notes will be securely encrypted and the server stores them, but can't decrypt them
- Currently the app is still in development

## Building The Project

- just import the project in android studio and have flutter and dart installed
- then edit the config like explained below
- and afterwards you can use the run configurations in android studio to start the app and the server in debug mode
- This project contains the sub projects **shared**, **server** and **app**

### Building Release Versions 

#### Server

```
dart compile exe server/lib/main.dart
```

#### App 

- first navigate into the `nota/app`folder and then use one of the following depending on the platform

```
flutter build windows --release 
flutter build linux --release       
flutter build apk --release           # android 
flutter build ipa --release           # ios 
```


## Config

- you have to run the run configuration "Create New Keys" at least once, because it will create the "sensitive_data.dart" 
  files with new random salts and keys
  - then you have to set the server hostname in `/shared/lib/core/config/sensitive_data.dart`
- you also have to add a RSA private key named `key.pem` and the matching certificate named `certificate.pem`in the 
  folder `nota/server/notaRes` for debug mode, or inside of a folder named `data` next to the server exe in release mode
    - if your private key is password protected, you can pass the password to the server exe as a command line argument 
      with `-r "password"`, or `--rsaPassword="password"`

### Creating a Self-Signed OpenSSL Certificate and Private Key

- first install openssl 
- then open a terminal and navigate to the folder `server/notaRes`
- now enter the command `openssl req -x509 -sha256 -nodes -days 36500 -newkey rsa:4096 -keyout key.pem -out 
  certificate.pem`
- always enter `.` except for the common name, where you can enter anything you want

## The Different Projects

### Server

- contains the server specific code (dart project)
- in the scope of the whole project and in relation to the app, the server is mostly written in the data layer without 
  many use cases
- the server will be build as a command line tool with no gui

### Shared

- contains the shared code used in server and app (dart project) and should not be used on its own

### App

- contains the app specific code (flutter project) 
- this will build the final app for the device with the gui that the user interacts with

## Testing

- some of the server tests can fail on a slow processor, because of some time critical operations
- if this happens, just increase the delays inside of the affected tests

### Server

- navigate to the `nota/server` folder with the terminal and run `dart test`, or just start the "All Server Tests" run
  configuration

### App

- navigate to the `nota/app` folder with the terminal and run `flutter test`, or just start the "All App Tests" run
  configuration
- the tests of the app also directly use the server tests for the real server responses instead of mocks!
  - because of this, the app tests also don't have to care about the server errors, because they are already tested in
    the server tests

# todo: screenshots of the app should follow here