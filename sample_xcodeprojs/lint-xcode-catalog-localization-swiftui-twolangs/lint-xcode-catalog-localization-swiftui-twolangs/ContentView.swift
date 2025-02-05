//
//  ContentView.swift
//  lint-xcode-catalog-localization.swiftui
//
//  Created by Sergi Hernanz on 31/1/25.
//

import SwiftUI

final class ViewModel {
    var sampleNSLocString: String {
        NSLocalizedString("nsloc1", comment: "Sample nslocalizedString 1")
    }
    var sampleNSLocStringAltComment: String {
        NSLocalizedString("nsloc1", comment: "Sample nslocalizedString 1 another comment")
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Missing translation")
            Text("Empty translation")
            // Text("commented translation")
            #if true
            Text("Not compiled translation")
            #endif
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(useKeys: String) {
        self.appendLiteral("ll")
    }
    mutating func appendInterpolation(useInt: Int) {
        self.appendLiteral("ll")
    }
}
