//
//  WatchFaceView.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/25/23.
//

import SwiftUI
import WidgetKit

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
    var presentSetting: Binding<Bool> {
        .init(get: { watchSetting.presentSetting }, set: { newValue in
            watchSetting.presentSetting = newValue
            if !newValue {
                watchLayout.saveDefault(context: modelContext)
                WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
            }
        })
    }
    
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
            .onEnded { finished in
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                watchSetting.presentSetting = finished
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
            let size = mainSize(proxy: proxy)
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
            .onChange(of: proxy.size) { _, newSize in
                watchSetting.vertical = newSize.height >= newSize.width
            }
            .animation(.easeInOut(duration: 0.2), value: entityPresenting.activeNote)
        }
        .sheet(isPresented: $showWelcome) {
            Welcome()
        }
        .inspector(isPresented: presentSetting) {
            Setting()
                .presentationBackground(.thinMaterial)
                .inspectorColumnWidth(min: 350, ideal: 400, max: 500)
        }
        .task(priority: .background) {
            showWelcome = ThemeData.latestVersion() < ThemeData.version
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive, .background:
                WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
                WidgetCenter.shared.reloadAllTimelines()
                watchLayout.saveDefault(context: modelContext)
                try? modelContext.save()
            default:
                break
            }
        }
    }
}

#Preview("Watch Face") {
    WatchFace()
}
