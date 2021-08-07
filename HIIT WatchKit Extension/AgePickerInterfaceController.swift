//
//  AgeInterfaceController.swift
//  HIIT WatchKit Extension
//
//  Created by karu on 9/8/19.
//  Copyright © 2019 SCode. All rights reserved.
//

import WatchKit
import Foundation


class AgePickerInterfaceController: WKInterfaceController {
	@IBOutlet weak var agePicker: WKInterfacePicker!
	
	let ageValues: [Int] = [15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
					31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,
					51,52,53,54,55,56,57,58,59,60,61,61,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80]
	var age = 15
	
	
	var userContext: UserContext!
	var parent: CommonPickerInterfaceController!
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.setTitle("Done")
        // Configure interface objects here.

		guard let parent = context as? CommonPickerInterfaceController else {
			dismiss()
			return
		}
		self.parent = parent
		
		if let age = parent.age{
			self.age = age
		}
 
		var items = [WKPickerItem]()
		
		for i in ageValues {
			let item = WKPickerItem()
			item.title = "\(i)"
			items.append(item)
		}
		agePicker.setItems(items)
    }
	
	override func didAppear() {
		agePicker.setSelectedItemIndex(ageValues.firstIndex(of: age)!)
	}

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		parent.age = age
    }

	@IBAction func SelectedAge(_ value: Int)
	{
		age = ageValues[value]
		//print("Age=\(age)")
	}
}
