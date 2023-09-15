//
//  WatchFace.swift
//  Chinese Time mac
//
//  Created by Leo Liu on 7/1/23.
//

import SwiftUI

@MainActor
struct WatchFace: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.chineseCalendar) var chineseCalendar
    @State var entityPresenting = EntitySelection()
    @State var tapPos: CGPoint? = nil
    @State var hoverBounds: CGRect = .zero
    @GestureState var longPressed = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    func tapGesture(proxy: GeometryProxy, size: CGSize) -> some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tap in
                tapPos = tap.location
                var tapPosition = tap.location
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
            let size: CGSize = watchLayout.watchSize            
            let centerOffset = if size.height >= size.width {
                watchLayout.centerTextOffset
            } else {
                watchLayout.centerTextHOffset
            }
            
            ZStack {
                Watch(displaySubquarter: true, displaySolarTerms: true, compact: false, watchLayout: watchLayout, markSize: 1.0, chineseCalendar: chineseCalendar, widthScale: 0.9, centerOffset: centerOffset, entityNotes: entityPresenting.entityNotes, textShift: true)
                    .frame(width: size.width, height: size.height)
                    .position(CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                    .environment(\.scaleEffectScale, longPressed ? -0.1 : 0.0)
                    .environment(\.scaleEffectAnchor, pressAnchor(pos: tapPos, size: size, proxy: proxy))
                    .gesture(longPress)
                    .simultaneousGesture(tapGesture(proxy: proxy, size: size))
                
                Hover(entityPresenting: entityPresenting, bounds: $hoverBounds, tapPos: $tapPos)
            }
            .animation(.easeInOut(duration: 0.2), value: entityPresenting.activeNote)
        }
        .frame(width: watchLayout.watchSize.width, height: watchLayout.watchSize.height)
    }
}

#Preview("WatchFace") {
    WatchFace()
        .modelContainer(ThemeData.container)
}
