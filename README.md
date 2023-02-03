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
  - then have to set the server hostname in `/shared/lib/core/config/sensitive_data.dart`
- you also have to add a RSA private key named `key.pem` and the matching certificate named `certificate.pem`in the 
  folder `server/data` for debug mode, or just in a data folder next to the server exe in release mode
    - if your private key is password protected, you can pass the password to the server exe as a command line argument 
      with `-r "password"`, or `--rsaPassword="password"`

#### Creating a Self-Signed OpenSSL Certificate and Private Key

- first install openssl 
- then open a terminal and navigate to the folder `server/data`
- now enter the command `openssl req -x509 -sha256 -nodes -days 36500 -newkey rsa:2048 -keyout key.pem -out 
  certificate.pem`
- always enter `.` except for the common name, where you can enter anything you want 

## Server
...

## Shared
...

## App
...

