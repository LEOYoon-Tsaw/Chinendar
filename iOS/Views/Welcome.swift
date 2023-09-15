//
//  Welcome.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 10)
                        .frame(maxHeight: 20)
                    Image(.image)
                        .resizable()
                        .frame(width: 120, height: 120)
                    Text("華曆", comment: "Chinese Time")
                        .font(.largeTitle.bold())
                    Spacer(minLength: 10)
                        .frame(maxHeight: 20)
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.largeTitle)
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("輪式設計", comment: "Welcome, ring design - title")
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                    .padding(.trailing, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("採用錶盤式設計，不同於以往日曆形制。一年、一月、一日、一時均週而復始，最適以「輪」代表。呈現細節之外，亦不失大局。", comment: "Welcome, ring design - detail")
                                    .font(.subheadline)
                            }
                        }
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("長按錶盤進設置", comment: "Welcome, long press - title")
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                    .padding(.trailing, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("設置更改後自動保存。可調時間、在地、外觀等。另有更多有關華曆之介紹。", comment: "Welcome, long press - detail")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 15)
                .frame(maxHeight: 25)
            
            Button {
                dismiss()
            } label: {
                Text("閱", comment: "Ok")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 15))
        }
        .padding()
    }
}


#Preview("Welcome") {
    Welcome()
}
