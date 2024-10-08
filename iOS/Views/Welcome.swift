//
//  Welcome.swift
//  Chinendar
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 10)
                        .frame(maxHeight: 20)
                    Icon(watchLayout: viewModel.watchLayout)
                        .frame(width: 120, height: 120)
                    Text("CHINENDAR")
                        .font(.largeTitle.bold())
                    Spacer(minLength: 10)
                        .frame(maxHeight: 20)
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.largeTitle)
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("WKM_1_TITLE")
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                    .padding(.trailing, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_1_DETAIL")
                                    .font(.subheadline)
                            }
                        }
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("WKM_2_TITLE")
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                    .padding(.trailing, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_2_DETAIL")
                                    .font(.subheadline)
                            }
                        }
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("WKM_3_TITLE")
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                    .padding(.trailing, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("WKM_3_DETAIL")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 15)
                .frame(maxHeight: 25)

            Button {
                dismiss()
            } label: {
                Text("OK")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 15))
        }
        .padding()
    }
}

#Preview("Welcome", traits: .modifier(SampleData())) {
    Welcome()
}
