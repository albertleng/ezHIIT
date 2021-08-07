//
//  MyPickerInterfaceController.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 9/8/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import WatchKit
import Foundation

enum pickerTypes{
	case time, lowHeartRate, highHeartRate
}

class CommonPickerInterfaceController: WKInterfaceController {
	
	@IBOutlet weak var label1: WKInterfaceLabel!
	@IBOutlet weak var label2: WKInterfaceLabel!

	@IBOutlet weak var label3: WKInterfaceLabel!
	@IBOutlet weak var label4: WKInterfaceLabel!
	
	@IBOutlet weak var picker: WKInterfacePicker!
	@IBOutlet weak var buttonAge: WKInterfaceButton!
	
	let LowHeartRateValues: [Int] = [70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150,
									 155,160,165,170,175,180,185,190,195,200]
	
	let TargetHeartRateValues: [Int] = [ 100,105,110,115,120,125,130,135,140,145,150,155,160,165,170,
										 175,180,185,190,195,200,205,210,215,220]
	
	let DurationValues: [Int] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,25,30,35,40,45,50,55,60,65,70,75,80,
								 85,90,95,100,105,110,115,120]
	
	var pickerType = pickerTypes.time
	var usrContext: UserContext!
	var pickedValue: Int!
	
	var age: Int!{
		didSet{
			if let age = age{
				//print("Age changed to \(age)")
				
				var dHeartRate = 0.0
				var iHeartRate = 0
				if pickerType == .highHeartRate{
					dHeartRate = 0.85*(220.0 - Double(age))
					iHeartRate = Int(dHeartRate)
					
					if iHeartRate % 5 > 2{
						iHeartRate = 5 + ( iHeartRate/5*5 )
					}
					else{
						iHeartRate = iHeartRate/5*5
					}
					picker.setSelectedItemIndex(TargetHeartRateValues.firstIndex(of: iHeartRate)!)
				}
				else if pickerType == .lowHeartRate{
					dHeartRate = 0.7*(220.0 - Double(age))
					iHeartRate = Int(dHeartRate)
					
					if iHeartRate % 5 > 2{
						iHeartRate = 5 + ( iHeartRate/5*5 )
					}
					else{
						iHeartRate = iHeartRate/5*5
					}
					picker.setSelectedItemIndex(LowHeartRateValues.firstIndex(of: iHeartRate)!)
				}
				
				usrContext.age = age
			}
		}
	}
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.setTitle("Done")
        // Configure interface objects here.
		
		guard let input = context as? [Any] else{
			dismiss()
			return
		}
		
		guard  let ctx = input.first as? UserContext else {
			dismiss()
			return
		}
		
		guard let typ = input.last as? pickerTypes else{
			dismiss()
			return
		}
		
		usrContext = ctx
		age = ctx.age
		
		let bound = WKInterfaceDevice.current().screenBounds
		
		var items = [WKPickerItem]()
		switch typ{
			
		case .time:
			if bound.width > 156{
				label1.setText("Total workout duration:")
				label2.setText("   ")
			}
			else{
				label1.setText("Total workout")
				label2.setText("duration:")
			}
			label3.setText("")
			label4.setText("min.")
			buttonAge.setHidden(true)
			
			for i in DurationValues {
				let item = WKPickerItem()
				item.title = "\(i)"
				items.append(item)
			}
			picker.setItems(items)
			pickerType = .time
			picker.setSelectedItemIndex(DurationValues.firstIndex(of: ctx.workoutDuration)!)
			
		case .lowHeartRate:
			if bound.width > 156{
				label1.setText("Target heart rate low zone:")
				label2.setText("   ")
			}
			else{
				label1.setText("Target heart rate")
				label2.setText("low zone:")
			}
			label4.setText("bpm")
			label3.setText("Recommend:")
			buttonAge.setHidden(false)
			buttonAge.setTitle("70% of (220 - Age)")
			for i in LowHeartRateValues {
				let item = WKPickerItem()
				item.title = "\(i)"
				items.append(item)
			}
			picker.setItems(items)
			pickerType = .lowHeartRate
			picker.setSelectedItemIndex(LowHeartRateValues.firstIndex(of: ctx.lowHeartRateValue)!)
			
		case .highHeartRate:
			if bound.width > 156{
				label1.setText("Target heart rate high zone:")
				label2.setText("   ")
			}
			else{
				label1.setText("Target heart rate")
				label2.setText("high zone:")
			}
			label3.setText("Recommend:")
			label4.setText("bpm")
			buttonAge.setHidden(false)
			buttonAge.setTitle("85% of (220 - Age)")
			for i in TargetHeartRateValues{
				let item = WKPickerItem()
				item.title = "\(i)"
				items.append(item)
			}
			picker.setItems(items)
			pickerType = .highHeartRate
			picker.setSelectedItemIndex(TargetHeartRateValues.firstIndex(of: ctx.highHeartRateValue)!)
		}
		
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		
		switch pickerType{
			
		case .time:
			usrContext.workoutDuration = pickedValue
		case .lowHeartRate:
			usrContext.lowHeartRateValue = pickedValue
		case .highHeartRate:
			usrContext.highHeartRateValue = pickedValue
		}
    }
	
	override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
		return  self
	}

	@IBAction func pickerAction(_ value: Int)
	{
		switch pickerType{
			
		case .time:
			pickedValue = DurationValues[value]
			
		case .lowHeartRate:
			pickedValue = LowHeartRateValues[value]
			
		case .highHeartRate:

			pickedValue = TargetHeartRateValues[value]
		}
	}
	
}
