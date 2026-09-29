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
    @State private var tapManager = TapManager()

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
                .glassEffect(.clear, in: .capsule)
                .onTapGesture {
                    tapManager.tap()
                }
                .shadow(color: .gray.opacity(0.25), radius: 10)
                .padding(.bottom, proxy.safeAreaInsets.bottom * 0.5 + 5)
                .padding(.horizontal, proxy.safeAreaInsets.bottom * 0.5 + 10)
                .opacity(tapManager.opacity)
                .animation(.easeIn(duration: 0.5), value: tapManager.opacity)
            }
            .ignoresSafeArea(edges: .bottom)
    }
}

@Observable @MainActor
private final class TapManager {
    private var tapped: Bool = false
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?
    var opacity: CGFloat {
        if tapped { 0.2 } else { 1.0 }
    }

    func tap() {
        timeoutTask?.cancel()
        timeoutTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                tapped = false
            }
        }
        tapped = true
    }
}

#Preview("StatusBar", traits: .modifier(SampleData())) {
    @Previewable @Environment(ViewModel.self) var viewModel
    let dateText = statusBarString(from: viewModel.chineseCalendar, options: viewModel.watchLayout)
    GeometryReader { proxy in
        StatusBarView(text: dateText, proxy: proxy)
    }
}
