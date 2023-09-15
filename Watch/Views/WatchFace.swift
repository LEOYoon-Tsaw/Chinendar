//
//  WatchFace.swift
//  Chinese Time Watch
//
//  Created by Leo Liu on 6/30/23.
//

import SwiftUI

@MainActor
struct WatchFace<Content: View>: View {
    @Binding var entityPresenting: EntitySelection
    @State var tapPos: CGPoint? = nil
    @State var hoverBounds: CGRect = .zero
    @GestureState var longPressed = false
    @ViewBuilder let content: () -> Content
    
    var tapGesture: some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tap in
                tapPos = tap.location
                let tapPosition = tap.location
                entityPresenting.activeNote = []
                for mark in entityPresenting.entityNotes.entities {
                    let diff = tapPosition - mark.position
                    let dist = sqrt(diff.x * diff.x + diff.y * diff.y)
                    if dist.isFinite && dist < 30 {
                        entityPresenting.activeNote.append(mark)
                    }
                }
            }
    }
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 3)
            .updating($longPressed) { currentState, gestureState,
                transaction in
                gestureState = currentState
            }
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                content()
                    .environment(\.scaleEffectScale, longPressed ? -0.1 : 0.0)
                    .environment(\.scaleEffectAnchor, pressAnchor(pos: tapPos, size: proxy.size, proxy: proxy))
                    .gesture(longPress)
                    .simultaneousGesture(tapGesture)
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
                      watchLayout: watchLayout, markSize: 1.5, chineseCalendar: chineseCalendar, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
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
            TimeWatch(matchZeroRingGap: false, displaySubquarter: true, compact: true, watchLayout: watchLayout, markSize: 1.5, chineseCalendar: chineseCalendar, widthScale: 1.5, entityNotes: entityPresenting.entityNotes, shrink: false)
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
                  watchLayout: watchLayout, markSize: 1.3, chineseCalendar: chineseCalendar, entityNotes: entityPresenting.entityNotes, shrink: false)
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
