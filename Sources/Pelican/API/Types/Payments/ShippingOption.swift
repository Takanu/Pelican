//
//  ShippingOption.swift
//  Pelican
//
//  Created by Ido Constantine on 18/12/2017.
//

import Foundation


/**
Represents one shipping option for the Telegram Payment API.
*/
public class ShippingOption: Codable {
	
	/// The shipping option identifier.
	var id: String = ""
	
	/// The name of the shipping option.
	var title: String = ""
	
	/// A list of costs associated with the shipping option.
	var prices: [LabeledPrice] = []
	
	
}
