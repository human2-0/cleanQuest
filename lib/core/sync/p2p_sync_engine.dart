import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

enum SyncConnectionState {
  disconnected,
  discovering,
  hosting,
  connected,
}

class P2pHostInfo {
  const P2pHostInfo({
    required this.host,
    required this.port,
    required this.hostUserId,
    required this.hostStartTimeMs,
    required this.primaryAdminId,
    required this.adminEpoch,
  });

  final String host;
  final int port;
  final String hostUserId;
  final int hostStartTimeMs;
  final String primaryAdminId;
  final int adminEpoch;
}

class P2pSyncEngine {
  P2pSyncEngine({
    required this.householdId,
    required this.userId,
    this.householdName = '',
    this.displayName = '',
    this.serviceType = '_cleanquest._tcp',
    this.servicePort = 4040,
  });

  final String householdId;
  final String userId;
  final String householdName;
  final String displayName;
  final String serviceType;
  final int servicePort;

  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController.broadcast();
  final StreamController<SyncConnectionState> _stateController =
      StreamController.broadcast();

  SyncConnectionState _state = SyncConnectionState.disconnected;

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;
  Future<void> _broadcastTask = Future.value();
  ServerSocket? _server;
  final Set<Socket> _clients = {};
  Socket? _clientSocket;
  StreamSubscription? _clientSub;
  StreamSubscription? _discoverySub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _hostRestartTimer;
  int? _localHostStartTimeMs;
  bool _shouldHost = false;
  bool _isAdmin = false;
  bool _isPrimary = false;
  String _primaryAdminId = '';
  int _adminEpoch = 0;
  bool _stoppingHost = false;
  bool _restartingHost = false;
  bool _connecting = false;
  int _hostRestartAttempts = 0;
  int _lastHostRestartMs = 0;
  P2pHostInfo? _lastDiscoveredHost;
  int _lastDiscoveredAtMs = 0;

  Stream<Map<String, dynamic>> get messages => _incomingController.stream;
  Stream<SyncConnectionState> get state => _stateController.stream;
  SyncConnectionState get currentState => _state;
  bool get isHost => _state == SyncConnectionState.hosting;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[p2p] $message');
    }
  }

  void updateAdminState({
    required bool isAdmin,
    required bool isPrimary,
    required String primaryAdminId,
    required int adminEpoch,
  }) {
    final shouldHost = isPrimary;
    final changed = _shouldHost != shouldHost ||
        _primaryAdminId != primaryAdminId ||
        _adminEpoch != adminEpoch ||
        _isAdmin != isAdmin ||
        _isPrimary != isPrimary;
    _shouldHost = shouldHost;
    _isAdmin = isAdmin;
    _isPrimary = isPrimary;
    _primaryAdminId = primaryAdminId;
    _adminEpoch = adminEpoch;
    if (!changed) {
      return;
    }
    _log(
      'admin-state isAdmin=$isAdmin isPrimary=$isPrimary '
      'primaryAdminId=$primaryAdminId adminEpoch=$adminEpoch '
      'shouldHost=$_shouldHost',
    );
    if (_state == SyncConnectionState.hosting && !_shouldHost) {
      () async {
        await _stopHost();
        _scheduleReconnect();
      }();
      return;
    }
    if (_shouldHost &&
        _state != SyncConnectionState.disconnected &&
        _state != SyncConnectionState.hosting) {
      _promoteToHost();
    }
  }

  Future<void> start() async {
    if (_state != SyncConnectionState.disconnected) {
      return;
    }
    if (householdId.isEmpty || userId.isEmpty) {
      _log(
        'start skip missing ids householdId="$householdId" userId="$userId"',
      );
      return;
    }
    _lastDiscoveredHost = null;
    _lastDiscoveredAtMs = 0;
    _log(
      'start householdId=$householdId userId=$userId '
      'householdName="$householdName" displayName="$displayName"',
    );
    _setState(SyncConnectionState.discovering);
    await _startDiscovery();
    await _selectHostOrBecomeHost();
  }

  Future<void> stop() async {
    _log('stop');
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _lastDiscoveredHost = null;
    _lastDiscoveredAtMs = 0;
    await _stopClient();
    await _stopHost();
    await _stopDiscovery();
    _setState(SyncConnectionState.disconnected);
  }

  Future<void> send(Map<String, dynamic> message) async {
    final encoded = '${jsonEncode(message)}\n';
    const maxAttempts = 3;
    var backoffMs = 200;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final socket = _clientSocket;
      if (socket == null) {
        _scheduleReconnect();
        return;
      }
      try {
        socket.write(encoded);
        await socket.flush();
        return;
      } catch (_) {
        if (attempt == maxAttempts) {
          _scheduleReconnect();
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
        backoffMs *= 2;
      }
    }
  }

  Future<void> broadcast(Map<String, dynamic> message) async {
    final encoded = '${jsonEncode(message)}\n';
    final toRemove = <Socket>[];
    for (final client in List<Socket>.from(_clients)) {
      try {
        client.write(encoded);
        await client.flush();
      } catch (_) {
        try {
          client.destroy();
        } catch (_) {}
        toRemove.add(client);
      }
    }
    if (toRemove.isNotEmpty) {
      _clients.removeAll(toRemove);
    }
  }

  Future<void> _startDiscovery() async {
    _log('discovery start type=$serviceType');
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    final stream = _discovery!.eventStream;
    _discoverySub = stream?.listen(_handleDiscoveryEvent);
    await _discovery!.start();
  }

  Future<void> _stopDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    if (_discovery != null) {
      await _discovery!.stop();
    }
    _discovery = null;
    _log('discovery stop');
  }

  Future<void> _selectHostOrBecomeHost() async {
    final cachedHost = _lastDiscoveredHost;
    if (cachedHost != null &&
        DateTime.now().millisecondsSinceEpoch - _lastDiscoveredAtMs < 10000) {
      await _connectToHost(cachedHost);
      return;
    }
    final host = await _findBestHost(const Duration(seconds: 3));
    if (host != null) {
      await _connectToHost(host);
    } else if (_shouldHost) {
      await _startHost();
    } else {
      _log('discovery bestHost=none; awaiting discovery event');
    }
  }

  Future<P2pHostInfo?> _findBestHost(Duration timeout) async {
    if (_discovery == null) {
      return null;
    }
    P2pHostInfo? best;

    final stream = _discovery!.eventStream;
    if (stream == null) {
      return null;
    }
    final sub = stream.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final info = _hostInfoFromService(event.service);
        if (info == null) {
          return;
        }
        if (info.hostUserId == userId) {
          return;
        }
        if (best == null || _isHigherPriority(info, best!)) {
          best = info;
        }
      }
    });

    await Future<void>.delayed(timeout);
    await sub.cancel();
    if (best == null) {
      _log('discovery bestHost=none');
    } else {
      _log(
        'discovery bestHost hostUserId=${best!.hostUserId} '
        'host=${best!.host} port=${best!.port} '
        'hostStartTime=${best!.hostStartTimeMs} '
        'primaryAdminId=${best!.primaryAdminId} '
        'adminEpoch=${best!.adminEpoch}',
      );
    }
    return best;
  }

  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
      event.service?.resolve(_discovery!.serviceResolver);
      return;
    }

    if (event.type != BonsoirDiscoveryEventType.discoveryServiceResolved) {
      return;
    }

    final info = _hostInfoFromService(event.service);
    if (info == null || info.hostUserId == userId) {
      return;
    }
    if (_lastDiscoveredHost == null ||
        _isHigherPriority(info, _lastDiscoveredHost!)) {
      _lastDiscoveredHost = info;
      _lastDiscoveredAtMs = DateTime.now().millisecondsSinceEpoch;
    }

    if (_state == SyncConnectionState.hosting &&
        _localHostStartTimeMs != null &&
        _isHigherPriority(info, P2pHostInfo(
          host: 'local',
          port: servicePort,
          hostUserId: userId,
          hostStartTimeMs: _localHostStartTimeMs!,
          primaryAdminId: _primaryAdminId,
          adminEpoch: _adminEpoch,
        ))) {
      _log(
        'discovery step-down hostUserId=${info.hostUserId} '
        'primaryAdminId=${info.primaryAdminId} adminEpoch=${info.adminEpoch}',
      );
      _stepDownAndConnect(info);
      return;
    }

    if (_state == SyncConnectionState.discovering && !_connecting) {
      _connecting = true;
      _connectToHost(info).whenComplete(() {
        _connecting = false;
      });
    }
  }

  Future<void> _startHost() async {
    if (!_shouldHost) {
      _log('host skip shouldHost=false');
      return;
    }
    if (householdId.isEmpty || userId.isEmpty) {
      _log('host skip missing ids householdId="$householdId" userId="$userId"');
      _scheduleReconnect();
      return;
    }
    _localHostStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv6,
        servicePort,
        v6Only: false,
      );
    } catch (_) {
      try {
        _server = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          servicePort,
        );
      } catch (_) {
        _localHostStartTimeMs = null;
        _scheduleReconnect();
        return;
      }
    }
    _server!.listen(
      _handleClientSocket,
      onDone: _onServerDone,
      onError: (_) => _onServerDone(),
    );
    await _startBroadcast();
    _setState(SyncConnectionState.hosting);
    _startHeartbeat();
  }

  Future<void> _stopHost() async {
    _stoppingHost = true;
    try {
      _heartbeatTimer?.cancel();
      _hostRestartTimer?.cancel();
      _hostRestartTimer = null;
      for (final client in List<Socket>.from(_clients)) {
        await _safeClose(client);
      }
      _clients.clear();
      await _safeServerClose(_server);
      _server = null;
      await _stopBroadcast();
      _localHostStartTimeMs = null;
    } finally {
      _stoppingHost = false;
    }
  }

  Future<void> _startBroadcast() async {
    await _queueBroadcast(() async {
      if (householdId.isEmpty || userId.isEmpty) {
        _log(
          'broadcast skip missing ids householdId="$householdId" userId="$userId"',
        );
        return;
      }
      if (_localHostStartTimeMs == null) {
        _log('broadcast skip missing host start time');
        return;
      }
      final primaryAdminId =
          _primaryAdminId.isNotEmpty ? _primaryAdminId : userId;
      final trimmedName = displayName.trim();
      final trimmedHousehold = householdName.trim();
      _log(
        'broadcast householdId=$householdId hostUserId=$userId '
        'primaryAdminId=$primaryAdminId adminEpoch=$_adminEpoch '
        'displayName="$trimmedName" householdName="$trimmedHousehold"',
      );
      final service = BonsoirService(
        name: 'CleanQuest-$userId',
        type: serviceType,
        port: servicePort,
        attributes: <String, String>{
          'householdId': householdId,
          'hostUserId': userId,
          if (trimmedName.isNotEmpty) 'hostDisplayName': trimmedName,
          if (trimmedHousehold.isNotEmpty) 'householdName': trimmedHousehold,
          'hostStartTime': _localHostStartTimeMs.toString(),
          'primaryAdminId': primaryAdminId,
          'adminEpoch': _adminEpoch.toString(),
          'protocolVersion': '1',
        },
      );
      final broadcast = BonsoirBroadcast(service: service);
      await broadcast.ready;
      await _broadcast?.stop();
      _broadcast = broadcast;
      await broadcast.start();
    });
  }

  Future<void> _stopBroadcast() async {
    await _queueBroadcast(() async {
      if (_broadcast != null) {
        await _broadcast!.stop();
      }
      _broadcast = null;
    });
  }

  Future<void> _connectToHost(P2pHostInfo host) async {
    if (_connecting) {
      return;
    }
    _connecting = true;
    try {
      await _stopHost();
      _log(
        'connect hostUserId=${host.hostUserId} host=${host.host} '
        'port=${host.port} hostStartTime=${host.hostStartTimeMs} '
        'primaryAdminId=${host.primaryAdminId} adminEpoch=${host.adminEpoch}',
      );
      try {
        _clientSocket = await Socket.connect(
          host.host,
          host.port,
          timeout: const Duration(seconds: 3),
        );
      } catch (_) {
        _log(
          'connect failed hostUserId=${host.hostUserId} host=${host.host} '
          'port=${host.port}',
        );
        _scheduleReconnect();
        return;
      }
      _clientSub = _clientSocket!
          .cast<List<int>>()
          .handleError((error) {
            _log('client stream error: $error');
            _onClientDone();
          })
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleIncomingLine,
            onDone: _onClientDone,
            cancelOnError: true,
          );
      _setState(SyncConnectionState.connected);
      _startHeartbeat();
    } finally {
      _connecting = false;
    }
  }

  Future<void> _stopClient() async {
    _heartbeatTimer?.cancel();
    await _clientSub?.cancel();
    _clientSub = null;
    await _safeClose(_clientSocket);
    _clientSocket = null;
  }

  void _handleClientSocket(Socket socket) {
    _clients.add(socket);
    final remoteLabel = _describeRemote(socket);
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      _handleIncomingLine,
      onDone: () {
        _log('server client done remote=$remoteLabel');
        _clients.remove(socket);
      },
      onError: (_) {
        _log('server client error remote=$remoteLabel');
        _clients.remove(socket);
      },
      cancelOnError: true,
    );
  }

  void _handleIncomingLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      _incomingController.add(message);
    } catch (_) {
      // Ignore malformed messages.
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final trimmedName = displayName.trim();
      final message = <String, dynamic>{
        'type': 'heartbeat',
        'householdId': householdId,
        'senderId': userId,
        'isAdmin': _isAdmin,
        'isPrimary': _isPrimary,
        'primaryAdminId': _primaryAdminId,
        'adminEpoch': _adminEpoch,
        if (trimmedName.isNotEmpty) 'displayName': trimmedName,
        'ts': DateTime.now().toIso8601String(),
        'tsMs': DateTime.now().millisecondsSinceEpoch,
      };
      if (_state == SyncConnectionState.hosting) {
        broadcast(message);
      } else {
        send(message);
      }
    });
  }

  void _onClientDone() {
    _log('client socket done');
    _scheduleReconnect();
  }

  void _onServerDone() {
    _log('server socket done');
    if (_stoppingHost) {
      return;
    }
    if (_state == SyncConnectionState.hosting && _shouldHost) {
      _scheduleHostRestart();
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) {
      return;
    }
    if (_state == SyncConnectionState.hosting && _shouldHost) {
      _log('reconnect while hosting; restarting host');
      _scheduleHostRestart();
      return;
    }
    if (_state == SyncConnectionState.connected) {
      () async {
        await _stopClient();
        _log('reconnect scheduled state=$_state');
        _setState(SyncConnectionState.discovering);
        _reconnectTimer = Timer(const Duration(seconds: 2), () {
          _reconnectTimer = null;
          _selectHostOrBecomeHost();
        });
      }();
      return;
    }
    _log('reconnect scheduled state=$_state');
    _setState(SyncConnectionState.discovering);
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      _selectHostOrBecomeHost();
    });
  }

  Future<void> _stepDownAndConnect(P2pHostInfo host) async {
    await _stopHost();
    await _connectToHost(host);
  }

  Future<void> _promoteToHost() async {
    await _stopClient();
    await _startHost();
  }

  Future<void> _restartHost() async {
    if (_restartingHost || _stoppingHost) {
      return;
    }
    _restartingHost = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      await _stopHost();
      if (_shouldHost) {
        await _startHost();
      } else {
        _scheduleReconnect();
      }
    } finally {
      _restartingHost = false;
    }
  }

  void _scheduleHostRestart() {
    if (_hostRestartTimer != null || _restartingHost || _stoppingHost) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHostRestartMs < 10000) {
      _hostRestartAttempts += 1;
    } else {
      _hostRestartAttempts = 1;
    }
    _lastHostRestartMs = now;
    final delayMs = _hostRestartAttempts > 3 ? 3000 : 500;
    _log('host restart scheduled delayMs=$delayMs attempts=$_hostRestartAttempts');
    _hostRestartTimer = Timer(Duration(milliseconds: delayMs), () {
      _hostRestartTimer = null;
      _restartHost();
    });
  }

  Future<void> _queueBroadcast(Future<void> Function() action) async {
    _broadcastTask =
        _broadcastTask.then((_) => action()).catchError((_) {});
    await _broadcastTask;
  }

  P2pHostInfo? _hostInfoFromService(BonsoirService? service) {
    if (service == null) {
      _log('discovery ignore: null service');
      return null;
    }
    if (householdId.isEmpty) {
      _log('discovery ignore: missing local householdId');
      return null;
    }
    final attributes = service.attributes;
    final protocolVersion = attributes['protocolVersion'];
    if (protocolVersion == null || protocolVersion.isEmpty) {
      _log('discovery ignore: missing protocolVersion attrs=$attributes');
      return null;
    }
    final advertisedHouseholdId = attributes['householdId'];
    if (advertisedHouseholdId != householdId) {
      _log(
        'discovery ignore: household mismatch local=$householdId '
        'remote=$advertisedHouseholdId attrs=$attributes',
      );
      return null;
    }
    if (service is! ResolvedBonsoirService) {
      _log('discovery ignore: service not resolved name=${service.name}');
      return null;
    }
    final host = service.host;
    if (host == null || host.isEmpty) {
      _log(
        'discovery ignore: missing host name=${service.name} attrs=$attributes',
      );
      return null;
    }
    final port = service.port ?? servicePort;
    final hostUserId = attributes['hostUserId'] ?? '';
    final startTimeRaw = attributes['hostStartTime'] ?? '0';
    final hostStartTime = int.tryParse(startTimeRaw) ?? 0;
    final primaryAdminId = attributes['primaryAdminId'] ?? '';
    final adminEpoch = int.tryParse(attributes['adminEpoch'] ?? '0') ?? 0;
    _log(
      'discovery resolved host=$host port=$port hostUserId=$hostUserId '
      'hostStartTime=$hostStartTime primaryAdminId=$primaryAdminId '
      'adminEpoch=$adminEpoch protocolVersion=$protocolVersion',
    );
    return P2pHostInfo(
      host: host,
      port: port,
      hostUserId: hostUserId,
      hostStartTimeMs: hostStartTime,
      primaryAdminId: primaryAdminId,
      adminEpoch: adminEpoch,
    );
  }

  bool _isHigherPriority(P2pHostInfo candidate, P2pHostInfo current) {
    if (_primaryAdminId.isNotEmpty) {
      final candidatePrimary = candidate.hostUserId == _primaryAdminId;
      final currentPrimary = current.hostUserId == _primaryAdminId;
      if (candidatePrimary != currentPrimary) {
        return candidatePrimary;
      }
    }
    if (candidate.adminEpoch != current.adminEpoch) {
      return candidate.adminEpoch > current.adminEpoch;
    }
    if (candidate.hostStartTimeMs != current.hostStartTimeMs) {
      return candidate.hostStartTimeMs < current.hostStartTimeMs;
    }
    return candidate.hostUserId.compareTo(current.hostUserId) < 0;
  }

  void _setState(SyncConnectionState next) {
    if (_state != next) {
      _log('state ${_state.name} -> ${next.name}');
    }
    _state = next;
    _stateController.add(next);
  }

  String _describeRemote(Socket socket) {
    try {
      return '${socket.remoteAddress.address}:${socket.remotePort}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _safeClose(Socket? socket) async {
    if (socket == null) {
      return;
    }
    try {
      await socket.close();
    } catch (error) {
      _log('socket close error: $error');
      try {
        socket.destroy();
      } catch (_) {}
    }
  }

  Future<void> _safeServerClose(ServerSocket? server) async {
    if (server == null) {
      return;
    }
    try {
      await server.close();
    } catch (error) {
      _log('server close error: $error');
    }
  }
}
