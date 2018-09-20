//
//  ScannerViewController.swift
//
//  Copyright © 2018. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol ScannerControllerDelegate {
    func didReceiveCode(code: String?)
}

@objc public class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    
    @objc var delegate: ScannerControllerDelegate?
    
    private var captureSession:AVCaptureSession!
    private var videoPreviewLayer:AVCaptureVideoPreviewLayer!
    private var objectFrameView:UIView?
    private let codeTypes:[AVMetadataObject.ObjectType]
    
    convenience init() {
        self.init(codeTypes: [.code39])
    }
    
   @objc init(codeTypes: [AVMetadataObject.ObjectType]) {
        self.codeTypes = codeTypes
        super.init(nibName: String(describing: ScannerViewController.self), bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    
    /**
     Setup settings
     */
    fileprivate func setupScanner() {
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = codeTypes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(videoPreviewLayer)
            view.bringSubview(toFront: backButton)
            view.bringSubview(toFront: qrCodeImageView)
            
            // Initialize QR Code Frame to highlight the QR code
            objectFrameView = UIView()
            
            if let qrCodeFrameView = objectFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            debugPrint(error)
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    /**
     Camera content delegate
     */
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        guard metadataObjects.count != 0 else {
            objectFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        switch metadataObjects[0] {
        case is AVMetadataMachineReadableCodeObject:
            var json = (metadataObjects[0] as! AVMetadataMachineReadableCodeObject).stringValue
            if let dict = convertToDictionary(text: json ?? "") {
                json = dict["id"] as? String
            }
            delegate?.didReceiveCode(code: json)
        default:
            break
        }
        
        delegate = nil
        if let last = metadataObjects.last, let object = videoPreviewLayer.transformedMetadataObject(for: last) {
            objectFrameView?.frame = object.bounds
        }
        
    }
}
