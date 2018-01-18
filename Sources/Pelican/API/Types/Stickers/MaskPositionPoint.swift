//
//  MaskPositionPoint.swift
//  Pelican
//
//  Created by Ido Constantine on 21/12/2017.
//

import Foundation

/**
Defines a collection of positions that a mask should automatically be moved to when added to an image.
*/
public enum MaskPositionPoint: String, Codable {
	case forehead
	case eyes
	case mouth
	case chin
}
