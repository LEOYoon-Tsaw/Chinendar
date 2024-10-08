//
//  Welcome.swift
//  Chinendar
//
//  Created by Leo Liu on 8/4/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Icon(watchLayout: viewModel.watchLayout)
                    .frame(width: 120, height: 120)
                Text("CHINENDAR")
                    .font(.largeTitle.bold())
                HStack {
                    Image(systemName: "menubar.rectangle")
                        .font(.largeTitle)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("WKM_1_TITLE")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .padding(.vertical, 5)
                            .padding(.trailing, 5)
                        Text("WKM_1_DETAIL")
                    }
                }
                .padding(.top, 5)
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.largeTitle)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("WKM_2_TITLE")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .padding(.vertical, 5)
                            .padding(.trailing, 5)
                        Text("WKM_2_DETAIL")
                    }
                }
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.largeTitle)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("WKM_3_TITLE")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .padding(.vertical, 5)
                            .padding(.trailing, 5)
                        Text("WKM_3_DETAIL")
                    }
                }
            }
            .padding(20)
        }
    }
}

#Preview("Welcome", traits: .modifier(SampleData())) {
    Welcome()
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400, minHeight: 400, idealHeight: 600, maxHeight: 700, alignment: .center)
}
