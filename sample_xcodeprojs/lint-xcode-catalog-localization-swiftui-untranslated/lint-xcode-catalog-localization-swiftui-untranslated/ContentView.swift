//
//  ContentView.swift
//  lint-xcode-catalog-localization.swiftui
//
//  Created by Sergi Hernanz on 31/1/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Missing translation")
            Text("Empty translation")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
