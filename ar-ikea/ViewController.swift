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

  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
    itemsCollectionView.dataSource = self
    itemsCollectionView.delegate = self
    registerGestureRecognizers()
  }
}

/// MARK: Helper
private extension ViewController {
  /// Adds tap gesture recognizer to scene view.
  func registerGestureRecognizers() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }

  /// Handles taps on scene view.
  @objc func tapped(sender: UITapGestureRecognizer) {
    let sceneView = sender.view as! ARSCNView
    let tapLocation = sender.location(in: sceneView)
    let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
    if !hitTest.isEmpty {
      addItem(hitTestResult: hitTest.first!)
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
    sceneView.scene.rootNode.addChildNode(node)
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

