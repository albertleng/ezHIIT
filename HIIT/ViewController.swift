//
//  ViewController.swift
//  HIIT
//
//  Created by karu on 13/7/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
	
	let healthStore = HKHealthStore()

	//var isAuthorized = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "HIIT"
		navigationController?.navigationBar.prefersLargeTitles = true
		
		let typesToShare: Set = [
			HKQuantityType.workoutType()
		]
		
		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			//HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
		]
		
		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
			// Handle error
			if success {
				
				//self.isAuthorized = true
			} else {
				
				//self.isAuthorized = false
				
			}
		}
	}
	


	
}

