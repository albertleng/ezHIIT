//
//  UserContext.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 10/8/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import Foundation
import HealthKit


class UserContext{
	let mainInterface: MainInterfaceController!  /// - TODO: 
	
	init(mainInterface: MainInterfaceController){
		self.mainInterface = mainInterface
		self.lowHeartRateValue = mainInterface.LowHeartRate
		self.highHeartRateValue = mainInterface.TargetHeartRate
		self.age = mainInterface.age
		self.workoutDuration = mainInterface.Duration
		self.config.activityType = .highIntensityIntervalTraining
		self.healthStore = mainInterface.healthStore
	}
	
	var age: Int!{
		didSet{
			if let age = self.age{
				mainInterface.age = age
				mainInterface.defaults.set(age, forKey: "age")
			}			
		}
	}
	
	var lowHeartRateValue: Int!{
		didSet{
			if let lowHr = self.lowHeartRateValue{
				mainInterface.LowHeartRate = lowHr
				mainInterface.lowHeartRateBtn.setTitle("\(lowHr)")
				
				mainInterface.defaults.set(lowHr, forKey: "LowHeartRate")

				
			}
		}
	}
	
	var highHeartRateValue: Int!{
		didSet{
			if let highHr = self.highHeartRateValue{
				mainInterface.TargetHeartRate = highHr
				mainInterface.highHeartRateBtn.setTitle("\(highHr)")

				mainInterface.defaults.set(highHr, forKey:  "TargetHeartRate")

			}
		}
	}
	
	var workoutDuration: Int!{
		didSet{
			if let duration = self.workoutDuration{
				mainInterface.Duration = duration
				mainInterface.durationBtn.setTitle("\(duration)")
				mainInterface.defaults.set(duration, forKey: "Duration")
			}
		}
	}
	
	let config = HKWorkoutConfiguration()
	let healthStore: HKHealthStore!
	
}
