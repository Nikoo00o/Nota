import "../../server/test/helper/test_helpers.dart" as server;

// todo: in the future also use the server tests here to respond to the actions of the app code. rename the file then, but
//  keep the relative import

// add comment: server tests should be run before, because this test here does not mock the server. it uses the real server
// implementation!

void main() {
  server.createCommonTestObjects(serverPort: 8900); // use this and the cleanup method in the tests to control the server
}
