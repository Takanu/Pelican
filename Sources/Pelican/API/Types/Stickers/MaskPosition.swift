//
//  MaskPosition.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/12/2017.
//

import Foundation

/**
Defines a point and set of coordinate and scaling parameters to determine where and how a sticker should be placed when added to an image.
*/
public class MaskPosition: Codable {
	
	/// The part of the face relative to which the mask should be placed.
	public var point: MaskPositionPoint
	
	/// The offset by X-axis measured in widths of the mask scaled to the face size, from left to right. For example, choosing -1.0 will place mask just to the left of the default mask position.
	public var offsetX: Float
	
	/// The offset by Y-axis measured in heights of the mask scaled to the face size, from top to bottom. For example, 1.0 will place the mask just below the default mask position.
	public var offsetY: Float
	
	/// How much the mask will be scaled by when used.  Eg. 2.0 will double the scale of the mask.
	public var maskScale: Float
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case point
		case offsetX = "x_shift"
		case offsetY = "y_shift"
		case maskScale = "scale"
	}
	
	public init(point: MaskPositionPoint, offsetX: Float, offsetY: Float, maskScale: Float) {
		self.point = point
		self.offsetX = offsetX
		self.offsetY = offsetY
		self.maskScale = maskScale
	}
}
