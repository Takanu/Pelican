//
//  Sticker+MaskPosition.swift
//  Pelican
//
//  Created by Lev Sokolov on 9/24/17.
//

import Foundation
import Vapor
import FluentProvider

final public class MaskPosition: TelegramType {
	public enum Point: String {
		case forehead
		case eyes
		case mouth
		case chin
	}
	
	public var storage = Storage()
	
	public var point: Point
	public var x_shift: Float
	public var y_shift: Float
	public var scale: Float
	
	public init(point: Point, x_shift: Float, y_shift: Float, scale: Float) {
		self.point = point
		self.x_shift = x_shift
		self.y_shift = y_shift
		self.scale = scale
	}
	
	// RowConvertible conforming methods
	public required init(row: Row) throws {
		guard
			let pointRow: String = try row.get("point"),
			let point = Point(rawValue: pointRow)
		else { throw TypeError.ExtractFailed }
		
		self.point = point
		self.x_shift = try row.get("x_shift")
		self.y_shift = try row.get("y_shift")
		self.scale = try row.get("scale")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		
		try row.set("point", point.rawValue)
		try row.set("x_shift", x_shift)
		try row.set("y_shift", y_shift)
		try row.set("scale", scale)
		
		return row
	}
}
