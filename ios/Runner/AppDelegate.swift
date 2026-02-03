import Flutter
import UIKit
import MultipeerConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "cleanquest_multipeer") {
      let channel = FlutterMethodChannel(
        name: "cleanquest/multipeer",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "startAdvertiser":
          guard let args = call.arguments as? [String: Any],
                let householdId = args["householdId"] as? String,
                let hostUserId = args["hostUserId"] as? String else {
            result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
            return
          }
          var info: [String: String] = [
            "householdId": householdId,
            "hostUserId": hostUserId
          ]
          if let displayName = args["displayName"] as? String, !displayName.isEmpty {
            info["displayName"] = displayName
          }
          if let householdName = args["householdName"] as? String, !householdName.isEmpty {
            info["householdName"] = householdName
          }
          MultipeerManager.shared.startAdvertiser(info: info)
          result(nil)
        case "stopAdvertiser":
          MultipeerManager.shared.stopAdvertiser()
          result(nil)
        case "browseNearby":
          guard let args = call.arguments as? [String: Any],
                let timeoutMs = args["timeoutMs"] as? Int else {
            result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
            return
          }
          MultipeerManager.shared.browse(timeout: Double(timeoutMs) / 1000.0) { peers in
            result(peers)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class MultipeerManager: NSObject {
  static let shared = MultipeerManager()

  private let serviceType = "cleanquest"
  private let peerId = MCPeerID(displayName: UIDevice.current.name)
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?
  private var browseCompletion: (([[String: String]]) -> Void)?
  private var foundPeers: [String: [String: String]] = [:]
  private var browseTimer: Timer?

  func startAdvertiser(info: [String: String]) {
    stopAdvertiser()
    advertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: info, serviceType: serviceType)
    advertiser?.delegate = self
    advertiser?.startAdvertisingPeer()
  }

  func stopAdvertiser() {
    advertiser?.stopAdvertisingPeer()
    advertiser = nil
  }

  func browse(timeout: TimeInterval, completion: @escaping ([[String: String]]) -> Void) {
    stopBrowse()
    browseCompletion = completion
    foundPeers = [:]
    browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
    browser?.delegate = self
    browser?.startBrowsingForPeers()
    browseTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
      self?.finishBrowse()
    }
  }

  private func stopBrowse() {
    browser?.stopBrowsingForPeers()
    browser = nil
    browseTimer?.invalidate()
    browseTimer = nil
    browseCompletion = nil
    foundPeers = [:]
  }

  private func finishBrowse() {
    browser?.stopBrowsingForPeers()
    browser = nil
    browseTimer?.invalidate()
    browseTimer = nil
    let results = Array(foundPeers.values)
    browseCompletion?(results)
    browseCompletion = nil
    foundPeers = [:]
  }
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    // Intentionally ignore; discovery should continue via browser or fallback.
  }

  func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    invitationHandler(false, nil)
  }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    var entry = info ?? [:]
    if entry["peerName"] == nil {
      entry["peerName"] = peerID.displayName
    }
    foundPeers[peerID.displayName] = entry
  }

  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    foundPeers.removeValue(forKey: peerID.displayName)
  }

  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    finishBrowse()
  }
}
