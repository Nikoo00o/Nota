# Nota

## Overview 
- A Cross-Platform Note-Taking App 
- This project contains the sub projects **shared**, **server** and **app**. 


## Building The Project

- just import the project in android studio and have flutter and dart installed
- then edit the config like explained below
- and afterwards you can use the run configurations to start the app and the server

## Config

- you have to run the run configuration "Create New Keys" at least once, because it will create the "sensitive_data.dart" 
  files with new random salts and keys
  - then you have to set the server hostname in `/shared/lib/core/config/sensitive_data.dart`
- you also have to add a RSA private key named `key.pem` and the matching certificate named `certificate.pem`in the 
  folder `server/notaRes` for debug mode, or just in a data folder next to the server exe in release mode
    - if your private key is password protected, you can pass the password to the server exe as a command line argument 
      with `-r "password"`, or `--rsaPassword="password"`

### Creating a Self-Signed OpenSSL Certificate and Private Key

- first install openssl 
- then open a terminal and navigate to the folder `server/notaRes`
- now enter the command `openssl req -x509 -sha256 -nodes -days 36500 -newkey rsa:4096 -keyout key.pem -out 
  certificate.pem`
- always enter `.` except for the common name, where you can enter anything you want 

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

## The Different Projects

### Server

- contains the server specific code (dart project)
- in the scope of the whole project and in relation to the app, the server is mostly written in the data layer without 
  many use cases

### Shared

- contains the shared code used in server and app (dart project)

### App

- contains the app specific code (flutter project)

