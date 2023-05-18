/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller that manages the scanning process.
*/

import RoomPlan
import SceneKit
import UIKit


class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    
    @IBOutlet var exportButton: UIButton?
    
    @IBOutlet var doneButton: UIBarButtonItem?
    @IBOutlet var cancelButton: UIBarButtonItem?
    
    private var isScanning: Bool = false
    
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
    private var finalResults: CapturedRoom?
    
    private var sceneView: SCNView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up after loading the view.
        setupRoomCaptureView()
    }
    
    
     private func onModelReady(model: CapturedRoom) {
         let walls = getAllNodes(for: model.walls,
                                 length: 0.1,
                                 contents: UIImage(named: "wallTexture"))
         walls.forEach { sceneView?.scene?.rootNode.addChildNode($0) }
         let doors = getAllNodes(for: model.doors,
                                 length: 0.11,
                                 contents: UIImage(named: "doorTexture"))
         doors.forEach { sceneView?.scene?.rootNode.addChildNode($0) }
         let windows = getAllNodes(for: model.windows,
                                   length: 0.11,
                                   contents: UIImage(named: "windowTexture"))
         windows.forEach { sceneView?.scene?.rootNode.addChildNode($0) }
         let openings = getAllNodes(for: model.openings,
                                   length: 0.11,
                                    contents: UIColor.blue.withAlphaComponent(0.5))
         openings.forEach { sceneView?.scene?.rootNode.addChildNode($0) }
        //Capture dimensions objects
         for object in model.objects {
             let uuidString = object.identifier.uuidString
             let categoryString = RoomPlanExampleApp.text(for: object.category)
             let position = object.transform.translation()
             let dimensions = object.dimensions
             print("object: identifier: \(uuidString), category: \(categoryString), position: \(position), dimensions: \(dimensions)")
         }
        
     }
     
     private func getAllNodes(for surfaces: [CapturedRoom.Surface], length: CGFloat, contents: Any?) -> [SCNNode] {
         var nodes: [SCNNode] = []
         surfaces.forEach { surface in
             let width = CGFloat(surface.dimensions.x)
             let height = CGFloat(surface.dimensions.y)
             
             NSLog("Height: \(height)  \n============\n")
             NSLog("Width: \(width)  \n============\n")
             let node = SCNNode()
             node.geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.0)
             node.geometry?.firstMaterial?.diffuse.contents = contents
             node.transform = SCNMatrix4(surface.transform)
             nodes.append(node)
         }
         return nodes
     }
    
    struct ObjectModel: Equatable {
        var dimensions: simd_float3
        var transform: simd_float4x4
        var category: CapturedRoom.Object.Category

        init(dimensions: simd_float3, transform: simd_float4x4, category: CapturedRoom.Object.Category) {
            self.dimensions = dimensions
            self.transform = transform
            self.category = category
        }
    }
        
    
    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
        
        view.insertSubview(roomCaptureView, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ flag: Bool) {
        super.viewWillDisappear(flag)
        stopSession()
    }
    
    private func startSession() {
        isScanning = true
        roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
        
        setActiveNavBar()
    }
    
    private func stopSession() {
        isScanning = false
        roomCaptureView?.captureSession.stop()
        
        
        setCompleteNavBar()
    }
    
    // Decide to post-process and show the final results.
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        
        return true
    }
    
    // Access the final post-processed results.
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        onModelReady(model: processedResult)
        finalResults = processedResult
    }
    
    @IBAction func doneScanning(_ sender: UIBarButtonItem) {
        if isScanning { stopSession() } else { cancelScanning(sender) }
    }

    @IBAction func cancelScanning(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    
    // Export the USDZ output by specifying the `.parametric` export option.
    // Alternatively, `.mesh` exports a nonparametric file and `.all`
    // exports both in a single USDZ.
    @IBAction func exportResults(_ sender: UIButton) {
        let destinationURL = FileManager.default.temporaryDirectory.appending(path: "Room.usdz")
        
        do {
            try finalResults?.export(to: destinationURL, exportOptions: .parametric)
            
            let activityVC = UIActivityViewController(activityItems: [destinationURL], applicationActivities: nil)
            activityVC.modalPresentationStyle = .popover
            
            present(activityVC, animated: true, completion: nil)
            if let popOver = activityVC.popoverPresentationController {
                popOver.sourceView = self.exportButton
            }
        } catch {
            print("Error = \(error)")
        }
    }
    
    private func setActiveNavBar() {
        UIView.animate(withDuration: 1.0, animations: {
            self.cancelButton?.tintColor = .white
            self.doneButton?.tintColor = .white
            self.exportButton?.alpha = 0.0
        }, completion: { complete in
            self.exportButton?.isHidden = true
        })
    }
    
    private func setCompleteNavBar() {
        self.exportButton?.isHidden = false
        UIView.animate(withDuration: 1.0) {
            self.cancelButton?.tintColor = .systemBlue
            self.doneButton?.tintColor = .systemBlue
            self.exportButton?.alpha = 1.0
        }
    }
}

