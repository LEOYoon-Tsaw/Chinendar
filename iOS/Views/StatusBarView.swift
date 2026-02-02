//
//  StatusBarView.swift
//  Chinendar
//
//  Created by Leo Liu on 1/31/26.
//

import SwiftUI

struct StatusBarView: View {
    let text: String
    let proxy: GeometryProxy
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Group {
                    if horizontalSizeClass == .compact && proxy.size.height > proxy.size.width {
                        Text(text)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(text)
                            .frame(minWidth: 180)
                    }
                }
                .lineLimit(1)
                .padding()
                .glassEffect(.clear)
                .shadow(color: .gray.opacity(0.25), radius: 10)
                .padding(.vertical, proxy.safeAreaInsets.bottom * 0.5 + 5)
                .padding(.horizontal, proxy.safeAreaInsets.bottom * 0.5 + 10)
            }
            .ignoresSafeArea(edges: .bottom)
    }
}

#Preview("StatusBar", traits: .modifier(SampleData())) {
    @Previewable @Environment(ViewModel.self) var viewModel
    let dateText = statusBarString(from: viewModel.chineseCalendar, options: viewModel.watchLayout)
    GeometryReader { proxy in
        StatusBarView(text: dateText, proxy: proxy)
    }
}
