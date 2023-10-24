//
//  ContentView.swift
//  ARViewShooting
//
//  Created by Katsuhiro Masaki on 2023/10/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @ObservedObject var game = Game(viewContainer: ARViewContainer())
    
    var body: some View {
        VStack {
            game.viewContainer.edgesIgnoringSafeArea(.all)
            ZStack(alignment: .center) {
                Button(game.started ? "Finish" : "Start") {
                    game.started.toggle()
                }
                .padding()
                if game.started {
                    HStack {
                        Spacer()
                        Text("\(game.shooted.count)")
                        Text("/")
                        Text("\(game.targets.count)")
                    }
                }
            }
        }
        .onChange(of: game.started, initial: false) { oldValue, newValue in
            if newValue {
                game.start()
            } else {
                game.finish()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arView = ARView(frame: .zero)
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func addRandomTargets() -> ModelEntity {
        let box = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let entity = ModelEntity(mesh: box, materials: [material])
        entity.collision = CollisionComponent(shapes: [.generateBox(width: 0.1, height: 0.1, depth: 0.1)])
        
        let x = Float.random(in: -0.5...0.5)
        let y = Float.random(in: -0.5...0.5)
        let z: Float = -0.2
        
        let anchor = AnchorEntity(world: simd_float3(x, y, z))
        anchor.addChild(entity)
        
        arView.scene.addAnchor(anchor)
        return entity
    }
}

class Game: ObservableObject {
    let viewContainer: ARViewContainer
    
    @Published var started = false
    @Published var targets: [ModelEntity] = []
    @Published var shooted: [ModelEntity] = []
    
    private var tapGesture: UITapGestureRecognizer!
    
    init(viewContainer: ARViewContainer) {
        self.viewContainer = viewContainer
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    }
    
    func start() {
        clearTargets()
        for _ in 0..<5 {
            targets.append(viewContainer.addRandomTargets())
        }
        viewContainer.arView.addGestureRecognizer(tapGesture)
    }
    
    func finish() {
        viewContainer.arView.removeGestureRecognizer(tapGesture)
        clearTargets()
    }
    
    func clearTargets() {
        targets.forEach { $0.removeFromParent() }
        targets = []
        shooted = []
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: viewContainer.arView)
        if let entity = viewContainer.arView.entity(at: tapLocation) as? ModelEntity {
            if !shooted.contains(entity) {
                shooted.append(entity)
                let shootedMaterial = SimpleMaterial(color: .blue, isMetallic: true)
                entity.model?.materials = [shootedMaterial]
                if targets.count == shooted.count {
                    started = false
                    finish()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
