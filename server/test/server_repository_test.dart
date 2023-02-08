import 'dart:io';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/core/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:test/test.dart';
import 'helper/test_helpers.dart';

// test for the general server functions
const int _serverPort = 8192;

// every test will be run in a separate process
void main() {
  Logger.initLogger(Logger()); // should always be the first call in every test

  setUp(() async {
    // will be run for each test!
    await createCommonTestObjects(serverPort: _serverPort); // use global test objects. needs a different server port for
    // each test file!!!

    await initTestHiveAndServer(serverRepository, serverConfigMock); // init hive test data and also start server for
    // each test (this callback will be run before each test)
  });

  tearDown(() async {
    await cleanupTestHiveAndServer(serverRepository, serverConfigMock); // cleanup server and hive test data after every
    // test (this callback will be run after each test)
  });

  const Endpoint invalidEndpoint = Endpoint(apiPath: "test/invalid/endpoint", httpMethod: HttpMethod.GET);
  const Endpoint exceptionEndpoint = Endpoint(apiPath: "test/exception/endpoint", httpMethod: HttpMethod.GET);
  const Endpoint getEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.GET);
  const Endpoint postEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.POST);
  const Endpoint putEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.PUT);
  const Endpoint deleteEndpoint = Endpoint(apiPath: "test/method/endpoint", httpMethod: HttpMethod.DELETE);
  const Endpoint sessionTokenEndpoint =
      Endpoint(apiPath: "test/sessionToken/endpoint", httpMethod: HttpMethod.POST, needsSessionToken: true);

  final ServerAccountModel validAccount = ServerAccountModel(
      userName: "validAccount",
      passwordHash: "validPassword",
      sessionToken: SessionTokenModel(token: "validToken", validTo: DateTime.now()),
      noteInfoList: const <NoteInfo>[],
      encryptedDataKey: "validKey");

  /// Helper method to add the 4 http method callbacks for the same endpoint
  void initHttpMethodEndpoints() {
    restServer.addCallback(endpoint: getEndpoint, callback: returnRequest);
    restServer.addCallback(endpoint: postEndpoint, callback: returnRequest);
    restServer.addCallback(endpoint: putEndpoint, callback: returnRequest);
    restServer.addCallback(endpoint: deleteEndpoint, callback: returnRequest);
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

    group("http request methods without session tokens against the same valid endpoint: ", () {
      test("get request should return the same query params", () async {
        initHttpMethodEndpoints();
        final Map<String, dynamic> response = await restClient.sendRequest(
          endpoint: getEndpoint,
          queryParams: <String, String>{"test": "test"},
          bodyData: <String, dynamic>{"ignored": "ignored"},
        );
        expect(response["test"], "test");
      });

      test("post request should return the same body params", () async {
        initHttpMethodEndpoints();
        final Map<String, dynamic> response = await restClient.sendRequest(
          endpoint: postEndpoint,
          queryParams: <String, String>{"ignored": "ignored"},
          bodyData: <String, dynamic>{"test": "test"},
        );
        expect(response["test"], "test");
      });

      test("put request should return the same body params", () async {
        initHttpMethodEndpoints();
        final Map<String, dynamic> response = await restClient.sendRequest(
          endpoint: putEndpoint,
          queryParams: <String, String>{"ignored": "ignored"},
          bodyData: <String, dynamic>{"test": "test"},
        );
        expect(response["test"], "test");
      });

      test("delete request should return the same body params", () async {
        initHttpMethodEndpoints();
        final Map<String, dynamic> response = await restClient.sendRequest(
          endpoint: deleteEndpoint,
          queryParams: <String, String>{"ignored": "ignored"},
          bodyData: <String, dynamic>{"test": "test"},
        );
        expect(response["test"], "test");
      });
    });

    test("execute a normal get request with no needed session token to the valid real ABOUT endpoint", () async {
      final Map<String, dynamic> response = await restClient.sendRequest(
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

    group("session token tests: ", () {
      test("a post request with a correct session token should get the valid accounts username", () async {
        initSessionTokenEndpoint();
        sessionServiceMock.sessionTokenOverride = validAccount.sessionToken!.token;
        final Map<String, dynamic> response = await restClient.sendRequest(
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
          throwsA(predicate(
              (Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized))),
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
          throwsA(predicate(
              (Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized))),
        );
      });
    });
  });
}

/// helper method that returns either the requests body data, or the query parameter as a json map for the response
RestCallbackResult returnRequest(RestCallbackParams params) =>
    RestCallbackResult(jsonResult: params.data ?? params.queryParams);
