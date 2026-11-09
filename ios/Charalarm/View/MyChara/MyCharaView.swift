import SwiftUI
import UniformTypeIdentifiers

/// 「自分のキャラ」を作る・直す画面。見た目はプリセットのキャラか手持ちの VRM、名前はユーザーが決める
struct MyCharaView: View {
    @State var viewState: MyCharaViewState
    @Environment(\.dismiss) private var dismiss

    private static let vrmType = UTType(filenameExtension: "vrm", conformingTo: .data) ?? .data

    var body: some View {
        Form {
            Section {
                preview
                    .frame(height: 320)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                if viewState.isLoadingPresets {
                    ProgressView()
                } else if viewState.presets.isEmpty {
                    Text(String(localized: "my-chara-no-presets"))
                        .foregroundStyle(.secondary)
                }
                presetGrid
            } header: {
                Text(String(localized: "my-chara-base"))
            } footer: {
                Text(String(localized: "my-chara-base-footer"))
            }

            Section {
                if viewState.importedPreviewURL != nil {
                    Button {
                        viewState.usesImportedVRM = true
                    } label: {
                        HStack {
                            Text(viewState.importedTitle ?? String(localized: "my-chara-imported"))
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewState.usesImportedVRM {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                Button {
                    viewState.showingImporter = true
                } label: {
                    Label(String(localized: "my-chara-import"), systemImage: "square.and.arrow.down")
                }
            } header: {
                Text(String(localized: "my-chara-own-vrm"))
            } footer: {
                Text(String(localized: "my-chara-import-footer"))
            }

            Section {
                TextField(String(localized: "my-chara-name-placeholder"), text: $viewState.name)
                Text("\(viewState.name.unicodeScalars.count) / 50")
                    .font(.caption)
                    .foregroundStyle(viewState.name.unicodeScalars.count > 50 ? .red : .secondary)
            } header: {
                Text(String(localized: "my-chara-name"))
            }

            Section {
                TextField(String(localized: "my-chara-personality-placeholder"), text: $viewState.personality, axis: .vertical)
                    .lineLimit(4...8)
                Text("\(viewState.personality.unicodeScalars.count) / 1000")
                    .font(.caption)
                    .foregroundStyle(viewState.personality.unicodeScalars.count > 1000 ? .red : .secondary)
            } header: {
                Text(String(localized: "my-chara-personality"))
            } footer: {
                Text(String(localized: "my-chara-personality-footer"))
            }

            Section {
                if viewState.isLoadingVoices {
                    ProgressView()
                } else if viewState.voices.isEmpty {
                    Button(String(localized: "my-chara-voices-retry")) {
                        Task { await viewState.loadVoices() }
                    }
                } else {
                    Picker(String(localized: "my-chara-voice"), selection: $viewState.selectedVoiceID) {
                        if viewState.hasMyChara {
                            Text(String(localized: "my-chara-voice-default")).tag(nil as String?)
                        }
                        ForEach(viewState.voices) { voice in
                            Text("\(voice.name) — \(voice.description)").tag(Optional(voice.id))
                        }
                    }
                    Button {
                        viewState.previewVoice()
                    } label: {
                        HStack {
                            Label(String(localized: "my-chara-voice-preview"), systemImage: "speaker.wave.2")
                            if viewState.isPreviewingVoice { ProgressView() }
                        }
                    }
                    .disabled(viewState.selectedVoiceID == nil || viewState.selectedPreset == nil || viewState.isPreviewingVoice)
                }
            } header: {
                Text(String(localized: "my-chara-voice"))
            } footer: {
                Text(String(localized: "my-chara-voice-footer"))
            }

            Section {
                Button(String(localized: "profile-select")) {
                    viewState.select()
                }
                .disabled(!viewState.canSave)
                if viewState.hasMyChara {
                    Button(String(localized: "my-chara-delete"), role: .destructive) {
                        if viewState.delete() {
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "my-chara-title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "common-save")) {
                    if viewState.saveFromToolbar() {
                        dismiss()
                    }
                }
                .disabled(!viewState.canSave)
            }
        }
        .fileImporter(isPresented: $viewState.showingImporter, allowedContentTypes: [Self.vrmType, .data]) { result in
            viewState.importVRM(result: result)
        }
        .alert(item: $viewState.alert) { alert in
            Alert(title: Text(alert.message), dismissButton: .default(Text(String(localized: "common-close"))))
        }
        .alert(
            String(localized: "my-chara-license-title"),
            isPresented: Binding(get: { viewState.licenseConfirmation != nil }, set: { if !$0 { viewState.licenseConfirmation = nil } })
        ) {
            Button(String(localized: "common-cancel"), role: .cancel) {}
            Button(String(localized: "my-chara-license-use")) {
                viewState.confirmLicense()
            }
        } message: {
            Text(String(localized: "my-chara-license-message"))
        }
        .fullScreenCover(isPresented: $viewState.showingResourceDownloadView, onDismiss: {
            viewState.selectionFinished()
        }) {
            ResourceDownloadView(viewState: ResourceDownloadViewState(charaID: viewState.downloadCharaID, myCharaPending: viewState.pendingSelection))
        }
        .onAppear {
            viewState.onAppear()
        }
        .onChange(of: viewState.selectedVoiceID) { _, _ in
            viewState.stopVoicePreview()
        }
        .onChange(of: viewState.selectedPresetID) { _, _ in
            viewState.stopVoicePreview()
        }
        .onDisappear {
            viewState.stopVoicePreview()
        }
    }

    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(viewState.presets) { preset in
                let isSelected = viewState.selectedPresetID == preset.charaID && !viewState.usesImportedVRM
                Button {
                    viewState.selectedPresetID = preset.charaID
                    viewState.usesImportedVRM = false
                } label: {
                    VStack(spacing: 8) {
                        AsyncImage(url: preset.presetImageURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Image(systemName: "person.crop.rectangle")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 150)
                        Text(preset.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                                .padding(4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(preset.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var preview: some View {
        if let url = viewState.previewModelFileURL {
            CharaVRMView(charaID: viewState.baseCharaID, modelFileURL: url, framing: .full)
                .id(url)
        } else if let url = viewState.previewImageURL {
            // 立ち絵のプリセット
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .padding(.top, 8)
        } else {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
        }
    }
}
