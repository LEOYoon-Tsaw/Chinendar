//
//  WatchFace.swift
//  Chinendar
//
//  Created by Leo Liu on 6/25/23.
//

import SwiftUI
import WidgetKit
import StoreKit

struct WatchFace: View {
    @Environment(ChineseCalendar.self) var chineseCalendar
    @Environment(WatchLayout.self) var watchLayout
    @Environment(CalendarConfigure.self) var calendarConfigure
    @Environment(WatchSetting.self) var watchSetting
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview
    @State var showWelcome = false
    @State var entityPresenting = EntitySelection()
    @State var touchState = PressState()
    @State var hoverBounds: CGRect = .zero
    @State var tapPos: CGPoint?
    @State var timer: Timer?
    @GestureState private var dragging = false

    @MainActor var presentSetting: Binding<Bool> {
        .init(get: { watchSetting.presentSetting }, set: { newValue in
            watchSetting.presentSetting = newValue
            if !newValue {
                if ThemeData.experienced() {
                    requestReview()
                }
            }
        })
    }
    
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
            let gesture = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($dragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    touchState.pressing = true
                    touchState.location = value.location
                }
            
            ZStack {
                Watch(displaySubquarter: true, displaySolarTerms: true, compact: false, watchLayout: watchLayout, markSize: 1.0, chineseCalendar: chineseCalendar, highlightType: .flicker, widthScale: 0.9, centerOffset: centerOffset, entityNotes: entityPresenting.entityNotes, textShift: true)
                    .frame(width: size.width, height: size.height)
                    .position(CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                    .environment(\.directedScale, DirectedScale(value: touchState.pressing ? -0.1 : 0.0, anchor: pressAnchor(pos: touchState.location, size: size, proxy: proxy)))
                    .gesture(gesture)
                
                Hover(entityPresenting: entityPresenting, bounds: $hoverBounds, tapPos: $tapPos)
            }
            .onChange(of: dragging) { _, newValue in
                if newValue {
                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        Task { @MainActor in
                            if !watchSetting.presentSetting {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                watchSetting.presentSetting = true
                                touchState.ended = true
                            }
                        }
                    }
                } else {
                    timer?.invalidate()
                    if touchState.tapped {
                        tapped(tapPosition: touchState.location!, proxy: proxy, size: size)
                    }
                    touchState.pressing = false
                    touchState.location = nil
                    touchState.ended = false
                }
            }
            .onChange(of: proxy.size) {
                watchSetting.vertical = proxy.size.height >= proxy.size.width
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
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .inactive, .background:
                WidgetCenter.shared.reloadAllTimelines()
            default:
                break
            }
        }
    }
}

#Preview("Watch Face") {
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()
    
    return WatchFace()
        .modelContainer(DataSchema.container)
        .environment(chineseCalendar)
        .environment(locationManager)
        .environment(watchLayout)
        .environment(calendarConfigure)
        .environment(watchSetting)
}
