//
//  WatchFace.swift
//  Chinendar
//
//  Created by Leo Liu on 6/30/23.
//

import SwiftUI

@MainActor
struct WatchFace<Content: View>: View {
    @Binding var entityPresenting: EntitySelection
    @State var tapPos: CGPoint? = nil
    @State var hoverBounds: CGRect = .zero
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
        GeometryReader { proxy in
            let gesture = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    touchState.pressing = true
                    touchState.location = value.location
                }
                .onEnded { value in
                    if touchState.tapped {
                        tapped(tapPosition: touchState.location!, proxy: proxy, size: proxy.size)
                    }
                    touchState.pressing = false
                    touchState.location = nil
                }
            
            ZStack {
                content()
                    .environment(\.directedScale, DirectedScale(value: touchState.pressing ? -0.1 : 0.0, anchor: pressAnchor(pos: touchState.location, size: proxy.size, proxy: proxy)))
                    .gesture(gesture)
                Hover(entityPresenting: entityPresenting, bounds: $hoverBounds, tapPos: $tapPos)
            }
            .animation(.easeInOut(duration: 0.2), value: tapPos)
        }
    }
}

@MainActor
struct WatchFaceDate: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.chineseCalendar) var chineseCalendar
    @State var entityPresenting = EntitySelection()
    
    var body: some View {
        WatchFace(entityPresenting: $entityPresenting) {
            DateWatch(displaySolarTerms: false, compact: true,
                      watchLayout: watchLayout, markSize: 1.5, chineseCalendar: chineseCalendar, highlightType: .flicker, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: watchSetting.size.width, height: watchSetting.size.height)
        }
    }
}

@MainActor
struct WatchFaceTime: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.chineseCalendar) var chineseCalendar
    @State var entityPresenting = EntitySelection()
    
    var body: some View {
        WatchFace(entityPresenting: $entityPresenting) {
            TimeWatch(matchZeroRingGap: false, displaySubquarter: true, compact: true, watchLayout: watchLayout, markSize: 1.5, chineseCalendar: chineseCalendar, highlightType: .flicker, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: watchSetting.size.width, height: watchSetting.size.height)
        }
    }
}

@MainActor
struct WatchFaceFull: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.chineseCalendar) var chineseCalendar
    @State var entityPresenting = EntitySelection()
    
    var body: some View {
        WatchFace(entityPresenting: $entityPresenting) {
            Watch(displaySubquarter: true, displaySolarTerms: false, compact: true,
                  watchLayout: watchLayout, markSize: 1.3, chineseCalendar: chineseCalendar, highlightType: .flicker, entityNotes: entityPresenting.entityNotes, shrink: false)
            .frame(width: watchSetting.size.width, height: watchSetting.size.height)
        }
    }
}

#Preview("Date") {
    @Environment(\.watchSetting) var watchSetting
    
    return GeometryReader { proxy in
        WatchFaceDate()
            .onAppear{
                watchSetting.size = proxy.size
            }
    }
    .ignoresSafeArea()
}

#Preview("Time") {
    @Environment(\.watchSetting) var watchSetting
    
    return GeometryReader { proxy in
        WatchFaceTime()
            .onAppear{
                watchSetting.size = proxy.size
            }
    }
    .ignoresSafeArea()
}

#Preview("Full") {
    @Environment(\.watchSetting) var watchSetting
    
    return GeometryReader { proxy in
        WatchFaceFull()
            .onAppear{
                watchSetting.size = proxy.size
            }
    }
    .ignoresSafeArea()
}
