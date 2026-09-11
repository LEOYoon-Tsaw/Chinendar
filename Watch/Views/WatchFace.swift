//
//  WatchFace.swift
//  Chinendar
//
//  Created by Leo Liu on 6/30/23.
//

import SwiftUI

struct WatchFace<Content: View>: View {
    @Binding var entityPresenting: EntitySelection
    let proxy: GeometryProxy
    @State var tapPos: CGPoint?
    @ViewBuilder let content: () -> Content
    @State var touchState = PressState()

    func tapped(tapPosition: CGPoint, proxy: GeometryProxy, size: CGSize) {
        var tapPosition = tapPosition
        tapPos = tapPosition
        tapPosition.x -= (proxy.size.width - size.width) / 2
        tapPosition.y -= (proxy.size.height - size.height) / 2
        entityPresenting.activeNote = []
        for mark in entityPresenting.entityNotes.entities {
            let diff = tapPosition - mark.position
            let dist = sqrt(diff.x * diff.x + diff.y * diff.y)
            if dist.isFinite && dist < 5 * min(size.width, size.height) * Marks.markSize {
                entityPresenting.activeNote.append(mark)
            }
        }
    }

    var body: some View {
        ZStack {
            content()
                .environment(\.directedScale, DirectedScale(value: touchState.pressing ? -0.1 : 0.0, anchor: pressAnchor(pos: touchState.location, size: proxy.size, proxy: proxy)))
                .gesture(touchState.gesture)
            Hover(entityPresenting: entityPresenting, tapPos: $tapPos)
        }
        .onChange(of: touchState.tapped) { _, newValue in
            if newValue {
                tapped(tapPosition: touchState.location!, proxy: proxy, size: proxy.size)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: entityPresenting.activeNote)
        .animation(.easeInOut(duration: 0.2), value: tapPos)
    }
}

struct WatchFaceDate: View {
    let proxy: GeometryProxy
    @Environment(ViewModel.self) var viewModel
    @State var entityPresenting = EntitySelection()

    var body: some View {
        WatchFace(entityPresenting: $entityPresenting, proxy: proxy) {
            DateWatch(size: proxy.size, displaySolarTerms: false, compact: true, watchLayout: viewModel.watchLayout, markSize: 1.5, chineseCalendar: viewModel.chineseCalendar, highlightType: .flicker, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: viewModel.settings.size.width, height: viewModel.settings.size.height)
        }
    }
}

struct WatchFaceTime: View {
    let proxy: GeometryProxy
    @Environment(ViewModel.self) var viewModel
    @State var entityPresenting = EntitySelection()

    var body: some View {
        WatchFace(entityPresenting: $entityPresenting, proxy: proxy) {
            TimeWatch(size: proxy.size, matchZeroRingGap: false, displaySubquarter: true, compact: true, watchLayout: viewModel.watchLayout, markSize: 1.5, chineseCalendar: viewModel.chineseCalendar, highlightType: .flicker, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: viewModel.settings.size.width, height: viewModel.settings.size.height)
        }
    }
}

struct WatchFaceFull: View {
    let proxy: GeometryProxy
    @Environment(ViewModel.self) var viewModel
    @State var entityPresenting = EntitySelection()

    var body: some View {
        WatchFace(entityPresenting: $entityPresenting, proxy: proxy) {
            Watch(size: proxy.size, displaySubquarter: true, displaySolarTerms: false, compact: true, watchLayout: viewModel.watchLayout, markSize: 1.3, chineseCalendar: viewModel.chineseCalendar, highlightType: .flicker, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: viewModel.settings.size.width, height: viewModel.settings.size.height)
        }
    }
}

#Preview("Date", traits: .modifier(SampleData())) {
    @Previewable @Environment(ViewModel.self) var viewModel
    GeometryReader { proxy in
        WatchFaceDate(proxy: proxy)
            .onAppear {
                viewModel.settings.size = proxy.size
            }
    }
    .ignoresSafeArea()
}

#Preview("Time", traits: .modifier(SampleData())) {
    @Previewable @Environment(ViewModel.self) var viewModel
    GeometryReader { proxy in
        WatchFaceTime(proxy: proxy)
            .onAppear {
                viewModel.settings.size = proxy.size
            }
    }
    .ignoresSafeArea()
}

#Preview("Full", traits: .modifier(SampleData())) {
    @Previewable @Environment(ViewModel.self) var viewModel
    GeometryReader { proxy in
        WatchFaceFull(proxy: proxy)
            .onAppear {
                viewModel.settings.size = proxy.size
            }
    }
    .ignoresSafeArea()
}
