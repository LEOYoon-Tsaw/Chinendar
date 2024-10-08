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
                    Text("CHINENDAR")
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
                                Text("WKM_1_TITLE")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_1_DETAIL")
                                    .font(.body)
                            }
                        }
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .frame(width: baseLength / 6, height: baseLength / 6)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("WKM_2_TITLE")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_2_DETAIL")
                                    .font(.body)
                            }
                        }
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .frame(width: baseLength / 6, height: baseLength / 6)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("WKM_3_TITLE")
                                    .font(.title3)
                                    .padding(.vertical, baseLength / 100)
                                    .padding(.trailing, baseLength / 25)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_3_DETAIL")
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
                Text("OK")
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
