import SwiftUI
import UIKit

// MARK: - キャラ作成画面

struct CreateView: View {
    @EnvironmentObject var game: GameState
    @State private var name = ""
    @State private var look = Appearance.random()
    @State private var previewAdult = false

    var body: some View {
        VStack(spacing: 0) {
            // 上：キャラはいつもここに見えている
            VStack(spacing: 10) {
                Text("赤ちゃんが生まれた！").font(.title2.bold())
                if Room3DView.isAvailable {
                    Picker("プレビュー", selection: $previewAdult) {
                        Text("いま（赤ちゃん）").tag(false)
                        Text("大人になると…").tag(true)
                    }
                    .pickerStyle(.segmented)
                    Room3DView(lookOverride: look, stageOverride: previewAdult ? .star : .baby, portrait: true)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        AvatarView(look: look, stage: .baby, size: 110)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        AvatarView(look: look, stage: .star, size: 110)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(height: 340)

            // 下：ボトムシートの中だけスクロールする
            BottomSheetPanel {
                VStack(spacing: 18) {
                    TextField("名前をつけてね", text: $name)
                        .textFieldStyle(.roundedBorder)
                    AppearanceEditor(look: $look)
                    Button("育てはじめる") {
                        var d = game.data
                        d.name = name
                        d.appearance = look
                        d.created = true
                        game.data = d
                        game.talk("おぎゃー！")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(name.isEmpty)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - 着せ替え画面

struct ClosetView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var draft = Appearance()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 上：キャラはスクロールしても動かない
                Group {
                    if Room3DView.isAvailable {
                        Room3DView(lookOverride: draft, portrait: true)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        AvatarView(look: draft, stage: game.stage, size: 200)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .frame(height: 300)

                // 下：ボトムシートの中だけスクロールする
                BottomSheetPanel {
                    AppearanceEditor(look: $draft)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("着せ替え")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        game.data.appearance = draft
                        dismiss()
                    }
                }
            }
        }
        .onAppear { draft = game.data.appearance }
    }
}

// MARK: - ボトムシート風の入れ物（中身だけスクロールする）

struct BottomSheetPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)
            ScrollView {
                content
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 10, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.top, 10)
    }
}

// MARK: - パーツを選ぶ部分（作成画面と着せ替え画面で共通）

struct AppearanceEditor: View {
    @Binding var look: Appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("体").font(.headline)
            ChipRow(title: "身長", selection: $look.height)
            ChipRow(title: "体格", selection: $look.build)

            Divider()
            Text("顔").font(.headline)
            ColorRow(title: "肌の色", colors: Palette.skins, selection: $look.skin)
            ChipRow(title: "髪型", selection: $look.hair)
            ColorRow(title: "髪の色", colors: Palette.hair, selection: $look.hairColor)
            ChipRow(title: "目", selection: $look.eyes)
            ChipRow(title: "まゆげ", selection: $look.brows)
            ChipRow(title: "口", selection: $look.mouth)
            ChipRow(title: "ひげ（ティーン以上で表示）", selection: $look.beard)

            Divider()
            Text("服・アクセサリー").font(.headline)
            ChipRow(title: "服", selection: $look.top)
            ColorRow(title: "服の色", colors: Palette.cloth, selection: $look.topColor)
            ChipRow(title: "帽子", selection: $look.hat)
            ColorRow(title: "帽子の色", colors: Palette.cloth, selection: $look.hatColor)
            ChipRow(title: "メガネ", selection: $look.glasses)
            ChipRow(title: "チェーン", selection: $look.chain)
            Toggle("ピアス", isOn: $look.earring)

            Button("🎲 ランダムにする") { look = .random() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ChipRow<T: OptionEnum>: View {
    let title: String
    @Binding var selection: T

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(T.allCases)) { option in
                        Button(option.label) { selection = option }
                            .buttonStyle(.bordered)
                            .tint(option == selection ? .orange : .gray)
                    }
                }
            }
        }
    }
}

struct ColorRow: View {
    let title: String
    let colors: [UInt32]
    @Binding var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors.indices, id: \.self) { i in
                        Circle().fill(Color(hex: colors[i]))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle().stroke(selection == i ? Color.orange : Color.gray.opacity(0.3),
                                                lineWidth: selection == i ? 4 : 1)
                            )
                            .onTapGesture { selection = i }
                    }
                }
                .padding(4)
            }
        }
    }
}
