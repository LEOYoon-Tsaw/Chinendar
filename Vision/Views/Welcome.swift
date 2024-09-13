//
//  Welcome.swift
//  Chinendar
//
//  Created by Leo Liu on 11/17/23.
//

import SwiftUI

struct Welcome: View {
    let size: CGSize
    @Environment(\.dismiss) var dismiss
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        let baseLength = min(size.width, size.height)
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: baseLength / 25) {
                    Spacer(minLength: baseLength / 50)
                        .frame(maxHeight: baseLength / 25)
                    Icon(watchLayout: viewModel.watchLayout)
                        .frame(width: baseLength / 4, height: baseLength / 4)
                    Text("華曆", comment: "Chinendar")
                        .font(.largeTitle.bold())
                    Spacer(minLength: baseLength / 50)
                        .frame(maxHeight: baseLength / 25)
                    VStack(spacing: baseLength / 25) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.largeTitle)
                                .frame(width: baseLength / 6, height: baseLength / 6)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("輪式設計", comment: "Welcome, ring design - title")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("採用錶盤式設計，不同於以往日曆形制。一年、一月、一日、一時均週而復始，最適以「輪」代表。呈現細節之外，亦不失大局。", comment: "Welcome, ring design - detail")
                                    .font(.body)
                            }
                        }
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .frame(width: baseLength / 6, height: baseLength / 6)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("定製自己的專屬風格", comment: "Welcome, setting - title")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("設置位於錶盤正下方，更改後自動保存。可調時間、在地、外觀等。另有更多有關華曆之介紹。", comment: "Welcome, setting - detail")
                                    .font(.body)
                            }
                        }
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .frame(width: baseLength / 6, height: baseLength / 6)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("新功能", comment: "Welcome, new features - title")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("新增功能詳情", comment: "Welcome, new features detail")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: baseLength / 50)
                .frame(maxHeight: baseLength / 25)

            Button {
                dismiss()
            } label: {
                Text("閱", comment: "Ok")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: size.width, height: size.height)
    }
}

#Preview("Welcome", traits: .modifier(SampleData())) {
    Welcome(size: CGSize(width: 396, height: 484))
}
