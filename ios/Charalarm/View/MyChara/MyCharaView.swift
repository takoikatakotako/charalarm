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
                ForEach(viewState.presets) { preset in
                    Button {
                        viewState.selectedPresetID = preset.charaID
                        viewState.usesImportedVRM = false
                    } label: {
                        HStack {
                            Text(preset.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewState.selectedPresetID == preset.charaID && !viewState.usesImportedVRM {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
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
            } header: {
                Text(String(localized: "my-chara-name"))
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
                    if viewState.save() {
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
        .fullScreenCover(isPresented: $viewState.showingResourceDownloadView) {
            ResourceDownloadView(viewState: ResourceDownloadViewState(charaID: viewState.baseCharaID, asMyChara: true))
        }
        .onAppear {
            viewState.onAppear()
        }
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
