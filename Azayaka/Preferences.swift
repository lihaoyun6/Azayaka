//
//  Preferences.swift
//  Azayaka
//
//  Created by Martin Persson on 2022-12-27.
//

import SwiftUI
import AVFAudio
import AVFoundation
import ServiceManagement

struct Preferences: View {
    static let frontAppKey = "frontAppOnly"
    @AppStorage("audioFormat")   private var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality")  private var audioQuality: AudioQuality = .high
    @AppStorage("frameRate")     private var frameRate: Int = 60
    @AppStorage("videoQuality")     private var videoQuality: Double = 1.0
    @AppStorage("videoFormat")   private var videoFormat: VideoFormat = .mp4
    @AppStorage("encoder")       private var encoder: Encoder = .h264
    @AppStorage("saveDirectory") private var saveDirectory: String?
    @AppStorage(Self.frontAppKey) private var frontApp: Bool = false
    @AppStorage("hideSelf")      private var hideSelf: Bool = false
    @AppStorage("showMouse")     private var showMouse: Bool = true
    @AppStorage("recordMic")     private var recordMic: Bool = false
    @AppStorage("highRes")     private var highRes: Bool = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        VStack(alignment: .leading) {
            GroupBox(label: Text("Video Output".local.uppercased()).fontWeight(.bold)) {
                Form() {
                    Picker("FPS", selection: $frameRate) {
                        Text("60").tag(60)
                        Text("30").tag(30)
                        Text("25").tag(25)
                        Text("24").tag(24)
                        Text("15").tag(15)
                    }.padding([.leading, .trailing], 10)
                    Picker("Resolution", selection: $highRes) {
                        Text("Auto").tag(true)
                        Text("Low (1x)").tag(false)
                    }.padding([.leading, .trailing], 10)
                    Picker("Quality", selection: $videoQuality) {
                        Text("Low").tag(0.3)
                        Text("Medium").tag(0.7)
                        Text("High").tag(1.0)
                    }.padding([.leading, .trailing], 10)
                    Picker("Format", selection: $videoFormat) {
                        Text("MOV").tag(VideoFormat.mov)
                        Text("MP4").tag(VideoFormat.mp4)
                    }.padding([.leading, .trailing], 10)
                    Picker("Encoder", selection: $encoder) {
                        Text("H.264").tag(Encoder.h264)
                        Text("H.265").tag(Encoder.h265)
                    }.padding([.leading, .trailing], 10)
                }.frame(maxWidth: .infinity).padding(.top, 10)
                Toggle(isOn: $hideSelf) {
                    Text("Exclude Azayaka itself")
                }.toggleStyle(CheckboxToggleStyle())
                Toggle(isOn: $frontApp) {
                    Text("Only list focused app's windows")
                }.toggleStyle(CheckboxToggleStyle())
                Toggle(isOn: $showMouse) {
                    Text("Show mouse cursor")
                }.toggleStyle(CheckboxToggleStyle()).padding(.bottom, 10)
            }
            GroupBox(label: Text("Audio Output".local.uppercased()).fontWeight(.bold)) {
                Form() {
                    Picker("Format", selection: $audioFormat) {
                        Text("AAC").tag(AudioFormat.aac)
                        Text("ALAC (Lossless)").tag(AudioFormat.alac)
                        Text("FLAC (Lossless)").tag(AudioFormat.flac)
                        Text("Opus").tag(AudioFormat.opus)
                    }.padding([.leading, .trailing], 10)
                    Picker("Quality", selection: $audioQuality) {
                        if audioFormat == .alac || audioFormat == .flac {
                            Text("Lossless").tag(audioQuality)
                        }
                        Text("Normal - 128Kbps").tag(AudioQuality.normal)
                        Text("Good - 192Kbps").tag(AudioQuality.good)
                        Text("High - 256Kbps").tag(AudioQuality.high)
                        Text("Extreme - 320Kbps").tag(AudioQuality.extreme)
                    }.padding([.leading, .trailing], 10).disabled(audioFormat == .alac || audioFormat == .flac)
                }.frame(maxWidth: .infinity).padding(.top, 10)
                Text("These settings are also used when recording video. If set to Opus, MP4 will fall back to AAC.")
                .font(.footnote).foregroundColor(Color.gray).padding(.leading, 4).padding(.trailing, 4).padding(.bottom, 4).fixedSize(horizontal: false, vertical: true)
                if #available(macOS 14, *) { // apparently they changed onChange in Sonoma
                    Toggle(isOn: $recordMic) {
                        Text("Record microphone")
                    }.toggleStyle(CheckboxToggleStyle()).onChange(of: recordMic) {
                        Task { await performMicCheck() }
                    }
                } else {
                    Toggle(isOn: $recordMic) {
                        Text("Record microphone")
                    }.toggleStyle(CheckboxToggleStyle()).onChange(of: recordMic) { _ in
                        Task { await performMicCheck() }
                    }
                }
                Text("Doesn't apply to system audio-only recordings. The currently set input device will be used, and will be written as a separate audio track.")
                .font(.footnote).foregroundColor(Color.gray).padding(.leading, 4).padding(.trailing, 4).padding(.bottom, 8).fixedSize(horizontal: false, vertical: true)
            }.onAppear {
                recordMic = recordMic && AVCaptureDevice.authorizationStatus(for: .audio) == .authorized // untick box if no perms
            }
            Spacer()
            VStack {
                HStack(spacing: 15){
                    Toggle(isOn: $launchAtLogin) {}
                        .offset(x: 10)
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    Text("Launch at login")
                }
            }.frame(maxWidth: .infinity)
            Divider()
            Spacer()
            VStack(spacing: 2) {
                Button("Select output directory", action: updateOutputDirectory)
                Text(String(format: "Currently set to \"%@\"".local, URL(fileURLWithPath: saveDirectory!).lastPathComponent)).font(.footnote).foregroundColor(Color.gray)
            }.frame(maxWidth: .infinity)
        }.frame(width: 260).padding([.leading, .trailing], 15).padding(.top, 10)
        HStack {
            Text("Azayaka \(getVersion()) (\(getBuild()))").foregroundColor(Color.secondary)
            Spacer()
            Text("https://mnpn.dev")
        }.padding(14).background(VisualEffectView()).frame(height: 42)
    }

    func performMicCheck() async {
        guard recordMic == true else { return }
        if await AVCaptureDevice.requestAccess(for: .audio) { return }

        recordMic = false
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Azayaka needs permissions!".local
            alert.informativeText = "Azayaka needs permission to record your microphone to do this.".local
            alert.addButton(withTitle: "Open Settings".local)
            alert.addButton(withTitle: "No thanks".local)
            alert.alertStyle = .warning
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
        }
    }

    func updateOutputDirectory() { // todo: re-sandbox
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowedContentTypes = []
        openPanel.allowsOtherFileTypes = false
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            saveDirectory = openPanel.urls.first?.path
        }
    }

    func getVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown".local
    }

    func getBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown".local
    }

    struct VisualEffectView: NSViewRepresentable {
        func makeNSView(context: Context) -> NSVisualEffectView { return NSVisualEffectView() }
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
    }
}

#Preview {
    Preferences()
}

extension AppDelegate {
    @objc func setLoginItem(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        do {
            if sender.state == .on { try SMAppService.mainApp.register() }
            if sender.state == .off { try SMAppService.mainApp.unregister() }
        }catch{
            print("Failed to \(sender.state == .on ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }
    
    @objc func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
        }else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        for w in NSApplication.shared.windows {
            if w.level.rawValue == 0 || w.level.rawValue == 3 { w.level = .floating }
        }
    }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}
