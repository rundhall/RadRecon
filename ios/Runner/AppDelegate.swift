import AVFoundation
import Flutter
import MediaPlayer
import UIKit
import UserNotifications

/// Bluetooth és fejhallgató médiagombok (lejátszás, következő, előző) és a
/// billentyűzetes távirányítók médiagombjai.
///
/// `MPRemoteCommandCenter`-rel dolgozik. iOS csak annak az appnak küldi a
/// médiagombokat, amelyik "most játszik", ezért amíg valamelyik gomb le van
/// kezelve, egy hangtalan hurok fut. A hangerőgombokat iOS nem adja át.
final class RemoteKeys {
  private let channel: FlutterMethodChannel
  private var player: AVAudioPlayer?
  private var wantAlive = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "radrecon/keys", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setHandled" {
        self?.update(Set((call.arguments as? [String]) ?? []))
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      self?.interruption(note)
    }
  }

  private func update(_ names: Set<String>) {
    let center = MPRemoteCommandCenter.shared()
    let play = names.contains("play")
    bind(center.togglePlayPauseCommand, play, "play")
    bind(center.playCommand, play, "play")
    bind(center.pauseCommand, play, "play")
    bind(center.nextTrackCommand, names.contains("next"), "next")
    bind(center.previousTrackCommand, names.contains("previous"), "previous")

    wantAlive = play || names.contains("next") || names.contains("previous")
    if wantAlive { startKeepAlive() } else { stopKeepAlive() }
  }

  private func bind(_ command: MPRemoteCommand, _ enabled: Bool, _ name: String) {
    command.removeTarget(nil)
    command.isEnabled = enabled
    guard enabled else { return }
    command.addTarget { [weak self] _ in
      self?.channel.invokeMethod("key", arguments: name)
      return .success
    }
  }

  // MARK: hangtalan hurok

  private func startKeepAlive() {
    if player?.isPlaying == true { return }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback)
      try session.setActive(true)
      let p = try AVAudioPlayer(data: RemoteKeys.silentWav())
      p.numberOfLoops = -1
      p.prepareToPlay()
      p.play()
      player = p
      UIApplication.shared.beginReceivingRemoteControlEvents()
      MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        MPMediaItemPropertyTitle: "RadRecon",
        MPNowPlayingInfoPropertyPlaybackRate: 1.0,
      ]
    } catch {
      NSLog("RemoteKeys: a hangtalan hurok nem indult: \(error)")
    }
  }

  private func stopKeepAlive() {
    player?.stop()
    player = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    UIApplication.shared.endReceivingRemoteControlEvents()
  }

  private func interruption(_ note: Notification) {
    guard wantAlive,
          let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
    startKeepAlive()
  }

  /// Egy másodperc csend (44,1 kHz, mono, 16 bit), futás közben előállítva.
  private static func silentWav() -> Data {
    let rate: UInt32 = 44100
    let samples = Int(rate)
    let dataSize = UInt32(samples * 2)
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    d.append("RIFF".data(using: .ascii)!)
    u32(36 + dataSize)
    d.append("WAVEfmt ".data(using: .ascii)!)
    u32(16); u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16)
    d.append("data".data(using: .ascii)!)
    u32(dataSize)
    d.append(Data(count: Int(dataSize)))
    return d
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var remoteKeys: RemoteKeys?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Helyi értesítések megjelenítéséhez (flutter_local_notifications).
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    remoteKeys = RemoteKeys(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
