//
//  InterfaceController.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 13/7/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit



class MainInterfaceController: WKInterfaceController {
	@IBOutlet weak var lowHeartRateBtn: WKInterfaceButton!
	@IBOutlet weak var highHeartRateBtn: WKInterfaceButton!
	@IBOutlet weak var durationBtn: WKInterfaceButton!
	
	let healthStore = HKHealthStore()
	
	var LowHeartRate : Int!
	var TargetHeartRate: Int!
	var Duration: Int!
	let defaults = UserDefaults.standard
	let config = HKWorkoutConfiguration()
	var age: Int!
	
	
	
	override func didAppear() {
		super.didAppear()
		
		config.activityType = .other
		
		if defaults.object(forKey: "LowHeartRate") != nil{
			LowHeartRate = defaults.integer(forKey: "LowHeartRate")
			TargetHeartRate = defaults.integer(forKey: "TargetHeartRate")
			Duration = defaults.integer(forKey: "Duration")
			let Age = defaults.integer(forKey: "age")
			if Age != 0 {
				age = Age
			}
			
		}else{
			LowHeartRate = 120 //TODO
			defaults.set(LowHeartRate, forKey: "LowHeartRate")
			TargetHeartRate = 150 //TODO
			defaults.set(TargetHeartRate, forKey:  "TargetHeartRate")
			Duration = 20
			defaults.set(Duration, forKey: "Duration")
			
		}
		
		lowHeartRateBtn.setTitle("\(LowHeartRate!)")
		highHeartRateBtn.setTitle("\(TargetHeartRate!)")
		durationBtn.setTitle("\(Duration!)")
 

		/// Requesting authorization.
		/// - Tag: RequestAuthorization
		// The quantity type to write to the health store.
		let typesToShare: Set = [
			HKQuantityType.workoutType()
		]
		
		// The quantity types to read from the health store.
		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			//HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
		]
		
		// Request authorization for those quantity types.
		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
			/// - TODO: handle error
			if success {

				
			} else {
				let action = WKAlertAction(title: "close", style: WKAlertActionStyle.default) {}
				
				DispatchQueue.main.async {
					self.presentAlert(withTitle: "ezHIIT", message: "Request authorization failed", preferredStyle: WKAlertControllerStyle.alert, actions:[action])
				}
			}
			
			if let error = error{
				let action = WKAlertAction(title: "close", style: WKAlertActionStyle.default) {}

				DispatchQueue.main.async {
					self.presentAlert(withTitle: "ezHIIT", message: "An error\(error)", preferredStyle: WKAlertControllerStyle.alert, actions:[action])
					
				}

			}
		}

	}
	
	

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
		self.setTitle("ezHIIT")
	 
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	

	
	override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
		let context = UserContext(mainInterface: self)
		
		if segueIdentifier == "startWorkout"{
			return context
		}
		else if segueIdentifier == "myPickerTime"{
			
			return [context, pickerTypes.time]
		}
		else if segueIdentifier == "myPickerLowBPM"{
			return [context, pickerTypes.lowHeartRate]
		}
		else if segueIdentifier == "myPickerHighBPM"{
			return [context, pickerTypes.highHeartRate]
		}
		
		return nil
	}

}
 
