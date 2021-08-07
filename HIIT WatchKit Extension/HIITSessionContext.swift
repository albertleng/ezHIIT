//
//  HIITSessionContext.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 3/8/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import Foundation
import HealthKit


struct HIIT {
	var LowHeartRate: Int
	var HightHeartRate: Int
	var Duration: Int
	
}

class HIITSessionContext
{
	let configuration: HKWorkoutConfiguration
	let healthStore: HKHealthStore
	let hiit : HIIT
	
	init(healthStore: HKHealthStore, configuration: HKWorkoutConfiguration,
		 hiit: HIIT)
	{
		self.hiit = HIIT(LowHeartRate: hiit.LowHeartRate, HightHeartRate: hiit.HightHeartRate, Duration: hiit.Duration )

		self.healthStore = healthStore
		self.configuration = configuration
	}
}
