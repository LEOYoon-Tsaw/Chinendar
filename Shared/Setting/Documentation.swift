//
//  Documentation.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI

extension MarkdownElement {
#if os(iOS)
    typealias SysFont = UIFont
#elseif os(macOS)
    typealias SysFont = NSFont
#endif
    
    var attributeContainer: AttributeContainer {
      var container = AttributeContainer()
      switch self {
      case .heading:
          container.font = .systemFont(ofSize: SysFont.systemFontSize * 1.05)
      case .paragraph:
          container.font = .systemFont(ofSize: SysFont.systemFontSize / 1.05)
      }
      return container
    }
}

struct Documentation: View {
    struct Paragraph: Identifiable {
        var id = UUID()
        let title: AttributedString
        let body: [AttributedString]
        var show: Bool = false
    }
    
    private let parser = MarkdownParser()
    @State var articles: [Paragraph] = []
    @Environment(\.watchSetting) var watchSetting
    
    var body: some View {
        Form {
            ForEach(articles) { article in
                Section {
                    HStack {
                        Text(article.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if article.show {
                            Image(systemName: "chevron.up")
                                .foregroundStyle(Color.accentColor)
                                .transition(.scale)
                        } else {
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Color.accentColor)
                                .transition(.scale)
                        }
                    }
                    .onTapGesture {
                        let index = articles.firstIndex { $0.id == article.id }!
                        withAnimation {
                            articles[index].show.toggle()
                        }
                    }
                    if article.show {
                        VStack(spacing: 10) {
                            ForEach(0..<article.body.count, id: \.self) { index in
                                Text(article.body[index])
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineSpacing(1.4)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
#if os(iOS)
        .listSectionSpacing(.compact)
#endif
        .task {
            prepareArticle(markdown: helpString)
        }
        .navigationTitle(Text("註釋", comment: "Documentation View"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
    
    func prepareArticle(markdown: String) {
        let elements = parser.parse(markdown)
        var articleInWork = [Paragraph]()
        var title = AttributedString()
        for element in elements {
            switch element {
            case .heading(let text):
                title = text.mergingAttributes(element.attributeContainer)
            case .paragraph(text: var text):
                for i in 0..<text.count {
                    text[i] = text[i].mergingAttributes(element.attributeContainer)
                }
                articleInWork.append(Paragraph(title: title, body: text))
            }
        }
        articles = articleInWork
    }
}

#Preview("Documentation") {
    Documentation()
#if os(macOS)
        .frame(width: 500, height: 300)
#endif
}
