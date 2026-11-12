import AppKit
import SceneKit
import SwiftUI

struct CaseIllustration: NSViewRepresentable {
    let lidOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = makeScene()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.isPlaying = false
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        guard let lid = view.scene?.rootNode.childNode(withName: "lid", recursively: true) else { return }
        let angle: CGFloat = lidOpen ? -.pi * 0.58 : 0
        guard abs(lid.eulerAngles.x - angle) > 0.001 else { return }
        context.coordinator.generation += 1
        let generation = context.coordinator.generation
        view.isPlaying = true
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0 : 0.45
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        lid.eulerAngles.x = angle
        SCNTransaction.commit()
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.5)) { [weak view] in
            guard context.coordinator.generation == generation else { return }
            view?.isPlaying = false
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var generation = 0
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        let caseNode = SCNNode()
        caseNode.eulerAngles = SCNVector3(-0.12, -0.35, 0.02)
        scene.rootNode.addChildNode(caseNode)

        let shell = material(color: NSColor(white: 0.88, alpha: 1), roughness: 0.32)
        let inner = material(color: NSColor(white: 0.77, alpha: 1), roughness: 0.5)
        let body = box(width: 2.7, height: 1.35, depth: 0.84, radius: 0.31, material: shell)
        body.position.y = -0.28
        caseNode.addChildNode(body)

        let rim = box(width: 2.42, height: 0.055, depth: 0.65, radius: 0.18, material: inner)
        rim.position = SCNVector3(0, 0.405, 0)
        caseNode.addChildNode(rim)
        [-0.55, 0.55].forEach { x in
            let earbud = makeEarbud(material: shell)
            earbud.position = SCNVector3(Float(x), 0.48, 0.02)
            caseNode.addChildNode(earbud)
        }

        let lid = SCNNode()
        lid.name = "lid"
        lid.position = SCNVector3(0, 0.40, -0.40)
        let lidShell = box(width: 2.7, height: 0.64, depth: 0.84, radius: 0.28, material: shell)
        lidShell.position = SCNVector3(0, 0.30, 0.40)
        lid.addChildNode(lidShell)
        lid.eulerAngles.x = lidOpen ? -.pi * 0.58 : 0
        caseNode.addChildNode(lid)

        let light = SCNSphere(radius: 0.023)
        light.firstMaterial = material(color: NSColor(white: 0.62, alpha: 1), roughness: 0.5)
        let indicator = SCNNode(geometry: light)
        indicator.position = SCNVector3(0, -0.11, 0.425)
        caseNode.addChildNode(indicator)

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.75
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.45, 7)
        scene.rootNode.addChildNode(cameraNode)
        addLight(to: scene, type: .ambient, intensity: 240, rotation: SCNVector3Zero)
        addLight(to: scene, type: .directional, intensity: 650, rotation: SCNVector3(-0.55, -0.7, 0))
        addLight(to: scene, type: .directional, intensity: 160, rotation: SCNVector3(0.35, 1.2, 0))
        return scene
    }

    private func makeEarbud(material: SCNMaterial) -> SCNNode {
        let node = SCNNode()
        let stem = SCNCapsule(capRadius: 0.105, height: 0.55)
        stem.firstMaterial = material
        let stemNode = SCNNode(geometry: stem)
        stemNode.position.y = 0.14
        node.addChildNode(stemNode)
        let head = SCNSphere(radius: 0.19)
        head.firstMaterial = material
        let headNode = SCNNode(geometry: head)
        headNode.scale = SCNVector3(1.15, 0.8, 0.85)
        headNode.position = SCNVector3(0, 0.40, 0)
        node.addChildNode(headNode)
        let vent = SCNSphere(radius: 0.035)
        vent.firstMaterial = self.material(color: NSColor(white: 0.2, alpha: 1), roughness: 0.8)
        let ventNode = SCNNode(geometry: vent)
        ventNode.scale = SCNVector3(1, 0.55, 0.3)
        ventNode.position = SCNVector3(0, 0.42, 0.16)
        node.addChildNode(ventNode)
        return node
    }

    private func box(width: CGFloat, height: CGFloat, depth: CGFloat, radius: CGFloat, material: SCNMaterial) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: depth, chamferRadius: radius)
        geometry.firstMaterial = material
        return SCNNode(geometry: geometry)
    }

    private func material(color: NSColor, roughness: CGFloat) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.roughness.contents = roughness
        material.metalness.contents = 0
        return material
    }

    private func addLight(to scene: SCNScene, type: SCNLight.LightType, intensity: CGFloat, rotation: SCNVector3) {
        let light = SCNLight()
        light.type = type
        light.intensity = intensity
        let node = SCNNode()
        node.light = light
        node.eulerAngles = rotation
        scene.rootNode.addChildNode(node)
    }
}
