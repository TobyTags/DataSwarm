//
//  ViewController.swift
//  DataSwarm
//
//  Created by Toby on 18/06/2023.
//

import UIKit
import SwiftyJSON // Import the SwiftyJSON library for JSON serialization

//imporint core framework libaries for raw sensor data
import CoreLocation
import CoreMotion
import CoreAudio
import AVFoundation
import Accelerate
import CoreImage
import CoreVideo
import GLKit
import QuartzCore
import DeviceKit

//Firebase Frirestore imports
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Firebase

//for compression
import Gzip

//running in background
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UNUserNotificationCenterDelegate {
    
    //1 thread call
    var on = false
    
    //global variable that holds all sensor data, the data stays here until replaced and is used every 0.1s
    var allData: (xRotationRate: Double?, yRotationRate: Double?, zRotationRate: Double?, absoluteRotationRate: Double?, magnetometerX: Double?, magnetometerY: Double?, magnetometerZ: Double?, magnetometerAbsolute: Double?, latitude: Double?, longitude: Double?, altitude: Double?, xnog: Double?, ynog: Double?, znog: Double?, absnog: Double?, xg: Double?, yg: Double?, zg: Double?, absg: Double?, pitch: Double?, yaw: Double?, roll: Double?, attitudeAbs: Double?, pressureHPA: Double?, xC: Double?, yC: Double?, zC: Double?, absoluteC: Double?, isCharging: Int?, batteryLevel: Float?)?
    
    // <--realtimecode-->
    //defining lables for real time data showing
    
    // Real-time value label
    @IBOutlet weak var Lable_Time: UILabel!
    
    // Timer for updating the label
    var timer: Timer?
    var timer2: Timer?
    
    //  <--location gps work-->
    // Location manager for GPS data
    let locationManager = CLLocationManager()
    
    //<<-pressure work-->
    // Pressure manager --> accsessing coremotion framwork liabary for it
    let altimeter = CMAltimeter()
    
    //<<--magnetomer work-->
    //magnetometer manager
    let motionManager = CMMotionManager()
    
    //<--distance travveled work-->
    // declaring var for last location
    var lastLocation: CLLocation?
    
    // Array to store all data readings
    static var dataReadings: [JSON] = []
    
    //flag to ensure data is only appended once per second
    static var lastAppendedDataTime = 0.0
    
    var Swarm_X = "Swarm_9"
    
    // <-- Function that is run after loading -->
    override func viewDidLoad() {
        
        if on == false {
            on = true
            super.viewDidLoad()
            // Assign the reference to AppDelegate's viewController property
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.viewController = self
            }
            
            var oldtimeT: Decimal = 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in      //calling to save the data every 0.1s percicse
                guard let self = self else { return }
                
                let timeT = readtime()
                
                if timeT != oldtimeT {
                    allsave()
                    updateLabel()
                    oldtimeT = timeT
                }
            }
            
            self.readAndSaveAllData() //calling to start the 0.1s data
            self.seconddata() //calling to start the 1s data
            
            // sending to Firebase
            //timer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in      //uploading data every 10mins
            //self?.sendDataButtonPressed()
            //}
            // sending to cloud storage
            timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in      //uploading data every 10mins
                self?.Uploadtostorage()
            }
            
            //<--gps location--
            // Configure location manager
            locationManager.requestWhenInUseAuthorization()
            
            // Initialize the motion manager
            motionManager.magnetometerUpdateInterval = 0.08 // Set the update interval
            
            // this is for compasew
            locationManager.delegate = self
            
            // Request permission to access the device's heading
            locationManager.requestWhenInUseAuthorization()
            
            // Check if the device supports heading updates
            if CLLocationManager.headingAvailable() {
                // Start heading updates
                locationManager.startUpdatingHeading()
            }
            print("called")
        }
        
        
        print("already running")
        
    }

    @IBOutlet weak var Time2: UILabel!
    
    // Function to update the label with the current time
    func updateLabel() {
        // Reading time
        let currentTime1 = Date().timeIntervalSince1970
        var currentTime: Decimal = 0.0 // Declare currentTime
        
        if let unwrappedTime = Double(String(format: "%.1f", currentTime1)) {
            let currentTime2 = unwrappedTime
            currentTime = Decimal(currentTime2)
        }
        
        let roundingBehavior = NSDecimalNumberHandler(roundingMode: .plain, scale: 1, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedTime = NSDecimalNumber(decimal: currentTime).rounding(accordingToBehavior: roundingBehavior)
        
        if let label = Time2 {
            label.text = String(describing: roundedTime)
        }
    }
    
    //creating outlets to lables
    @IBOutlet weak var Latitude: UILabel!
    @IBOutlet weak var Longitude: UILabel!
    @IBOutlet weak var Altitude: UILabel!
    
    func seconddata() {
        //reading gps
        getLocationData { locationData in
            let lat = locationData["latitude"]
            let long = locationData["longitude"]
            let alt = locationData["altitude"]
            
            
            //saving data
            DispatchQueue.main.async { [weak self] in
                self?.allData = (
                    self?.allData?.xRotationRate,
                    self?.allData?.yRotationRate,
                    self?.allData?.zRotationRate,
                    self?.allData?.absoluteRotationRate,
                    self?.allData?.magnetometerX,
                    self?.allData?.magnetometerY,
                    self?.allData?.magnetometerZ,
                    self?.allData?.magnetometerAbsolute,
                    lat,
                    long,
                    alt,
                    self?.allData?.xnog,
                    self?.allData?.ynog,
                    self?.allData?.znog,
                    self?.allData?.absnog,
                    self?.allData?.xg,
                    self?.allData?.yg,
                    self?.allData?.zg,
                    self?.allData?.absg,
                    self?.allData?.pitch,
                    self?.allData?.yaw,
                    self?.allData?.roll,
                    self?.allData?.attitudeAbs,
                    self?.allData?.pressureHPA,
                    self?.allData?.xC,
                    self?.allData?.yC,
                    self?.allData?.zC,
                    self?.allData?.absoluteC,
                    self?.allData?.isCharging,
                    self?.allData?.batteryLevel
                )
            }
            
            //putting data on UI lables
            if let latitude = self.Latitude, let lat = lat {
                let formattedLat = String(format: "%.11f", lat)
                latitude.text = formattedLat
            } else {
                self.Latitude?.text = ""
            }
            
            //putting data on UI lables
            if let Longitude = self.Longitude, let long = long {
                let formattedLat = String(format: "%.11f", long)
                Longitude.text = formattedLat
            } else {
                self.Latitude?.text = ""
            }
            
            //putting data on UI lables
            if let Altitude = self.Altitude, let alt = alt {
                let formattedLat = String(format: "%.11f", alt)
                Altitude.text = formattedLat
            } else {
                self.Altitude?.text = ""
            }
            
        }
        
        startAltimeterUpdates() {
            
        }
        
        readBatteryStatus()
    }



    
    // Save time data to JSON file
    func readAndSaveAllData() {
        
        // Magnetometer Reading
        startMagnetometerUpdates() {
    
        }
        
        // Gyro Reading
        startMotionUpdates()  {
            
        }
         
        // Accelerometer reading + attitude readings
        startAccelerometerUpdates1() {
            
        }


/*
        
        // Reading audio ambient (dB)
        //<--  audio set up -->
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey: 320000,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100.0
            ]
            
            let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("tempAudio.caf")
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: audioSettings)
            
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            audioRecorder.updateMeters()
            let decibels = audioRecorder.averagePower(forChannel: 0)
            //data["audioAmbient"] = decibels
            
            // Reading audio amplitude
            let amplitude = audioRecorder.peakPower(forChannel: 0)
            //data["audioAmplitude"] = amplitude
            
            // Reading audio frequency
            let audioEngine = AVAudioEngine()
            let audioMixer = AVAudioMixerNode()
            let audioInput = audioEngine.inputNode
            
            audioEngine.attach(audioMixer)
            audioEngine.connect(audioInput, to: audioMixer, format: audioInput.outputFormat(forBus: 0))
            
            let bus = 0
            let bufferSize = AVAudioFrameCount(audioInput.outputFormat(forBus: bus).sampleRate)
            
            try audioEngine.start()
            
            audioMixer.installTap(onBus: bus, bufferSize: bufferSize, format: audioInput.outputFormat(forBus: bus)) { (buffer, time) in
                let sampleRate = Float(audioInput.outputFormat(forBus: bus).sampleRate)
                let samples = buffer.floatChannelData![0]
                let frameLength = vDSP_Length(buffer.frameLength)
                
                let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(frameLength))), FFTRadix(kFFTRadix2))
                let real = UnsafeMutablePointer<Float>.allocate(capacity: Int(frameLength))
                var imaginary = UnsafeMutablePointer<Float>.allocate(capacity: Int(frameLength))

                var splitComplex = DSPSplitComplex(realp: real, imagp: imaginary)
                
                vDSP_vmul(samples, 1, [Float](repeating: 0.54, count: Int(frameLength)), 1, samples, 1, frameLength)
                vDSP_fft_zip(fftSetup!, &splitComplex, 1, vDSP_Length(log2(Float(frameLength))), FFTDirection(FFT_FORWARD))
                
                var magnitudes = [Float](repeating: 0.0, count: Int(frameLength / 2))
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(frameLength / 2))
                
                var frequency = Float(0.0)
                var magnitude = Float(-Double.greatestFiniteMagnitude)
                
                for i in 0..<Int(frameLength / 2) {
                    if magnitudes[i] > magnitude {
                        magnitude = magnitudes[i]
                        frequency = Float(i)
                    }
                }
                
                let audioFrequency = frequency * sampleRate / Float(frameLength)
                //data["audioFrequency"] = audioFrequency
            }
            
            audioMixer.volume = 1.0
            
            // Stop recording and clean up temporary audio file
            audioRecorder.stop()
            try? FileManager.default.removeItem(at: audioFilename)
        } catch {
            //data["audioAmbient"] = "NA"
            //data["audioAmplitude"] = "NA"
            //data["audioFrequency"] = "NA"
        }
        
 */
       /*
        
        // proximity reading
        if UIDevice.current.proximityState {
            //data["proximity"] = "true"
        } else if !UIDevice.current.proximityState {
            //data["proximity"] = "false"
        } else {
            //data["proximity"] = "NA"
        }
         
        */
    }
    
    
    
    // sending to firebase my token
    let db = Firestore.firestore()
    var collectionRef: CollectionReference!
    
    
    /*
    // -- old code
    // Button action to send data to Firestore
    func sendDataButtonPressed() {
        do {
            // Convert data readings array to JSON data
            let jsonData = try JSON(ViewController.dataReadings).rawData()

            // Convert JSON data to string
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Parse the JSON string into an array of dictionaries
                if let jsonArray = convertToArrayOfDictionaries(jsonString) {
                    // Create a dictionary to hold all data readings
                    var allData: [String: Any] = [:]
                    allData["dataReadings"] = jsonArray

                    // Get the unique identifier for the document
                    let uniqueIdentifier = getUniqueDeviceIdentifier()

                    // Use the unique identifier as the document ID
                    if let documentID = uniqueIdentifier {
                        // Create a new document under "Swarm_5" with the unique identifier as the ID
                        let swarmCollectionRef = db.collection(Swarm_X)
                        swarmCollectionRef.document(documentID).setData(["UniqueIdentifier": documentID]) { error in
                            if let error = error {
                                print("Error adding identifier document: \(error)")
                            } else {
                                print("Identifier document added to \(self.Swarm_X) collection with ID: \(documentID)")
                                
                                // Save additional data under the same document ID
                                let phoneModel = self.getPhoneModel()
                                let endtime = self.readtime()
                                
                                let additionalData: [String: Any] = ["Device": phoneModel, "EndTime": endtime]
                                swarmCollectionRef.document(documentID).updateData(additionalData) { error in
                                    if let error = error {
                                        print("Error updating identifier document: \(error)")
                                    } else {
                                        print("Additional data added to identifier document with ID: \(documentID)")
                                        
                                        // Create a new collection "SensorData" under the identifier document
                                        let sensorDataCollectionRef = swarmCollectionRef.document(documentID).collection("SensorData")
                                        
                                        // Use the current timestamp as the document ID for the data document
                                        let dataDocumentID = "\(endtime)"
                                        
                                        // Save the entire data dictionary as a new document in "SensorData" collection
                                        sensorDataCollectionRef.document(dataDocumentID).setData(allData) { error in
                                            if let error = error {
                                                print("Error adding data document: \(error)")
                                            } else {
                                                print("Data document added to SensorData collection under identifier document with ID: \(dataDocumentID)")
                                                
                                                // Delete the data from your device after successful submission
                                                ViewController.dataReadings.removeAll()
                                                print("Data deleted from device")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        print("Failed to retrieve a unique identifier.")
                    }
                } else {
                    print("Failed to parse JSON")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
     */

    // Helper method to convert JSON string to an array of dictionaries
    func convertToArrayOfDictionaries(_ jsonString: String) -> [[String: Any]]? {
        if let data = jsonString.data(using: .utf8) {
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                return jsonArray
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        return nil
    }
    
    //get unique phone ID
    func getUniqueDeviceIdentifier() -> String? {
        if let identifier = UIDevice.current.identifierForVendor?.uuidString {
            return identifier
        }
        
        return nil
    }

    
    //phone model
    func getPhoneModel() -> String {
        let device = Device.current
        
        switch device {
        case .iPhone4:
            return "iPhone 4"
        case .iPhone4s:
            return "iPhone 4s"
        case .iPhone5:
            return "iPhone 5"
        case .iPhone5c:
            return "iPhone 5c"
        case .iPhone5s:
            return "iPhone 5s"
        case .iPhone6:
            return "iPhone 6"
        case .iPhone6Plus:
            return "iPhone 6 Plus"
        case .iPhone6s:
            return "iPhone 6s"
        case .iPhone6sPlus:
            return "iPhone 6s Plus"
        case .iPhoneSE:
            return "iPhone SE"
        case .iPhone7:
            return "iPhone 7"
        case .iPhone7Plus:
            return "iPhone 7 Plus"
        case .iPhone8:
            return "iPhone 8"
        case .iPhone8Plus:
            return "iPhone 8 Plus"
        case .iPhoneX:
            return "iPhone X"
        case .iPhoneXS:
            return "iPhone XS"
        case .iPhoneXSMax:
            return "iPhone XS Max"
        case .iPhoneXR:
            return "iPhone XR"
        case .iPhone11:
            return "iPhone 11"
        case .iPhone11Pro:
            return "iPhone 11 Pro"
        case .iPhone11ProMax:
            return "iPhone 11 Pro Max"
        case .iPhoneSE2:
            return "iPhone SE (2nd generation)"
        case .iPhone12Mini:
            return "iPhone 12 Mini"
        case .iPhone12:
            return "iPhone 12"
        case .iPhone12Pro:
            return "iPhone 12 Pro"
        case .iPhone12ProMax:
            return "iPhone 12 Pro Max"
        case .iPhone13Mini:
            return "iPhone 13 Mini"
        case .iPhone13:
            return "iPhone 13"
        case .iPhone13Pro:
            return "iPhone 13 Pro"
        case .iPhone13ProMax:
            return "iPhone 13 Pro Max"
        default:
            return "Unknown iPhone model"
        }
    }
    
    //time
    func readtime() -> Decimal {
        let currentTime1 = Date().timeIntervalSince1970
        if let unwrappedTime = Double(String(format: "%.1f", currentTime1)) {
            let currentTime2 = unwrappedTime
            let currentTime = NSDecimalNumber(decimal: Decimal(currentTime2)).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 1, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            return currentTime
        }
        return 0.0
    }

    //gps stuff
    func getLocationData(completion: @escaping ([String: Double]) -> Void) {
        let locationManager = CLLocationManager()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        var data: [String: Double] = [:]
        
        // Create a timer that runs every 30 mins
        let timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in //1800
            // Reading latitude and longitude
            if let latitude = locationManager.location?.coordinate.latitude {
                data["latitude"] = latitude
            }
            
            if let longitude = locationManager.location?.coordinate.longitude {
                data["longitude"] = longitude
            }
            
            // Reading altitude
            if let altitude = locationManager.location?.altitude {
                data["altitude"] = altitude
            }
            
            completion(data)
        }
        
        // Start the timer immediately and add it to the current run loop
        timer.fire()
        RunLoop.current.add(timer, forMode: .common)
    }


    
    
    // UI lable interface real time data declirations
    @IBOutlet var MagX: UILabel!
    @IBOutlet var MagY: UILabel!
    @IBOutlet var MagZ: UILabel!
    @IBOutlet var MagAbs: UILabel!
    //calibrated ones
    @IBOutlet weak var xC: UILabel!
    @IBOutlet weak var yC: UILabel!
    @IBOutlet weak var zC: UILabel!
    @IBOutlet weak var AbsC: UILabel!
    
    

    func startMagnetometerUpdates(completion: @escaping () -> Void) {
        
        if motionManager.isMagnetometerAvailable {
            motionManager.startMagnetometerUpdates(to: .main) { (magnetometerData, error) in
                if let magnetData = magnetometerData {
                    
                    let magnetrometerVal = magnetData.magneticField
                    let x = magnetrometerVal.x
                    let y = magnetrometerVal.y
                    let z = magnetrometerVal.z
                    let absolute = sqrt(x * x + y * y + z * z)
                    
                    //calibrated version
                    let xC = x + 12.2
                    let yC = y - 30.1
                    let zC = z + 548
                    let absoluteC = sqrt(xC * xC + yC * yC + zC * zC)
                    
                    self.allData = (
                        self.allData?.xRotationRate,
                        self.allData?.yRotationRate,
                        self.allData?.zRotationRate,
                        self.allData?.absoluteRotationRate,
                        x,
                        y,
                        z,
                        absolute,
                        self.allData?.latitude,
                        self.allData?.longitude,
                        self.allData?.altitude,
                        self.allData?.xnog,
                        self.allData?.ynog,
                        self.allData?.znog,
                        self.allData?.absnog,
                        self.allData?.xg,
                        self.allData?.yg,
                        self.allData?.zg,
                        self.allData?.absg,
                        self.allData?.pitch,
                        self.allData?.yaw,
                        self.allData?.roll,
                        self.allData?.attitudeAbs,
                        self.allData?.pressureHPA,
                        xC,
                        yC,
                        zC,
                        absoluteC,
                        self.allData?.isCharging,
                        self.allData?.batteryLevel
                    )
                    
                    // Putting data in UI labels
                    if let magXLabel = self.MagX {
                        magXLabel.text = String(format: "%.3f", x)
                    }
                    
                    if let magYLabel = self.MagY {
                        magYLabel.text = String(format: "%.3f", y)
                    }
                    
                    if let magZLabel = self.MagZ {
                        magZLabel.text = String(format: "%.3f", z)
                    }
                    
                    if let magAbsLabel = self.MagAbs {
                        magAbsLabel.text = String(format: "%.3f", absolute)
                    }
                    
                    //calibrated ones
                    if let xCLable = self.xC {
                        xCLable.text = String(format: "%.3f", xC)
                    }
                    
                    if let yCLable = self.yC {
                        yCLable.text = String(format: "%.3f", yC)
                    }
                    
                    if let zCLable = self.zC {
                        zCLable.text = String(format: "%.3f", zC)
                    }
                    
                    if let AbsC = self.AbsC {
                        AbsC.text = String(format: "%.3f", absoluteC)
                    }
                    
                    
                    // Recursive call to keep the updates running forever
                    self.startMagnetometerUpdates(completion: completion)
                }
            }
        }
    }


    

    
    //declaring GYRO labals for ui real time data
    @IBOutlet weak var GyroX: UILabel!
    @IBOutlet weak var GyroY: UILabel!
    @IBOutlet weak var GyroZ: UILabel!
    @IBOutlet weak var GyroAbs: UILabel!
    //declearing outlets for pitch data
    @IBOutlet weak var PitchL: UILabel!
    @IBOutlet weak var YawL: UILabel!
    @IBOutlet weak var RoleL: UILabel!
    @IBOutlet weak var AttitudeL: UILabel!
    
    
    func startMotionUpdates(completion: @escaping () -> Void) {
        motionManager.deviceMotionUpdateInterval = 0.1 // Set the update interval to 0.1 seconds
        
        // Reading rotation rate data
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
                if let motion = deviceMotion {
                    
                    // calculation accelerometer
                    let rotationRate = motion.rotationRate
                    let xRotationRate = rotationRate.x
                    let yRotationRate = rotationRate.y
                    let zRotationRate = rotationRate.z
                    let absoluteRotationRate = sqrt(xRotationRate * xRotationRate + yRotationRate * yRotationRate + zRotationRate * zRotationRate)
                    
                    // Calculate pitch, yaw, and roll using device motion data
                    let pitch = motion.attitude.pitch
                    let yaw = motion.attitude.yaw
                    let roll = motion.attitude.roll
                    let attitudeAbs = sqrt(pitch * pitch + yaw * yaw + roll * roll)
                    
                    //saving data
                    self.allData = (
                        xRotationRate,
                        yRotationRate,
                        zRotationRate,
                        absoluteRotationRate,
                        self.allData?.magnetometerX,
                        self.allData?.magnetometerY,
                        self.allData?.magnetometerZ,
                        self.allData?.magnetometerAbsolute,
                        self.allData?.latitude,
                        self.allData?.longitude,
                        self.allData?.altitude,
                        self.allData?.xnog,
                        self.allData?.ynog,
                        self.allData?.znog,
                        self.allData?.absnog,
                        self.allData?.xg,
                        self.allData?.yg,
                        self.allData?.zg,
                        self.allData?.absg,
                        pitch,
                        yaw,
                        roll,
                        attitudeAbs,
                        self.allData?.pressureHPA,
                        self.allData?.xC,
                        self.allData?.yC,
                        self.allData?.zC,
                        self.allData?.absoluteC,
                        self.allData?.isCharging,
                        self.allData?.batteryLevel
                    )
                    
                    
                    //putting data on UI lables
                    if let GyroX = self.GyroX {
                        GyroX.text = String(format: "%.9f", xRotationRate)
                    }
                    
                    //putting data on UI lables
                    if let GyroY = self.GyroY {
                        GyroY.text = String(format: "%.9f", yRotationRate)
                    }
                    
                    //putting data on UI lables
                    if let GyroZ = self.GyroZ {
                        GyroZ.text = String(format: "%.9f", zRotationRate)
                    }
                    
                    //putting data on UI lables
                    if let GyroAbs = self.GyroAbs {
                        GyroAbs.text = String(format: "%.9f", absoluteRotationRate)
                    }
                    
                    //updating UI interface lables
                    if (self.PitchL) != nil {
                        self.PitchL.text = String(format: "%.3f", pitch)
                    }
                    
                    if (self.YawL) != nil {
                        self.YawL.text = String(format: "%.3f", yaw)
                    }
                    
                    if (self.RoleL) != nil {
                        self.RoleL.text = String(format: "%.3f", roll)
                    }
                    
                    if (self.AttitudeL) != nil {
                        self.AttitudeL.text = String(format: "%.3f", attitudeAbs)
                    }
                    
                    // Call the completion handler
                    completion()
                }
            }
        }
    }
    
    
    @IBOutlet weak var xnogLabel: UILabel!
    @IBOutlet weak var ynogLabel: UILabel!
    @IBOutlet weak var znogLabel: UILabel!
    @IBOutlet weak var absnogLabel: UILabel!
    @IBOutlet weak var xgLabel: UILabel!
    @IBOutlet weak var ygLabel: UILabel!
    @IBOutlet weak var zgLabel: UILabel!
    @IBOutlet weak var absgLabel: UILabel!

    func startAccelerometerUpdates1(completion: @escaping () -> Void) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // Set the update interval in seconds
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let acceleration = data?.acceleration, error == nil else {
                    return
                }

                // Without gravity
                let xnog = acceleration.x
                let ynog = acceleration.y
                let znog = acceleration.z
                let absnog = sqrt(xnog * xnog + ynog * ynog + znog * znog)

                // With gravity
                let xg = xnog * 9.81
                let yg = ynog * 9.81
                let zg = znog * 9.81
                let absg = sqrt(xg * xg + yg * yg + zg * zg)
                
                // Saving data or updating UI elements can be done directly here
                self.allData = (
                    self.allData?.xRotationRate,
                    self.allData?.yRotationRate,
                    self.allData?.zRotationRate,
                    self.allData?.absoluteRotationRate,
                    self.allData?.magnetometerX,
                    self.allData?.magnetometerY,
                    self.allData?.magnetometerZ,
                    self.allData?.magnetometerAbsolute,
                    self.allData?.latitude,
                    self.allData?.longitude,
                    self.allData?.altitude,
                    xnog,
                    ynog,
                    znog,
                    absnog,
                    xg,
                    yg,
                    zg,
                    absg,
                    self.allData?.pitch,
                    self.allData?.yaw,
                    self.allData?.roll,
                    self.allData?.attitudeAbs,
                    self.allData?.pressureHPA,
                    self.allData?.xC,
                    self.allData?.yC,
                    self.allData?.zC,
                    self.allData?.absoluteC,
                    self.allData?.isCharging,
                    self.allData?.batteryLevel
                )
                
                // Update the UI labels
                if self.xnogLabel != nil {
                    self.xnogLabel.text = String(format: "%.9f", xnog)
                }
                
                if self.ynogLabel != nil { // not actually unrapping vallues but puting in a check for nill vallues to stop it from running when its a nill val
                    self.ynogLabel.text = String(format: "%.9f", ynog)
                }
                
                if self.znogLabel != nil {
                    self.znogLabel.text = String(format: "%.9f", znog)
                }
                
                if self.absnogLabel != nil {
                    self.absnogLabel.text = String(format: "%.9f", absnog)
                }
                
                if self.xgLabel != nil {
                    self.xgLabel.text = String(format: "%.9f", xg)
                }
                
                if self.ygLabel != nil {
                    self.ygLabel.text = String(format: "%.9f", yg)
                }
                
                if self.zgLabel != nil {
                    self.zgLabel.text = String(format: "%.9f", zg)
                }
                
                if self.absgLabel != nil {
                    self.absgLabel.text = String(format: "%.9f", absg)
                }
                
                // Call the completion handler
                completion()
            }
        }
    }
    
    
    @IBOutlet weak var PressureL: UILabel!
    
    func startAltimeterUpdates(completion: @escaping () -> Void) {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data, error == nil else {
                    print("Failed to read altimeter data: \(error?.localizedDescription ?? "")")
                    return
                }
                
                // reading the pressure
                let pressurePa = data.pressure.doubleValue
                
                //converting it to hPa
                let pressureHPA = pressurePa / 100
                
                //appending data to global var
                self?.allData = (
                    self?.allData?.xRotationRate,
                    self?.allData?.yRotationRate,
                    self?.allData?.zRotationRate,
                    self?.allData?.absoluteRotationRate,
                    self?.allData?.magnetometerX,
                    self?.allData?.magnetometerY,
                    self?.allData?.magnetometerZ,
                    self?.allData?.magnetometerAbsolute,
                    self?.allData?.latitude,
                    self?.allData?.longitude,
                    self?.allData?.altitude,
                    self?.allData?.xnog,
                    self?.allData?.ynog,
                    self?.allData?.znog,
                    self?.allData?.absnog,
                    self?.allData?.xg,
                    self?.allData?.yg,
                    self?.allData?.zg,
                    self?.allData?.absg,
                    self?.allData?.pitch,
                    self?.allData?.yaw,
                    self?.allData?.roll,
                    self?.allData?.attitudeAbs,
                    pressureHPA,
                    self?.allData?.xC,
                    self?.allData?.yC,
                    self?.allData?.zC,
                    self?.allData?.absoluteC,
                    self?.allData?.isCharging,
                    self?.allData?.batteryLevel
                )
                
                //updating it on the UI lable
                if (self?.PressureL) != nil {
                    self?.PressureL.text = String(format: "%.6f hPa", pressureHPA)
                }
                
            }
        }
    }
    
    //reading battery
    func readBatteryStatus() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        // Create a timer to read the battery status every 10 seconds
        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            let device = UIDevice.current
            
            // Get the battery level as a value between 0.0 and 1.0
            let batteryLevel = device.batteryLevel * 100

            // Check if the device is currently charging
            let chargingValue = device.batteryState == .charging || device.batteryState == .full
            let isCharging = chargingValue ? 1 : 0
            
            
            //appending data to global var
            self.allData = (
                self.allData?.xRotationRate,
                self.allData?.yRotationRate,
                self.allData?.zRotationRate,
                self.allData?.absoluteRotationRate,
                self.allData?.magnetometerX,
                self.allData?.magnetometerY,
                self.allData?.magnetometerZ,
                self.allData?.magnetometerAbsolute,
                self.allData?.latitude,
                self.allData?.longitude,
                self.allData?.altitude,
                self.allData?.xnog,
                self.allData?.ynog,
                self.allData?.znog,
                self.allData?.absnog,
                self.allData?.xg,
                self.allData?.yg,
                self.allData?.zg,
                self.allData?.absg,
                self.allData?.pitch,
                self.allData?.yaw,
                self.allData?.roll,
                self.allData?.attitudeAbs,
                self.allData?.pressureHPA,
                self.allData?.xC,
                self.allData?.yC,
                self.allData?.zC,
                self.allData?.absoluteC,
                isCharging,
                batteryLevel
            )
        }
        
        // Start the timer immediately
        timer.fire()
    }
    
    //ambient light reading to be put here
    
    
    
    func allsave() {
        var data: [String: Any] = [:]
        
        let currentTime = readtime()

        let (XrotationRate, YrotationRate, ZrotationRate, absoluteRotationRate, magnetometerX, magnetometerY, magnetometerZ, magnetometerAbsolute, latitude, longitude, altitude, xnog, ynog, znog, absnog, xg, yg, zg, absg, pitch, yaw, roll, attitudeAbs, pressureHPA, xC, yC, zC, absoluteC, isCharging, batteryLevel) = allData ?? (nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)

        // Add other data fields inside the "time" key
        data["\(currentTime)"] = [         //first letter dicides order in database, capital before lowercase
            "01": XrotationRate,
            "02": YrotationRate,
            "03": ZrotationRate,
            "04": absoluteRotationRate,
            "05": magnetometerX,
            "06": magnetometerY,
            "07": magnetometerZ,
            "08": magnetometerAbsolute,
            "09": latitude,
            "10": longitude,
            "11": altitude,
            "12": xnog,
            "13": ynog,
            "14": znog,
            "15": absnog,
            "16": xg,
            "17": yg,
            "18": zg,
            "19": absg,
            "20": pitch,
            "21": yaw,
            "22": roll,
            "23": attitudeAbs,
            "24": pressureHPA,
            "25": xC,
            "26": yC,
            "27": zC,
            "28": absoluteC,
            "29": isCharging,
            "30": batteryLevel
        ]

        let saveJSONObject: JSON = JSON(data)
        ViewController.dataReadings.append(saveJSONObject)
        
    }
    
    
    
    
    
    
    
    /*
    // <-- downloading data code -->>
    
    @IBAction func DownloadData(_ sender: Any) {
        downloadUserData()
        print("called")
    }
    
    struct SensorReading {
        let timestamp: TimeInterval
        let XrotationRate: Double
        let YrotationRate: Double
        let ZrotationRate: Double
        let absoluteRotationRate: Double
        let magnetometerX: Double
        let magnetometerY: Double
        let magnetometerZ: Double
        let agnetometerAbsolute: Double
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let NoGAccelerationX: Double
        let NoGAccelerationY: Double
        let NoGAccelerationZ: Double
        let NoGAccelerationABS: Double
        let GAccelerationX: Double
        let GAccelerationY: Double
        let GAccelerationZ: Double
        let GAccelerationABS: Double
        let pitch: Double
        let roll: Double
        let attitudeAbs: Double
        let Pressure: Double
        let isCharging: Double
        let batteryLevel: Double
    }
    
    func downloadUserData() {
        guard let userId = getUniqueDeviceIdentifier() else {
            print("User is not authenticated or user ID is missing.")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection(Swarm_X).document(userId).collection("SensorData").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            guard let querySnapshot = querySnapshot else {
                print("No data found in collection.")
                return
            }
            
            var allSensorData: [[String: Any]] = []
            
            var allSensorReadings: [SensorReading] = []
                
            for document in querySnapshot.documents {
                if let sensorDataArray = document.data()["dataArray"] as? [[String: Any]] {
                    for sensorDataDict in sensorDataArray {
                        if let timestamp = sensorDataDict["timestamp"] as? TimeInterval,
                           let xRotationRate = sensorDataDict["01 XrotationRate"] as? Double,
                           let yRotationRate = sensorDataDict["YrotationRate"] as? Double,
                           let zRotationRate = sensorDataDict["ZrotationRate"] as? Double,
                           let absoluteRotationRate = sensorDataDict["absoluteRotationRate"] as? Double,
                           let magnetometerX = sensorDataDict["magnetometerX"] as? Double,
                           let magnetometerY = sensorDataDict["magnetometerY"] as? Double,
                           let magnetometerZ = sensorDataDict["magnetometerZ"] as? Double,
                           let agnetometerAbsolute = sensorDataDict["agnetometerAbsolute"] as? Double,
                           let latitude = sensorDataDict["latitude"] as? Double,
                           let longitude = sensorDataDict["longitude"] as? Double,
                           let altitude = sensorDataDict["altitude"] as? Double,
                           let noGAccelerationX = sensorDataDict["NoGAccelerationX"] as? Double,
                           let noGAccelerationY = sensorDataDict["NoGAccelerationY"] as? Double,
                           let noGAccelerationZ = sensorDataDict["NoGAccelerationZ"] as? Double,
                           let noGAccelerationABS = sensorDataDict["NoGAccelerationABS"] as? Double,
                           let gAccelerationX = sensorDataDict["GAccelerationX"] as? Double,
                           let gAccelerationY = sensorDataDict["GAccelerationY"] as? Double,
                           let gAccelerationZ = sensorDataDict["GAccelerationZ"] as? Double,
                           let gAccelerationABS = sensorDataDict["GAccelerationABS"] as? Double,
                           let pitch = sensorDataDict["pitch"] as? Double,
                           let roll = sensorDataDict["roll"] as? Double,
                           let attitudeAbs = sensorDataDict["attitudeAbs"] as? Double,
                           let pressure = sensorDataDict["Pressure"] as? Double {
                            
                            let reading = SensorReading(
                                timestamp: timestamp,
                                XrotationRate: xRotationRate,
                                YrotationRate: yRotationRate,
                                ZrotationRate: zRotationRate,
                                absoluteRotationRate: absoluteRotationRate,
                                magnetometerX: magnetometerX,
                                magnetometerY: magnetometerY,
                                magnetometerZ: magnetometerZ,
                                agnetometerAbsolute: agnetometerAbsolute,
                                latitude: latitude,
                                longitude: longitude,
                                altitude: altitude,
                                NoGAccelerationX: noGAccelerationX,
                                NoGAccelerationY: noGAccelerationY,
                                NoGAccelerationZ: noGAccelerationZ,
                                NoGAccelerationABS: noGAccelerationABS,
                                GAccelerationX: gAccelerationX,
                                GAccelerationY: gAccelerationY,
                                GAccelerationZ: gAccelerationZ,
                                GAccelerationABS: gAccelerationABS,
                                pitch: pitch,
                                roll: roll,
                                attitudeAbs: attitudeAbs,
                                Pressure: pressure
                            )
                            allSensorReadings.append(reading)
                        }
                    }
                }
            }
            
            // Save user data to a file
            let fileName = "SensorData.json"
            if let fileURL = self.getDocumentsDirectory()?.appendingPathComponent(fileName) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: allSensorData, options: .prettyPrinted)
                    try jsonData.write(to: fileURL)
                    
                    // Show an alert to let the user know the file is ready for download
                    self.showDownloadAlert(fileURL: fileURL)
                } catch {
                    print("Error saving sensor data: \(error)")
                }
            }
        }
    }


    func getDocumentsDirectory() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func showDownloadAlert(fileURL: URL) {
        let alertController = UIAlertController(title: "Download Complete", message: "The JSON file is ready for download.", preferredStyle: .alert)
        let downloadAction = UIAlertAction(title: "Download", style: .default) { _ in
            // Provide a way for the user to share or save the file
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
        alertController.addAction(downloadAction)
        present(alertController, animated: true, completion: nil)
    }
    */
    
    // <-- uploading to cloud storage -->
    func Uploadtostorage() {
        let user = self.getUniqueDeviceIdentifier()
        let endtime = self.readtime()
        let phone = self.getPhoneModel()
        
        // Assuming 'endtime' is a Decimal
        let endtimeDecimal: Decimal = endtime
        // Convert Decimal to NSNumber
        let endtimeNumber = NSDecimalNumber(decimal: endtimeDecimal)
        // Convert NSNumber to Int
        let epochTime = Int(endtimeNumber.intValue)
        // Calculate the current hour
        let currentHour = (epochTime / 3600) % 24
        
        
        // Get the current date
       let currentDate = Date()
       // Format the date as a string (e.g., "2023-11-02")
       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd"
       let dateString = dateFormatter.string(from: currentDate)
       print(dateString)
        
        if let user = user {
            let uploadRef = Storage.storage().reference(withPath: "/Sigma/Users/\("\(user) : \(phone)")/\(dateString)/\(currentHour)/\(endtime).zip")
            
            do {
                // Convert data readings array to JSON data
                let jsonData = try JSON(ViewController.dataReadings).rawData()
                ViewController.dataReadings.removeAll()
                
                // Compress the JSON data
                if let compressedData = try? jsonData.gzipped() {
                    uploadRef.putData(compressedData) { (downloadMetadata, error) in
                        if let error = error {
                            print("Error uploading compressed data: \(error)")
                        } else {
                            //print(downloadMetadata as Any)
                            print("yeah looks good to me")
                        }
                    }
                }
            } catch {
                print("Error converting data to JSON: \(error)")
            }
        }
    }

    
}






