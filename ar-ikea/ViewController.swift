//
//  ViewController.swift
//  ar-ikea
//
//  Created by Willie Johnson on 10/7/18.
//  Copyright © 2018 Willie Johnson. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var itemsCollectionView: UICollectionView!

  let configuration = ARWorldTrackingConfiguration()

  /// Addable furniture items.
  let itemsArray: [String] = ["cup", "vase", "boxing", "table"]

  /// The item that was selected in the collection view.
  var selectedItem: String?

  @IBOutlet weak var planeDetectedLabel: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
    itemsCollectionView.dataSource = self
    itemsCollectionView.delegate = self
    sceneView.delegate = self
    registerGestureRecognizers()
  }
}

/// MARK: Helper
private extension ViewController {
  /// Adds tap gesture recognizers to scene view.
  func registerGestureRecognizers() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
    let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
    let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
    longPressGestureRecognizer.minimumPressDuration = 0.1
    sceneView.addGestureRecognizer(tapGestureRecognizer)
    sceneView.addGestureRecognizer(pinchGestureRecognizer)
    sceneView.addGestureRecognizer(longPressGestureRecognizer)
    sceneView.autoenablesDefaultLighting = true
  }

  /// Handles taps on scene view.
  @objc func tapped(sender: UITapGestureRecognizer) {
    let sceneView = sender.view as! ARSCNView
    let tapLocation = sender.location(in: sceneView)
    let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

    // Check if there was an item tapped.
    if !hitTest.isEmpty {
      addItem(hitTestResult: hitTest.first!)
    }
  }

  @objc func pinched(sender: UIPinchGestureRecognizer) {
    // Hit test at location pinched.
    guard let sceneView = sender.view as? ARSCNView else { return }
    let pinchLocation = sender.location(in: sceneView)
    let hitTest = sceneView.hitTest(pinchLocation)

    // Check if there was an item pinched.
    if !hitTest.isEmpty {
      // Grab item pinched.
      guard let results = hitTest.first else { return }
      let node = results.node

      // Scale item based on pinch scale.
      let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
      node.runAction(pinchAction)

      // Reset gesture scale.
      sender.scale = 1.0
    }
  }

  /// Rotate the object based on long press gesture.
  @objc func rotate(sender: UILongPressGestureRecognizer) {
    guard let sceneView = sender.view as? ARSCNView else { return }
    let holdLocation = sender.location(in: sceneView)
    let hitTest = sceneView.hitTest(holdLocation)

    if !hitTest.isEmpty {
      guard let result = hitTest.first else { return }

      if sender.state == .began {
        let action = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
        let forever = SCNAction.repeatForever(action)
        result.node.runAction(forever)
      } else if sender.state == .ended {
        result.node.removeAllActions()
      }
    }
  }

  /// Adds the item item to detected plan based on item tapped in collection view.
  func addItem(hitTestResult: ARHitTestResult) {
    // Check if there's an item selected.
    guard let selectedItem = selectedItem else { return }

    // Grab item node from scene with same name.
    guard let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn") else { return }
    guard let node = scene.rootNode.childNode(withName: selectedItem, recursively: false) else { return }

    // Grab position information of detected plane.
    let transform = hitTestResult.worldTransform
    let thirdColumn = transform.columns.3

    // Position item at detected plane.
    node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
    if selectedItem == "table" {
      centerPivot(for: node)
    }
    sceneView.scene.rootNode.addChildNode(node)
  }

  func centerPivot(for node: SCNNode) {
    let min = node.boundingBox.min
    let max = node.boundingBox.max
    node.pivot = SCNMatrix4MakeTranslation(
      min.x + (max.x - min.x) / 2,
      min.y + (max.y - min.y) / 2,
      min.z + (max.z - min.z) / 2
    )
  }
}

/// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return itemsArray.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCell
    cell.itemLabel.text = itemsArray[indexPath.row]
    return cell
  }
}

/// MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath)
    cell?.backgroundColor = UIColor.green
    selectedItem = itemsArray[indexPath.row]
  }

  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath)
    cell?.backgroundColor = UIColor.orange
  }
}

/// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
    DispatchQueue.main.async {
      self.planeDetectedLabel.isHidden = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        self.planeDetectedLabel.isHidden = true
      }
    }
  }
}

extension Int {
  var degreesToRadians: Double { return Double(self) * .pi/180}
}

