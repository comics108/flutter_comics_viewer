//
//  Piece.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 22 Oct 2019.
//  Copyright (c) 2019 Iron Water Studio. All rights reserved.
//

import Foundation

struct Piece {

	var id: Int
	var x: Int
	var y: Int
	var width: Int
	var height: Int
	var file: String
	var version: Int
	var date: Date
	var order: Int

	init(id: Int, x: Int, y: Int, width: Int, height: Int, file: String, version: Int, date: Date, order: Int) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.file = file
		self.version = version
		self.date = date
		self.order = order
	}

	init() {
		self.init(id: Int(), x: Int(), y: Int(), width: Int(), height: Int(), file: String(), version: Int(), date: Date(), order: Int())
	}

}

extension Piece: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"X: \(x)",
			"Y: \(y)",
			"Width: \(width)",
			"Height: \(height)",
			"File: \(file)",
			"Version: \(version)",
			"Date: \(date)",
			"Order: \(order)"
			].joined(separator: ", ")
	}
}

extension Piece {
	/**
		Example for closure:
		 	(success: @escaping (Piece?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Piece.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Piece.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Piece? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Piece field \"data\" is not dictionary type"
		}
		
		var model = Piece()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Piece field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let x: Int = try? Int.parse(json["x"], model.x) else {
			throw "Piece field \"x\" has wrong value \"\(String(describing: json["x"]))\" for type \"Int\""
		}
		model.x = x

		guard let y: Int = try? Int.parse(json["y"], model.y) else {
			throw "Piece field \"y\" has wrong value \"\(String(describing: json["y"]))\" for type \"Int\""
		}
		model.y = y

		guard let width: Int = try? Int.parse(json["width"], model.width) else {
			throw "Piece field \"width\" has wrong value \"\(String(describing: json["width"]))\" for type \"Int\""
		}
		model.width = width

		guard let height: Int = try? Int.parse(json["height"], model.height) else {
			throw "Piece field \"height\" has wrong value \"\(String(describing: json["height"]))\" for type \"Int\""
		}
		model.height = height

		guard let file: String = try? String.parse(json["file"], model.file) else {
			throw "Piece field \"file\" has wrong value \"\(String(describing: json["file"]))\" for type \"String\""
		}
		model.file = file

		guard let version: Int = try? Int.parse(json["version"], model.version) else {
			throw "Piece field \"version\" has wrong value \"\(String(describing: json["version"]))\" for type \"Int\""
		}
		model.version = version

		guard let date: Date = try? Date.parse(json["date"], model.date) else {
			throw "Piece field \"date\" has wrong value \"\(String(describing: json["date"]))\" for type \"Date\""
		}
		model.date = date

		guard let order: Int = try? Int.parse(json["order"], model.order) else {
			throw "Piece field \"order\" has wrong value \"\(String(describing: json["order"]))\" for type \"Int\""
		}
		model.order = order

		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Piece]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Piece.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Piece.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Piece]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Piece field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Piece.parse) else { throw "Piece field \"data\" contains items with unexpected format" }
		
		return result
	}
}
