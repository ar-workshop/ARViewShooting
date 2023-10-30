//
//  ContentView.swift
//  ARViewShooting
//
//  Created by Katsuhiro Masaki on 2023/10/24.
//

import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @ObservedObject var game: Game
    
    var body: some View {
        VStack {
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

struct ImmersiveContentView: View {
    @ObservedObject var game: Game
    
    var body: some View {
        RealityView { content in
            content.add(game.root)
        } update: { content in
            for target in game.targets {
                game.root.addChild(target)
            }
        }.gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded({ value in
                    if let entity = value.entity as? ModelEntity {
                        if !game.shooted.contains(entity) {
                            game.shooted.append(entity)
                            let shootedMaterial = SimpleMaterial(color: .blue, isMetallic: true)
                            entity.model?.materials = [shootedMaterial]
                            if game.targets.count == game.shooted.count {
                                game.started = false
                                game.finish()
                            }
                        }
                    }
                })
        )
    }
}

class Game: ObservableObject {
    
    @Published var started = false
    @Published var targets: [ModelEntity] = []
    @Published var shooted: [ModelEntity] = []
    public let root = Entity()
    
    var worldInfo = WorldTrackingProvider()
    
    init() {
        setInitialCameraPosition()
    }
    
    func start() {
        clearTargets()
        for _ in 0..<5 {
            targets.append(addRandomTargets())
        }
    }
    
    func finish() {
        clearTargets()
    }
    
    func clearTargets() {
        targets.forEach { $0.removeFromParent() }
        targets = []
        shooted = []
    }
    
    func addRandomTargets() -> ModelEntity {
        let box = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let entity = ModelEntity(mesh: box, materials: [material])
        entity.collision = CollisionComponent(shapes: [ShapeResource.generateConvex(from: entity.model!.mesh)])
        entity.components.set(InputTargetComponent())
        
        let x: Float = Float.random(in: -0.5 ... 0.5)
        let y: Float = Float.random(in: -0.5 ... 0.5)
        let z: Float = Float.random(in: -1.0 ... -0.5)
        
        entity.position = simd_float3(x, y, z)
        
        return entity
    }
    
    func setInitialCameraPosition() {
#if targetEnvironment(simulator)
        root.position.y = 1.05
        root.position.z = -1
#else
        guard let pose = worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            root.position.y = 1.05
            root.position.z = -1
            return
        }
        let cameraMatrix = pose.originFromAnchorTransform
        let cameraTransform = Transform(matrix: cameraMatrix)
        root.position = cameraTransform.translation + cameraMatrix.forward * -0.5
#endif
    }
}

public extension simd_float4x4 {
    
    /// Returns the forward vector for the orientation represented by this matrix.
    var forward: SIMD3<Float> {
        simd_normalize(SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z))
    }
}

#Preview {
    ContentView(game: Game())
}
