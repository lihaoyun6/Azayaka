//
//  Preferences.swift
//  Azayaka
//
//  Created by Martin Persson on 2022-12-27.
//

import SwiftUI

struct Preferences: View {
    @AppStorage("audioFormat") private var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality") private var audioQuality: AudioQuality = .high
    @AppStorage("frameRate") private var frameRate: Int = 60
    @AppStorage("videoFormat") private var videoFormat: VideoFormat = .mp4
    @AppStorage("encoder") private var encoder: Encoder = .h264

    var body: some View {
        VStack(alignment: .leading) {
            GroupBox(label: Text("Video Output".uppercased()).fontWeight(.bold)) {
                Form() {
                    Picker("FPS", selection: $frameRate) {
                        Text("60").tag(60)
                        Text("30").tag(30)
                        Text("25").tag(25)
                        Text("24").tag(24)
                        Text("15").tag(15)
                    }.scaledToFit()
                    Picker("Format", selection: $videoFormat) {
                        Text("MOV").tag(VideoFormat.mov)
                        Text("MP4").tag(VideoFormat.mp4)
                    }.scaledToFit()
                    Picker("Encoder", selection: $encoder) {
                        Text("h264").tag(Encoder.h264)
                        Text("h265").tag(Encoder.h265)
                    }.scaledToFit()
                }.frame(maxWidth: .infinity).padding(10)
            }
            GroupBox(label: Text("Audio Output".uppercased()).fontWeight(.bold)) {
                Form() {
                    Picker("Format", selection: $audioFormat) {
                        Text("AAC").tag(AudioFormat.aac)
                        Text("ALAC (Lossless)").tag(AudioFormat.alac)
                        Text("FLAC (Lossless)").tag(AudioFormat.flac)
                        Text("Opus").tag(AudioFormat.opus)
                    }.scaledToFit()
                    Picker("Quality", selection: $audioQuality) {
                        if audioFormat == .alac || audioFormat == .flac {
                            Text("Lossless").tag(audioQuality)
                        }
                        Text("Normal - 128Kbps").tag(AudioQuality.normal)
                        Text("Good - 192Kbps").tag(AudioQuality.good)
                        Text("High - 256Kbps").tag(AudioQuality.high)
                        Text("Extreme - 320Kbps").tag(AudioQuality.extreme)
                    }.scaledToFit().disabled(audioFormat == .alac || audioFormat == .flac)
                }.frame(maxWidth: .infinity).padding(.top, 10)
                Text("These settings are also used when recording video. If set to Opus, MP4 will fall back to AAC.")
                .font(.footnote).foregroundColor(Color.gray).padding(.leading, 2).padding(.trailing, 2).padding(.bottom, 8)
            }
            Divider()
            Spacer()
            VStack(spacing: 2) {
                Button("Select output directory", action: updateOutputDirectory).disabled(true)
                Text("Currently set to \"Downloads\"").font(.footnote).foregroundColor(Color.gray)
            }.frame(maxWidth: .infinity)
            Spacer()
            HStack {
                Text("Azayaka \(getVersion()) (\(getBuild()))")
                Spacer()
                Text("https://mnpn.dev")
            }.padding(5).background(.thickMaterial) .frame( maxWidth: .infinity, alignment: .topLeading)
        }.frame(width: 260, height: 350).padding(10)
    }

    func updateOutputDirectory() { }

    func getVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    func getBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}

extension AppDelegate {
    @objc func openPreferences() {
        preferences.isReleasedWhenClosed = false // otherwise we crash when opening the window again, WTF?
        preferences.title = "Azayaka"
        //preferences.subtitle = "Preferences"
        preferences.contentView = NSHostingView(rootView: Preferences()) // is this how you SwiftUI help I'm scared
        preferences.styleMask = [.titled, .closable]
        preferences.center()
        NSApp.activate(ignoringOtherApps: true)
        preferences.makeKeyAndOrderFront(nil)
    }
}