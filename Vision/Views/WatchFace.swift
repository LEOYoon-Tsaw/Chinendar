//
//  WatchFace.swift
//  Chinendar
//
//  Created by Leo Liu on 11/14/23.
//

import SwiftUI

@MainActor
struct WatchFace: View {
    @Environment(\.chineseCalendar) var chineseCalendar
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State var showWelcome = false
    @State var entityPresenting = EntitySelection()
    @State var tapPos: CGPoint? = nil
    @State var hoverBounds: CGRect = .zero
    @GestureState var longPressed = false
    
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
        LongPressGesture(minimumDuration: 0.5)
            .updating($longPressed) { currentState, gestureState,
                transaction in
                gestureState = currentState
            }
    }
    
    func mainSize(proxy: GeometryProxy) -> CGSize {
        var idealSize = watchLayout.watchSize
        if proxy.size.height < proxy.size.width {
            let width = idealSize.width
            idealSize.width = idealSize.height
            idealSize.height = width
        }
        if proxy.size.width * 0.95 < idealSize.width {
            let ratio = proxy.size.width * 0.95 / idealSize.width
            idealSize.width *= ratio
            idealSize.height *= ratio
        }
        if proxy.size.height * 0.95 < idealSize.height {
            let ratio = proxy.size.height * 0.95 / idealSize.height
            idealSize.width *= ratio
            idealSize.height *= ratio
        }
        return idealSize
    }
    
    var body: some View {
        GeometryReader { proxy in

            let size = watchLayout.watchSize
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
            .onChange(of: proxy.size) {
                watchSetting.vertical = proxy.size.height >= proxy.size.width
                watchLayout.watchSize = proxy.size
            }
            .animation(.easeInOut(duration: 0.2), value: entityPresenting.activeNote)
        }
        .sheet(isPresented: $showWelcome) {
            Welcome(size: CGSizeMake(watchLayout.watchSize.width * 0.8, watchLayout.watchSize.height * 0.8))
        }
        .task(priority: .background) {
            showWelcome = ThemeData.latestVersion() < ThemeData.version
        }
    }
}

#Preview("Watch Face") {
    WatchFace()
}
