import SceneKit
import SwiftUI
import UIKit

struct RickshawSceneView: View {
  private let scene: SCNScene = {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 2.2, z: 7)
    scene.rootNode.addChildNode(cameraNode)

    let floorNode = SCNNode(geometry: SCNFloor())
    floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
    scene.rootNode.addChildNode(floorNode)

    let autoNode = SCNNode()

    let body = SCNBox(width: 2.4, height: 0.8, length: 1.5, chamferRadius: 0.2)
    body.firstMaterial?.diffuse.contents = UIColor(Theme.mango)
    let bodyNode = SCNNode(geometry: body)
    bodyNode.position = SCNVector3(0, 0.6, 0)
    autoNode.addChildNode(bodyNode)

    let cab = SCNBox(width: 1.4, height: 1.0, length: 1.4, chamferRadius: 0.2)
    cab.firstMaterial?.diffuse.contents = UIColor(Theme.mint)
    let cabNode = SCNNode(geometry: cab)
    cabNode.position = SCNVector3(-0.4, 1.2, 0)
    autoNode.addChildNode(cabNode)

    let roof = SCNBox(width: 1.6, height: 0.2, length: 1.6, chamferRadius: 0.2)
    roof.firstMaterial?.diffuse.contents = UIColor(Theme.sky)
    let roofNode = SCNNode(geometry: roof)
    roofNode.position = SCNVector3(-0.4, 1.8, 0)
    autoNode.addChildNode(roofNode)

    for offset in [-0.9, 0.9] {
      let wheel = SCNCylinder(radius: 0.28, height: 0.25)
      wheel.firstMaterial?.diffuse.contents = UIColor(Theme.ink)
      let wheelNode = SCNNode(geometry: wheel)
      wheelNode.position = SCNVector3(Float(offset), 0.25, 0.7)
      wheelNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
      autoNode.addChildNode(wheelNode)

      let wheelNodeBack = SCNNode(geometry: wheel)
      wheelNodeBack.position = SCNVector3(Float(offset), 0.25, -0.7)
      wheelNodeBack.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
      autoNode.addChildNode(wheelNodeBack)
    }

    let bobUp = SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 1.2)
    bobUp.timingMode = .easeInEaseOut
    let bobDown = SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: 1.2)
    bobDown.timingMode = .easeInEaseOut
    autoNode.runAction(.repeatForever(.sequence([bobUp, bobDown])))

    scene.rootNode.addChildNode(autoNode)

    let spotlight = SCNLight()
    spotlight.type = .omni
    spotlight.intensity = 1200
    let lightNode = SCNNode()
    lightNode.light = spotlight
    lightNode.position = SCNVector3(0, 3, 4)
    scene.rootNode.addChildNode(lightNode)

    return scene
  }()

  var body: some View {
    SceneView(
      scene: scene,
      options: [.autoenablesDefaultLighting]
    )
    .frame(height: 160)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
  }
}
