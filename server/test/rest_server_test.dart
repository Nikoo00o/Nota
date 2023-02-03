import 'package:server/config/server_config.dart';
import 'package:server/network/nota_server.dart';
import 'package:server/network/rest_server.dart';
import 'package:shared/core/network/endpoints.dart';
import 'package:shared/core/network/rest_client.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:test/test.dart';

import 'mocks/server_session_service_mock.dart';

void main() {
  late ServerConfig serverConfig;
  late RestServer restServer;
  late NotaServer notaServer;
  late ServerSessionServiceMock serverSessionServiceMock;
  late RestClient restClient;
  Logger.initLogger(Logger());

  setUp(() {
    serverConfig = ServerConfig();
    restServer = RestServer();
    notaServer = NotaServer(restServer: restServer, serverConfig: serverConfig);
    serverSessionServiceMock = ServerSessionServiceMock();
    restClient = RestClient(config: serverConfig, sessionService: serverSessionServiceMock);
  });

  test(
    'test the basic server functions',
    () async {
      final bool started = await notaServer.runNota(autoRestart: false);
      expect(started, true);

      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CREATE,
        queryParams: <String, String>{"test": "1"},
        bodyData: <String, dynamic>{"another": 2},
      );

      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD,
        queryParams: <String, String>{"test": "1"},
        bodyData: <String, dynamic>{"another": 2},
      );

      await restServer.stop();

      // todo: implement real tests and modify session service mock and use real server implementation!
    },
  );
}
