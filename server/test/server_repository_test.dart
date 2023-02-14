import 'dart:io';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/core/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/core/network/response_data.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:test/test.dart';
import 'helper/test_helpers.dart';

// test for the general server functions

const int _serverPort = 8192;

// every test will be run in a separate process
void main() {
  setUp(() async {
    // will be run for each test!
    await createCommonTestObjects(serverPort: _serverPort); // creates the global test objects.
    // IMPORTANT: this needs a different server port for each test file! (this callback will be run before each test)
  });

  tearDown(() async {
    await cleanupTestFilesAndServer(deleteTestFolderAfterwards: true); // cleanup server and hive test data after every test
    // (this callback will be run after each test)
  });

  group("server repository tests: ", () {
    test("throw a notFound exception on a request to an invalid endpoint", () async {
      expect(
        () async {
          await restClient.sendRequest(
            endpoint: invalidEndpoint,
          );
        },
        throwsA(
            predicate((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.notFound))),
      );
    });
    group("Http request methods without session tokens against the same valid endpoint: ", _testHttpMethods);
    group("Test different requests: ", _testDifferentRequests);
    group("Session token tests: ", _testWithSessionTokens);
  });
}

const Endpoint invalidEndpoint = Endpoint(apiPath: "test/invalid/endpoint", httpMethod: HttpMethod.GET);
const Endpoint exceptionEndpoint = Endpoint(apiPath: "test/exception/endpoint", httpMethod: HttpMethod.GET);
const Endpoint getEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.GET);
const Endpoint postEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.POST);
const Endpoint putEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.PUT);
const Endpoint deleteEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.DELETE);
const Endpoint sessionTokenEndpoint =
    Endpoint(apiPath: "test/sessionToken/endpoint", httpMethod: HttpMethod.POST, needsSessionToken: true);
const Endpoint differentTestsEndpoint = Endpoint(apiPath: "test/different/tests/endpoint", httpMethod: HttpMethod.POST);

final ServerAccountModel validAccount = ServerAccountModel(
    userName: "validAccount",
    passwordHash: "validPassword",
    sessionToken: SessionTokenModel(token: "validToken", validTo: DateTime.now()),
    noteInfoList: const <NoteInfo>[],
    encryptedDataKey: "validKey");

/// Helper method to add the 4 http method callbacks for the same endpoint
void initHttpMethodEndpoints() {
  restServer.addCallback(endpoint: getEndpoint, callback: _returnJsonRequest);
  restServer.addCallback(endpoint: postEndpoint, callback: _returnJsonRequest);
  restServer.addCallback(endpoint: putEndpoint, callback: _returnJsonRequest);
  restServer.addCallback(endpoint: deleteEndpoint, callback: _returnJsonRequest);
}

/// Adds a callback for the [sessionTokenEndpoint] and also overrides the [restServer.authenticationCallbackOverride] to
/// match the [validAccount]
void initSessionTokenEndpoint() {
  restServer.authenticationCallbackOverride = (String sessionToken) async {
    if (validAccount.containsSessionToken(sessionToken)) {
      return validAccount;
    }
    return null;
  };
  restServer.addCallback(
      endpoint: sessionTokenEndpoint,
      callback: (_) => RestCallbackResult(jsonResult: <String, dynamic>{"test": validAccount.userName}));
}

/// helper method that returns either the requests body data, or the query parameter as a json map for the response
/// depending if the body data is null, or not.
///
/// Will also check if the request body data was send as json if data was send.
RestCallbackResult _returnJsonRequest(RestCallbackParams params) {
  if (params.data != null) {
    expect(params.requestHeaders[HttpHeaders.contentTypeHeader], ContentType.json.toString(),
        reason: "content type header of client request should also be json");
  }
  return RestCallbackResult(jsonResult: params.jsonBody ?? params.queryParams);
}

void _testHttpMethods() {
  test("get request should return the same query params with json content type header", () async {
    initHttpMethodEndpoints();
    final ResponseData response = await restClient.sendRequest(
      endpoint: getEndpoint,
      queryParams: <String, String>{"test": "test"},
    );
    expect(response.json!["test"], "test", reason: "body params should be equal");
    expect(response.responseHeaders[HttpHeaders.contentTypeHeader], ContentType.json.toString(),
        reason: "content type header should be json");
  });

  test("post request should return the same body params with json content type header", () async {
    initHttpMethodEndpoints();
    final ResponseData response = await restClient.sendRequest(
      endpoint: postEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
      bodyData: <String, dynamic>{"test": "test"},
    );
    expect(response.json!["test"], "test", reason: "body params should be equal");
    expect(response.responseHeaders[HttpHeaders.contentTypeHeader], ContentType.json.toString(),
        reason: "content type header should be json");
  });

  test("post request should also return the same body params when using sendJsonRequest ", () async {
    initHttpMethodEndpoints();
    final Map<String, dynamic> json = await restClient.sendJsonRequest(
      endpoint: postEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
      bodyData: <String, dynamic>{"test": "test"},
    );
    expect(json["test"], "test", reason: "body params should be equal");
  });

  test("put request should return the same body params with json content type header", () async {
    initHttpMethodEndpoints();
    final ResponseData response = await restClient.sendRequest(
      endpoint: putEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
      bodyData: <String, dynamic>{"test": "test"},
    );
    expect(response.json!["test"], "test", reason: "body params should be equal");
    expect(response.responseHeaders[HttpHeaders.contentTypeHeader], ContentType.json.toString(),
        reason: "content type header should be json");
  });

  test("delete request should return the same body params with json content type header", () async {
    initHttpMethodEndpoints();
    final ResponseData response = await restClient.sendRequest(
      endpoint: deleteEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
      bodyData: <String, dynamic>{"test": "test"},
    );
    expect(response.json!["test"], "test", reason: "body params should be equal");
    expect(response.responseHeaders[HttpHeaders.contentTypeHeader], ContentType.json.toString(),
        reason: "content type header should be json");
  });

  test("a get request with body data should throw an exception", () async {
    initHttpMethodEndpoints();
    expect(
      () async {
        await restClient.sendRequest(
          endpoint: getEndpoint,
          queryParams: <String, String>{"valid": "valid"},
          bodyData: <String, dynamic>{"error": "error"},
        );
      },
      throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.INVALID_DATA_TYPE)),
    );
  });

  test("post request should also work without body data", () async {
    initHttpMethodEndpoints();
    final Map<String, dynamic> response = await restClient.sendJsonRequest(
      endpoint: postEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
    );
    expect(response["ignored"], "ignored");
  });

  test("post request should also work without body data with a direct request", () async {
    initHttpMethodEndpoints();
    final ResponseData response = await restClient.sendRequest(
      endpoint: postEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
    );
    expect(response.json!["ignored"], "ignored");
  });

  test("put request should also work without body data", () async {
    initHttpMethodEndpoints();
    final Map<String, dynamic> response = await restClient.sendJsonRequest(
      endpoint: putEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
    );
    expect(response["ignored"], "ignored");
  });

  test("delete request should also work without body data", () async {
    initHttpMethodEndpoints();
    final Map<String, dynamic> response = await restClient.sendJsonRequest(
      endpoint: deleteEndpoint,
      queryParams: <String, String>{"ignored": "ignored"},
    );
    expect(response["ignored"], "ignored");
  });
}

void _testDifferentRequests() {
  test("execute a normal get request with no needed session token to the valid real ABOUT endpoint", () async {
    final Map<String, dynamic> response = await restClient.sendJsonRequest(
      endpoint: Endpoints.ABOUT,
    );
    expect(response[RestJsonParameter.NOTA_ABOUT], predicate((Object e) => e is String && e.isNotEmpty));
  });

  test("throw a badRequest exception on a request to an endpoint callback that throws an exception", () async {
    restServer.addCallback(endpoint: exceptionEndpoint, callback: (_) => throw const BaseException(message: ""));
    expect(
      () async {
        await restClient.sendRequest(
          endpoint: exceptionEndpoint,
        );
      },
      throwsA(
          predicate((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.badRequest))),
    );
  });

  test("throw an invalid data type exception on a client request with an invalid data type ", () async {
    expect(
      () async {
        await restClient.sendRequest(endpoint: postEndpoint, bodyData: 11111);
      },
      throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.INVALID_DATA_TYPE)),
    );
  });

  test("post binary data which should be returned and have the correct headers set", () async {
    final List<int> clientBytes = StringUtils.getRandomBytes(1000000);
    final List<int> serverBytes = StringUtils.getRandomBytes(1000000);

    restServer.addCallback(
        endpoint: differentTestsEndpoint,
        callback: (RestCallbackParams params) {
          expect(clientBytes, params.data, reason: "The request should contain the client bytes");
          expect(params.jsonBody, null, reason: "Json client request should be empty");
          expect(params.requestHeaders[HttpHeaders.contentTypeHeader], ContentType.binary.toString(),
              reason: "content type header should be binary");
          return RestCallbackResult(rawBytes: serverBytes);
        });

    final ResponseData responseData = await restClient.sendRequest(endpoint: differentTestsEndpoint, bodyData: clientBytes);
    expect(serverBytes, responseData.bytes, reason: "The response should contain the server bytes");
    expect(responseData.json, null, reason: "Json server response should be empty");
    expect(responseData.responseHeaders[HttpHeaders.contentTypeHeader], ContentType.binary.toString(),
        reason: "content type header should be binary");
  });

  test("encoding the binary data in json and testing the other way around", () async {
    final String clientBytes = StringUtils.getRandomBytesAsBase64String(40);
    final String serverBytes = StringUtils.getRandomBytesAsBase64String(40);

    restServer.addCallback(
        endpoint: differentTestsEndpoint,
        callback: (RestCallbackParams params) {
          expect(clientBytes, params.jsonBody!["bytes"], reason: "The request should contain the client json");
          expect(params.rawBytes, null, reason: "Byte client request should be empty");
          return RestCallbackResult(jsonResult: <String, String>{"bytes": serverBytes});
        });

    final ResponseData responseData =
        await restClient.sendRequest(endpoint: differentTestsEndpoint, bodyData: <String, dynamic>{"bytes": clientBytes});
    expect(serverBytes, responseData.json!["bytes"], reason: "The response should contain the server json");
    expect(responseData.bytes, null, reason: "Json server response should be empty");
  });
}

void _testWithSessionTokens() {
  test("a post request with a correct session token should get the valid accounts username", () async {
    initSessionTokenEndpoint();
    sessionServiceMock.sessionTokenOverride = validAccount.sessionToken!.token;
    final Map<String, dynamic> response = await restClient.sendJsonRequest(
      endpoint: sessionTokenEndpoint,
    );
    expect(response["test"], validAccount.userName);
  });

  test("a post request with an empty session token should throw an unauthorized exception", () async {
    initSessionTokenEndpoint();
    sessionServiceMock.sessionTokenOverride = "";
    expect(
      () async {
        await restClient.sendRequest(
          endpoint: sessionTokenEndpoint,
        );
      },
      throwsA(
          predicate((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized))),
    );
  });

  test("a post request with an invalid session token should throw an unauthorized exception", () async {
    initSessionTokenEndpoint();
    sessionServiceMock.sessionTokenOverride = "invalidSessionToken";
    expect(
      () async {
        await restClient.sendRequest(
          endpoint: sessionTokenEndpoint,
        );
      },
      throwsA(
          predicate((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized))),
    );
  });
}
