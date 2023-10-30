//
//  ARViewShootingApp.swift
//  ARViewShooting
//
//  Created by Katsuhiro Masaki on 2023/10/24.
//

import SwiftUI

@main
struct ARViewShootingApp: App {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @StateObject var game = Game()
    
    @State private var immersionStyle: ImmersionStyle = .mixed
    var body: some Scene {
        WindowGroup(id: "SwiftContent") {
            ContentView(game: game)
                .onChange(of: game.started, { _, newValue in
                    Task {
                        if newValue {
                            await openImmersiveSpace(id: "immersiveContent")
                        } else {
                            await dismissImmersiveSpace()
                        }
                    }
                })
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "immersiveContent") {
            ImmersiveContentView(game: game)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
