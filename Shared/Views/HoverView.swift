//
//  NamedEntity.swift
//  Chinese Time
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI
import Observation

@MainActor
@Observable class EntitySelection {
    @ObservationIgnored var entityNotes = EntityNotes()
    @ObservationIgnored var timer: Timer? = nil
    @ObservationIgnored var _activeNote: [EntityNotes.EntityNote] = [] {
        didSet {
            timer?.invalidate()
            if _activeNote.count > 0 {
                timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    Task { @MainActor in
                        self.activeNote = []
                    }
                }
            } else {
                timer = nil
            }
        }
    }
    var activeNote: [EntityNotes.EntityNote] {
        get {
            self.access(keyPath: \.activeNote)
            return _activeNote
        } set {
            self.withMutation(keyPath: \.activeNote) {
                _activeNote = newValue
            }
        }
    }
}

private func edgeSafePos(pos: CGPoint, bounds: CGRect, screen: CGSize) -> CGPoint {
    var idealPos = pos
    let boundSize = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    if idealPos.x < boundSize.x {
        idealPos.x = boundSize.x
    } else if idealPos.x + boundSize.x > screen.width {
        idealPos.x = screen.width - boundSize.x
    }
    if idealPos.y < boundSize.y {
        idealPos.y = boundSize.y
    } else if idealPos.y + boundSize.y > screen.height {
        idealPos.y = screen.height - boundSize.y
    }
    return idealPos
}

struct Hover: View {
    @Environment(\.watchLayout) var watchLayout
    @State var entityPresenting: EntitySelection
    @Binding var bounds: CGRect
    @Binding var tapPos: CGPoint?
    @State var isChinese = Locale.isChinese
    @State var prepared = true
    
    var body: some View {
        GeometryReader { proxy in
            if let tapPos = tapPos, entityPresenting.activeNote.count > 0 {
                let idealPos = edgeSafePos(pos: tapPos, bounds: bounds, screen: proxy.size)
                if isChinese {
                    HStack(alignment: .top) {
                        ForEach(entityPresenting.activeNote) {note in
                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: watchLayout.textFont.pointSize * 0.3)
                                    .frame(width: watchLayout.textFont.pointSize, height: watchLayout.textFont.pointSize)
                                    .foregroundStyle(Color(cgColor: note.color))
                                    .padding(.vertical, 1)
                                Spacer(minLength: 3)
                                    .frame(maxHeight: 3)
                                ForEach(Array(note.name), id: \.self) { char in
                                    Text(String(char))
                                        .font(.system(size: watchLayout.textFont.pointSize))
                                        .padding(0)
                                }
                            }
                        }
                    }
                    .padding(5)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { proxy[$0] }
                    .onPreferenceChange(BoundsPreferenceKey.self) { bounds = $0 }
                    .position(idealPos)
                } else {
                    VStack(alignment: .leading) {
                        ForEach(entityPresenting.activeNote) {note in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: watchLayout.textFont.pointSize * 0.3)
                                    .frame(width: watchLayout.textFont.pointSize, height: watchLayout.textFont.pointSize)
                                    .foregroundStyle(Color(cgColor: note.color))
                                    .padding(.horizontal, 1)
                                    .padding(.vertical, 0)
                                Spacer(minLength: 3)
                                    .frame(maxWidth: 3)
                                Text(Locale.translation[note.name] ?? "")
                                    .font(.system(size: watchLayout.textFont.pointSize))
                                    .padding(0)
                            }
                        }
                    }
                    .padding(5)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { proxy[$0] }
                    .onPreferenceChange(BoundsPreferenceKey.self) { bounds = $0 }
                    .position(idealPos)
                }
            }
        }
    }
}

private struct BoundsPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }

}
