//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//
import AVFoundation
import UIKit

class CameraViewController: UIViewController {

    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    
    private var player: AVPlayer!
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!


	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        setUpCamera()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(tapGesture:)))
        view.addGestureRecognizer(tapGesture)
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    // comment for commit 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.startRunning()
    }
    
    
    private func bestAudio() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        fatalError("No audio")
    }
    
    func playMovie(url: URL) {
        player = AVPlayer(url: url)
        
        let playerLayer = AVPlayerLayer(player: player)
        
        var topRect = view.bounds
        topRect.size.height = topRect.height / 4
        topRect.size.width = topRect.width / 4
        topRect.origin.y = view.layoutMargins.top
        
        playerLayer.frame = topRect
        view.layer.addSublayer(playerLayer)
        
        player.play()
    }
    
    @objc func handleTapGesture(tapGesture: UITapGestureRecognizer) {
        print("tap")
        
        switch tapGesture.state {
        case .ended:
            replayMovie()
            
        default:
            print("handle other states: \(tapGesture.state)")
        }
        
        
    }
    
    func replayMovie() {
        if let player = player {
            player.seek(to: CMTime.zero) // CMTime(0, 30)
            
            player.play()
        }
    }
    
    
    private func setUpCamera() {
        let camera = bestCamera()
        // configuration
        captureSession.beginConfiguration()
        
        // Inputs
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Device congigured incorreclty")
        }
        
        guard captureSession.canAddInput(cameraInput) else {
            fatalError("Unable to add camera input")
        }
        captureSession.addInput(cameraInput)
        
        // 1920x1080p
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        
        // Microphone
        let microphone = bestAudio()
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone) else {
            fatalError("Can't create input from microphone")
        }
        guard captureSession.canAddInput(audioInput) else {
            fatalError("Can't add audio input")
        }
        captureSession.addInput(audioInput)
        
        
        // Outputs
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannt add file output")
        }
        captureSession.addOutput(fileOutput)
        
        
        
        // commit configuration
        captureSession.commitConfiguration()
        
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        // front / back
        // wide angle, ultra wide angle, depth, zoom lens
        
        // try ultraWide
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        // try wide angle lens
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        fatalError("No Cameras availab;e on device or you are using a simulator")
        
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecord()
	}
    
    var isRecording: Bool {
        fileOutput.isRecording
    }
    func toggleRecord() {
        if isRecording {
            fileOutput.stopRecording()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
    }
    
    private func updateViews() {
        recordButton.isSelected = isRecording
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error saving recording: \(error.localizedDescription)")
        }
        print("URL: \(outputFileURL.path)")
        updateViews()
        playMovie(url: outputFileURL)
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateViews()
    }
}
