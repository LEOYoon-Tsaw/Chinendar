//
//  HoverView.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI
import Observation

@MainActor
@Observable final class EntitySelection {
    @ObservationIgnored var entityNotes = EntityNotes()
    @ObservationIgnored var timer: Timer?
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
    @Environment(ViewModel.self) var viewModel
    @State var entityPresenting: EntitySelection
    @Binding var bounds: CGRect
    @Binding var tapPos: CGPoint?
    @State var isEastAsian = Locale.isEastAsian
    @State var prepared = true

    var body: some View {

        let shortEdge = min(viewModel.baseLayout.watchSize.width, viewModel.baseLayout.watchSize.height)
        let longEdge = min(viewModel.baseLayout.watchSize.width, viewModel.baseLayout.watchSize.height)
        let fontSize: CGFloat = min(shortEdge * 0.04, longEdge * 0.032)

        GeometryReader { proxy in
            if let tapPos, entityPresenting.activeNote.count > 0 {
                let idealPos = edgeSafePos(pos: tapPos, bounds: bounds, screen: proxy.size)
                if isEastAsian {
                    HStack(alignment: .top) {
                        ForEach(entityPresenting.activeNote) {note in
                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: fontSize * 0.2)
                                    .frame(width: fontSize, height: fontSize)
                                    .foregroundStyle(Color(cgColor: note.color))
                                    .padding(.vertical, fontSize * 0.08)
                                Spacer(minLength: fontSize * 0.2)
                                    .frame(maxHeight: fontSize * 0.2)
                                ForEach(Array(Locale.translate(note.name)), id: \.self) { char in
                                    Text(String(char))
                                        .font(.system(size: fontSize))
                                        .padding(0)
                                }
                            }
                        }
                    }
                    .padding(fontSize * 0.3)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: fontSize * 0.5, style: .continuous))
                    .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { proxy[$0] }
                    .onPreferenceChange(BoundsPreferenceKey.self) { [$bounds] newValue in
                        $bounds.wrappedValue = newValue
                    }
                    .position(idealPos)
                } else {
                    VStack(alignment: .leading) {
                        ForEach(entityPresenting.activeNote) {note in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: fontSize * 0.2)
                                    .frame(width: fontSize, height: fontSize)
                                    .foregroundStyle(Color(cgColor: note.color))
                                    .padding(.horizontal, fontSize * 0.08)
                                    .padding(.vertical, 0)
                                Spacer(minLength: fontSize * 0.2)
                                    .frame(maxWidth: fontSize * 0.2)
                                Text(Locale.translate(note.name))
                                    .font(.system(size: fontSize))
                                    .padding(0)
                            }
                        }
                    }
                    .padding(fontSize * 0.3)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: fontSize * 0.5, style: .continuous))
                    .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { proxy[$0] }
                    .onPreferenceChange(BoundsPreferenceKey.self) { [$bounds] newValue in
                        $bounds.wrappedValue = newValue
                    }
                    .position(idealPos)
                }
            }
        }
    }
}

private struct BoundsPreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }

}
