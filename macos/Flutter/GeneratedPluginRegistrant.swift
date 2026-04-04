//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_service
import audio_session
import flutter_tts
import geolocator_apple
import package_info_plus
import speech_to_text
import sqflite_darwin
import url_launcher_macos
import video_player_avfoundation
import webview_flutter_wkwebview

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioServicePlugin.register(with: registry.registrar(forPlugin: "AudioServicePlugin"))
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  FlutterTtsPlugin.register(with: registry.registrar(forPlugin: "FlutterTtsPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  SpeechToTextPlugin.register(with: registry.registrar(forPlugin: "SpeechToTextPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
  WebViewFlutterPlugin.register(with: registry.registrar(forPlugin: "WebViewFlutterPlugin"))
}
