//
//  WorkoutInterfaceController.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 3/8/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import AVFoundation


class WorkoutInterfaceController: WKInterfaceController,
	HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate , AVAudioPlayerDelegate
{
	@IBOutlet weak var backgroundGroup: WKInterfaceGroup!
	@IBOutlet weak var backgroundGroupInterval: WKInterfaceGroup!
	@IBOutlet weak var backgroundGroupTime: WKInterfaceGroup!
	
	@IBOutlet weak var heartRateLabel: WKInterfaceLabel!
	@IBOutlet weak var WKElapsedtimer: WKInterfaceTimer!
	@IBOutlet weak var WKIntervalTimer: WKInterfaceTimer!
	
	@IBOutlet weak var repLabel: WKInterfaceLabel!	
	@IBOutlet weak var endLabel: WKInterfaceLabel!
	
	var healthStore: HKHealthStore!
	var configuration: HKWorkoutConfiguration!
	var session: HKWorkoutSession!
	var builder: HKLiveWorkoutBuilder!
	var avPlayer: AVAudioPlayer?
	
 
	
	enum hiitStatus{
		case start
		case active
		case rest
		case unknown
		case hitHighZone
		case hitLowZone
		case end
	}
	
	struct HeartRateTracking
	{
		var value = 0	 		// current heart rate value
		var refValue = 0 		// reference value to determine inc / dec
		var announcedValue = 0  // last announced value
		
		var increasing = true
		
		var hitHighZone = false
		var hitLowZone = false
		var hitMidValue = false
		
		var max = Int.min
		var min = Int.max
		
		var maxOccureAt = Date()
		var minOccureAt = Date()
	}
	
	
	struct Elapsed {
		var time = 0 	// total elapsed time in seconds
		var since = Date().timeIntervalSince1970
	}
 
	var userContext: UserContext!
	var elapsed 	= Elapsed()

	
	var workoutDidEnd 			= false
	var workoutDidStart 		= false
	var workoutEnding 			= false
	var highZoneWarningTimer 	= 0.0
	var defaultVolume : Float!
	var reps = 0

	var HIITStatus 				= hiitStatus.start
	var HeartRate 				= HeartRateTracking()
	
	//var timer: Timer?
	
	let INVALID_MAX = Int.min
	let INVALID_MIN = Int.max
	let audioSession: AVAudioSession = .sharedInstance()
 
	
    override func awake(withContext context: Any?)
	{
        super.awake(withContext: context)
		setTitle("End")
 
		guard let context = context as? UserContext else {
			dismiss()
			return
		}
		userContext = context
		healthStore = context.healthStore
 		configuration = context.config
		workoutDidEnd = false
		repLabel.setText("0")
		endLabel.setText("")
		
		WKIntervalTimer.setTextColor(.green)
		//heartRateLabel.setTextColor(.red)
		
		let alertAction = WKAlertAction(title: "Cancel", style: .cancel) {}
		
		/// Create the session and obtain the workout builder.
		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
			builder = session.associatedWorkoutBuilder()
		} catch {
			presentAlert(withTitle: "", message: "failed to create workout session", preferredStyle: .alert, actions: [alertAction])
			dismiss()
			return
		}
 
		
		/// Setup session and builder.
		session.delegate = self
		builder.delegate = self
 
		/// Set the workout builder's data source.
		builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: configuration)
		
		/// Start the workout session and begin data collection.
		session.startActivity(with: Date())
		builder.beginCollection(withStart: Date()) { (success, error) in
			print(error ?? " ")
		}
		
		/// AVAudio Session for notification alert
		if prepareAVSession() == false
		{
			presentAlert(withTitle: "", message: "failed to create AVAudioSession", preferredStyle: .alert, actions: [alertAction])
			dismiss()
			return
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name:
			NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification") , object: nil)

	}
	

	
	
	func setDurationTimerDate(_ sessionState: HKWorkoutSessionState)
	{
		let timerDate = Date(timeInterval: 0,  since: Date())
 
		DispatchQueue.main.async {
			self.WKElapsedtimer.setDate(timerDate)
			self.elapsed.since = timerDate.timeIntervalSince1970
		}

		DispatchQueue.main.async {
			/// Update the timer based on the state we are in.
			sessionState == .running ? self.WKElapsedtimer.start() : self.WKElapsedtimer.stop()
			
		}
	}
	
	
	func playNotification( withSound sound: WKHapticType)
	{
		if avPlayer!.isPlaying {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
				WKInterfaceDevice.current().play(sound)
			}
		}
		else{
			WKInterfaceDevice.current().play(sound)
		}
		
		if sound == .directionDown || sound == .directionUp || sound == .stop{
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.5){
				self.playAudio(file: "notification.mp3")
			}
		}
	}
	
	
	func prepareAVSession() -> Bool
	{
		do {

			try audioSession.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.duckOthers)
		}
		catch {
			print(error)
			return false
		}
 
 		return true
	}
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		
		player.stop()
 
		do {
			try audioSession.setActive(false)
			
		}
		catch {
			//print ("audiosession cannot be deactivated")
		}

	}
	
	
	func playAudio(file fileName: String)
   {
	   if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
		   
		   do {
			   avPlayer = try AVAudioPlayer(contentsOf: url)
			   avPlayer?.delegate = self
			   if defaultVolume == nil{
				   defaultVolume = avPlayer?.volume
			   }
			   avPlayer?.volume = 1.0

			   do {
				   try self.audioSession.setActive(true)
				   self.avPlayer?.play()
			   }
			   catch {
				   print ("audiosession cannot be activated")
			   }
		   }
		   catch {
			   print(error)
		   }
	   }
   }
	

	
	func readOutHeartRate(_ heartRate: Int)
	{
		if heartRate < 60 || heartRate > 220 {
			return
		}
 
		let audioFile = "\(heartRate)" + ".mp3"
		
		if let url = Bundle.main.url(forResource: audioFile, withExtension: nil) {
			
			do {
				avPlayer = try AVAudioPlayer(contentsOf: url)
				avPlayer?.delegate = self
				if defaultVolume == nil{
					defaultVolume = avPlayer?.volume
				}
				avPlayer?.volume = 1.0

				do {
					try self.audioSession.setActive(true)
					self.avPlayer?.play()
				}
				catch {
					print ("audiosession cannot be activated")
				}
			}
			catch {
				print(error)
			}
		}
	}
	
	func readOut(currentHeartRate bpm: Double?  )
	{

		guard let bpm = bpm else{ return}
		
		let intBpm = Int(bpm)
		var toAnnounce = 0
		
		if intBpm > 110 && intBpm <= 180 {
			
			if (intBpm % 10 == 2 || intBpm % 10 == 3 ||
				intBpm % 10 == 7  || intBpm % 10 == 8 ) && abs(HeartRate.value - intBpm) < 5
			{
				//  X2 X3 X8 X8   excluded
				return
			}
			
			toAnnounce =  Int((bpm/5).rounded()*5)
		}
		else{
			if (intBpm % 10 == 4 || intBpm % 10 == 5 ||
				intBpm % 10 == 6) && abs(HeartRate.value - intBpm) < 10
			{
				//  X4 X5 X6   excluded
				return
			}
			
			toAnnounce =  Int((bpm/10).rounded()*10)
		}
		
		HeartRate.value = intBpm
		
		if !HeartRate.increasing && toAnnounce == userContext.lowHeartRateValue
			&& intBpm > toAnnounce {
			return // at low value announce userContext.lowHeartRateValue or lower
				   // to prevent wrong rep count in case user
				   // sart to be active again.
		}
		
		if HeartRate.increasing && toAnnounce == userContext.highHeartRateValue
			&& intBpm < toAnnounce {
			return 
		}
		
		if HeartRate.announcedValue != toAnnounce{
			readOutHeartRate(toAnnounce)
			HeartRate.announcedValue  = toAnnounce
			
		}
 
	}

	
	// for simmulation
  	#if false
	var simmulatedHR = 70
	var simmulatedHRIncreasing = true
	
	func SimulateHeartRate() -> Int
	{
	    if simmulatedHRIncreasing == true{
		   if  simmulatedHR < 120 {
			   var r = Int.random(in: 0...15);
			   r -= 3
			   simmulatedHR += r
		   }
		   else{
			   simmulatedHRIncreasing = false
		   }
	    }
	    else{
		   if simmulatedHR > 70 {
			   var r = Int.random(in: 0...15);
			   r -= 3
			   simmulatedHR -= r
		   }
		   else{
			   simmulatedHRIncreasing = true
		   }
	    }
		return simmulatedHR
	}
	#endif
 
	
	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes:
		Set<HKSampleType>)
	{
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else {
				return
			}
	
			if session.state == .running
			{
				elapsed.time = (Int)(Date().timeIntervalSince1970 - elapsed.since )
				if userContext.workoutDuration*60 < (elapsed.time )
				{
					workoutEnding = true // reached the target duration.
				}
			}
			
			if let statistics = workoutBuilder.statistics(for: quantityType)
			{
				switch statistics.quantityType
				{// consider only HR QuantityType
					
				case HKQuantityType.quantityType(forIdentifier: .heartRate):
					
					let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
					let value1 = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
					
					guard let value = value1 else{
						return
					}
					
					let currentHeartRate = Int( round( 1 * value ) / 1 )

					//TODO: remove
					#if false
					currentHeartRate = SimulateHeartRate()
					#endif
					

					if currentHeartRate <= 0 {
						return // invalid value
					}

					readOut(currentHeartRate: Double(currentHeartRate) )
					
					if workoutDidStart == false
					{
						if session.state == .running && currentHeartRate >= userContext.lowHeartRateValue
						{
							setDurationTimerDate(.running)
							DispatchQueue.main.async {
								
								let duration = Double(self.userContext.workoutDuration!)
								self.backgroundGroupTime.setBackgroundImageNamed("outer")
								self.backgroundGroupTime.startAnimatingWithImages(in: NSRange(location: 1, length: 21),duration:duration*60.0, repeatCount: 1)
								self.resetIntervalTimer(to: Date() , withWindDown: false)
							}
							workoutDidStart = true
						}

					}
					
					HIITWorkout2(heartRate: currentHeartRate)
					
					// Update heart rate label
					DispatchQueue.main.async {
						self.heartRateLabel.setText("\(currentHeartRate)")
					}

					// Animate heart rate value in HR circle
					var HrAnimationLocation = 0.0
					if currentHeartRate < self.userContext.lowHeartRateValue{
						// until Min HR, show 0 to 25%
						HrAnimationLocation = 5.0*Double(currentHeartRate)/(Double(self.userContext.lowHeartRateValue))
					}
					else{
						// from min HR to max HR show the remaining 75%
						let min = Double(self.userContext.lowHeartRateValue)
						let max = Double(self.userContext.highHeartRateValue)
						let range = Double(max - min)
						HrAnimationLocation = 20 - 15*(max - Double(currentHeartRate))/range
					}
					// truncate to 100% and 5%
					if HrAnimationLocation > 20{
						HrAnimationLocation = 20
					}
					else if HrAnimationLocation < 1{
						HrAnimationLocation = 1
					}
					// update animation
					DispatchQueue.main.async {
						self.backgroundGroup.stopAnimating()
						self.backgroundGroup.startAnimatingWithImages(in: NSRange(location: Int(HrAnimationLocation), length: 1),duration: 1,repeatCount: 1)
					}
					break
					
				default:
					return
				}
				
			}
			
		}
	}
	
	
	
	func HIITWorkout2(heartRate currentValue : Int)
	{
		switch(HIITStatus)
		{
		case .start:
			
			if currentValue >= userContext.highHeartRateValue{
				HeartRate.increasing = true
				HIITStatus = .hitHighZone
				playNotification(withSound: .directionDown)
				//print("high zone")
			}
			

			highZoneWarningTimer = 0
			HeartRate.max = INVALID_MAX
			HeartRate.min = INVALID_MIN
			
			break
			
		case .hitHighZone:
			if currentValue <= userContext.lowHeartRateValue
			{
				HIITStatus = .hitLowZone
				HeartRate.increasing = false
				playNotification(withSound: .directionUp)
				//print("low zone")

				reps += 1
				DispatchQueue.main.async {
					self.repLabel.setText("\(self.reps)")
				}
				
				highZoneWarningTimer = 0
			}
			else if currentValue >= userContext.highHeartRateValue
			{
				if highZoneWarningTimer == 0 {
					highZoneWarningTimer = Date().timeIntervalSince1970
				}
				else{
					if Date().timeIntervalSince1970 - highZoneWarningTimer >= 20{
						highZoneWarningTimer = Date().timeIntervalSince1970

						playNotification( withSound: .retry)
					}
				}
			}
			
			if HeartRate.max != INVALID_MAX
				&& currentValue < (HeartRate.max - 10)
			{
				highZoneWarningTimer = 0
				HeartRate.increasing = false
				//print("dec start \(currentValue)")
				
				DispatchQueue.main.async {
					self.resetIntervalTimer(to: self.HeartRate.maxOccureAt)
				}
				HeartRate.max = INVALID_MAX
			}
			
			if( HeartRate.increasing && currentValue > HeartRate.max ){ // still increasing
				HeartRate.max = currentValue
				HeartRate.min = INVALID_MIN // invalidate min value
				HeartRate.maxOccureAt = Date()
				//print("max \(HeartRate.max)")
			}
			
			break
			
		case .hitLowZone:
			if currentValue >= userContext.highHeartRateValue{
				HIITStatus = .hitHighZone
				playNotification(withSound: .directionDown)
				//print("high zone")
			}
			else if HeartRate.min != INVALID_MIN
				&& currentValue > (HeartRate.min + 10)
				
			{
				//print("inc start \(currentValue)")
				HeartRate.increasing = true
				DispatchQueue.main.async {
					self.resetIntervalTimer(to: self.HeartRate.minOccureAt)
				}
				HeartRate.min = INVALID_MIN
			}
			
			if( HeartRate.increasing == false && currentValue < HeartRate.min ){
				HeartRate.min = currentValue
				HeartRate.max = INVALID_MAX
				HeartRate.minOccureAt = Date()
				//print("min \(HeartRate.min)")
			}
			
			if currentValue <= userContext.lowHeartRateValue{
				if workoutEnding
				{
					playNotification( withSound: .stop)
					endWorkout()
					HIITStatus = .end
					//DispatchQueue.main.async {
					//	self.WKElapsedtimer.setTextColor(.lightGray)
					//}
					//print("end")
				}
			}
			
			break
			
				
		case .end:// end, nothing to do
			break
			
			
		default: // TODO: remove unused status
				break;
			
		}
	}
	
	
	//NOT USED
	func HIITWorkout(_ currentHeartRate : Int)
	{
		let current = currentHeartRate
		
		//readOut(currentHeartRate: Double(currentHeartRate) )
		
		if HeartRate.refValue == 0
		{// just started
			
			HeartRate.min = Int.max
			HeartRate.max = Int.min
			HeartRate.hitMidValue = false
			
			if 110 > current{ // warm up heart rate taken as 110
				return // still warm up
			}
			
			HeartRate.refValue = 1

		}
		
		if current - HeartRate.refValue >= 10 // check if increasing
		{// yes, increasing
			if !HeartRate.increasing {
				HeartRate.increasing = true

				DispatchQueue.main.async {
					self.resetIntervalTimer(to: self.HeartRate.minOccureAt)
				}
			}
			
			HeartRate.refValue = current
			
			if workoutDidStart == false{
				if session.state == .running {
					setDurationTimerDate(.running)
					DispatchQueue.main.async {
						
						let duration = Double(self.userContext.workoutDuration!)
						self.backgroundGroupTime.setBackgroundImageNamed("outer")
						self.backgroundGroupTime.startAnimatingWithImages(in: NSRange(location: 1, length: 21),
																	 duration:duration*60.0, repeatCount: 1)
						self.resetIntervalTimer(to: Date() , withWindDown: false)
					}
					
					workoutDidStart = true

				}
			}
		}
		else if HeartRate.refValue - current >= 10 && HeartRate.hitHighZone // check if decreasing
		{ //yes, decreasing
			if HeartRate.increasing {
				HeartRate.increasing = false

				DispatchQueue.main.async {
					self.resetIntervalTimer(to: self.HeartRate.maxOccureAt)
				}
				//print("interval reset max now \(Date()) , max \(self.HeartRate.maxOccureAt)")
				
			}
			HeartRate.refValue = current
		}
		
		if HeartRate.increasing
		{ // in increasing mode
			if( current > HeartRate.max ){ // still increasing
				HeartRate.max = current
				HeartRate.min = INVALID_MIN // invalidate min value
				HeartRate.maxOccureAt = Date()
				//print("max \(current) @ \(HeartRate.maxOccureAt)")

			}
			
			if current > (userContext.highHeartRateValue + userContext.lowHeartRateValue)/2{
				HeartRate.hitMidValue = true
				HeartRate.hitLowZone  = false
			}
			
			if current  >= userContext.highHeartRateValue{
				if HeartRate.hitHighZone == false {
					HeartRate.hitHighZone = true

					playNotification( withSound: .directionUp)

				}
				
				if highZoneWarningTimer == 0 {
					highZoneWarningTimer = Date().timeIntervalSince1970
				}
				else{
					if Date().timeIntervalSince1970 - highZoneWarningTimer >= 20{
						highZoneWarningTimer = Date().timeIntervalSince1970
 
						playNotification( withSound: .retry)
					}
				}
			}
		}
		else
		{ // in decreasing mode
			highZoneWarningTimer = 0
			
			if( current < HeartRate.min){ // still decreasing
				HeartRate.min = current
				HeartRate.max = INVALID_MAX // invalidate max value
				HeartRate.minOccureAt = Date()
				//print("min @ \(HeartRate.minOccureAt)")
			}
			
			if current  <= userContext.lowHeartRateValue
			{
				if !HeartRate.hitLowZone   && (HeartRate.hitHighZone ||
					HeartRate.hitMidValue)
				{
					HeartRate.hitHighZone = false
					HeartRate.hitLowZone  = true
					HeartRate.hitMidValue = false
					playNotification( withSound: .directionDown)

					reps += 1
					DispatchQueue.main.async {
						self.repLabel.setText("\(self.reps)")
					}
				}
				
				if workoutEnding{

					playNotification( withSound: .stop)
					endWorkout()
					
					DispatchQueue.main.async {
						self.WKElapsedtimer.setTextColor(.lightGray)
						//self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timerFunction), userInfo: nil, repeats: true)
					}
				}
			}
		}
	}
	
 
	
	func resetIntervalTimer(to datetime: Date = Date(), withWindDown windDown : Bool = true )
	{
		WKIntervalTimer.setDate(datetime)
		WKIntervalTimer.start()
		
		//if HeartRate.increasing {
		//	WKIntervalTimer.setTextColor(.green)
		//}
		//else {
		//	WKIntervalTimer.setTextColor(.cyan)
		//}
		//print("def = \(Date().timeIntervalSince1970 -  datetime.timeIntervalSince1970)")
		var location = Int(20.0/180.0*Double(Date().timeIntervalSince1970 -  datetime.timeIntervalSince1970))
		
		if location > 20{
			location = 20
		}
		else if location < 1{
			location = 1
		}
 
		backgroundGroupInterval.stopAnimating()
		
		if windDown {
			backgroundGroupInterval.startAnimatingWithImages(in: NSRange(location: 0, length: 20),duration: TimeInterval(-1),	repeatCount: 1)

		}
		
		//let delay = DispatchTime.now() + 4
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
			self?.backgroundGroupInterval.startAnimatingWithImages(in: NSRange(location: location, length: 20-location),duration: TimeInterval(9*(20-location)),	repeatCount: 1)
		}


	}
	
	
	
	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
		/// - TODO:
	}
	
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		//print("\(fromState.rawValue) to \(toState.rawValue)")
		
		/*
		if toState == .running {
			self.setDurationTimerDate(.running)
			let duration = Double(userContext.workoutDuration!)
			backgroundGroupTime.setBackgroundImageNamed("outer")
			backgroundGroupTime.startAnimatingWithImages(in: NSRange(location: 1, length: 21),
														 duration:duration*60.0, repeatCount: 1)
			//interval.time = 1
			//interval.since = Date().timeIntervalSince1970
			resetIntervalTimer()

		}
		*/
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		workoutDidEnd = true
		endWorkout()
	}

	
	// fired only after workout ended
	@objc func timerFunction()
	{
		struct flag{
			static var value = false
		}
		
		flag.value = flag.value == false ? true : false

		WKElapsedtimer.setHidden(flag.value)
	}
	
	
	
	func endWorkout()
	{
		if session.state != .ended && workoutDidEnd == false{
			
			session.end()
			
			//interval.time = Int(Date().timeIntervalSince1970 - interval.since)
			elapsed.time = Int(Date().timeIntervalSince1970 - elapsed.since)
 
			
			WKElapsedtimer.stop()
			WKIntervalTimer.stop()
			backgroundGroupTime.stopAnimating()
			backgroundGroupInterval.stopAnimating()
			
			endLabel.setText("end")
			
			builder.endCollection(withEnd: Date()) { (success, error) in
				self.builder.finishWorkout { (workout, error) in
					//print(error ?? "error endCollection")
				}
			}
			
			workoutDidEnd = true

		}
	}
	
	// this function is not called in WOS 6 due to a bug
	/*
    override func willActivate() {
	   // This method is called when watch view controller is about to be visible to user
	   super.willActivate()
	   
	   //TODO: restart timer
	   //print("willActivate")
	   
	   if  workoutDidEnd{
		   WKElapsedtimer.setDate(Date().addingTimeInterval(-Double(elapsed.time)))
		   WKElapsedtimer.start()
		   WKElapsedtimer.stop()
		   
		   //WKIntervalTimer.setDate(Date().addingTimeInterval(-Double(interval.time)))
		   
		   //WKIntervalTimer.start()
		   //WKIntervalTimer.stop()
	   }
    }
	*/
	
	// used this function instead of willActivate
	@objc func applicationDidBecomeActive(notification: NSNotification)
	{
		//print("active again")
		if workoutDidStart {
			WKElapsedtimer.start()
			if workoutDidEnd == false{
				WKIntervalTimer.start()
			}
		}
		
		if  workoutDidEnd{
			WKElapsedtimer.setDate(Date().addingTimeInterval(-Double(elapsed.time)))
			WKElapsedtimer.start()
			WKElapsedtimer.stop()
			
			//WKIntervalTimer.setDate(Date().addingTimeInterval(-Double( interval.time)))
			//WKIntervalTimer.start()
			WKIntervalTimer.stop()
		}
	}

	
	override func willDisappear() {
		builder.delegate = nil
		session.delegate = nil
		endWorkout()
		avPlayer?.volume = defaultVolume!
		//timer?.invalidate()
		
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification") , object: nil)
		
		//print("willDisappear")
	}

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		//print("didDeactivated")
    }
	
	
	override func didAppear()
	{
		super.didAppear()
		
		//print("didAppear")
		
		backgroundGroup.setBackgroundImageNamed("inner")
		
		backgroundGroupInterval.setBackgroundImageNamed("middle")
		backgroundGroupInterval.startAnimatingWithImages(in: NSRange(location: 0, length: 1),
														 duration:1, repeatCount: 1)
		
	}
	
	
	 
}
