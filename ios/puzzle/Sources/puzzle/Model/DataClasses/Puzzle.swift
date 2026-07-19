//
//  Puzzle.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 22 Oct 2019.
//  Copyright (c) 2019 Iron Water Studio. All rights reserved.
//

import Foundation

struct Puzzle {

	var id: Int
	var name: String
	var width: Int
	var height: Int
	var order: Int
	var pieces: [Piece]

	init(id: Int, name: String, width: Int, height: Int, order: Int, pieces: [Piece]) {
		self.id = id
		self.name = name
		self.width = width
		self.height = height
		self.order = order
		self.pieces = pieces
	}

	init() {
		self.init(id: Int(), name: String(), width: Int(), height: Int(), order: Int(), pieces: [Piece]())
	}

}

extension Puzzle: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"Name: \(name)",
			"Width: \(width)",
			"Height: \(height)",
			"Order: \(order)",
			"Pieces: \(pieces)"
			].joined(separator: ", ")
	}
}

extension Puzzle {
	/**
		Example for closure:
		 	(success: @escaping (Puzzle?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Puzzle.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Puzzle.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Puzzle? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Puzzle field \"data\" is not dictionary type"
		}
		
		var model = Puzzle()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Puzzle field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let name: String = try? String.parse(json["name"], model.name) else {
			throw "Puzzle field \"name\" has wrong value \"\(String(describing: json["name"]))\" for type \"String\""
		}
		model.name = name

		guard let width: Int = try? Int.parse(json["width"], model.width) else {
			throw "Puzzle field \"width\" has wrong value \"\(String(describing: json["width"]))\" for type \"Int\""
		}
		model.width = width

		guard let height: Int = try? Int.parse(json["height"], model.height) else {
			throw "Puzzle field \"height\" has wrong value \"\(String(describing: json["height"]))\" for type \"Int\""
		}
		model.height = height

		guard let order: Int = try? Int.parse(json["order"], model.order) else {
			throw "Puzzle field \"order\" has wrong value \"\(String(describing: json["order"]))\" for type \"Int\""
		}
		model.order = order

		do {
			if let pieces: [Piece] = try Piece.array(json["pieces"]) {
				model.pieces = pieces
			}
		} catch { throw "Puzzle field \"pieces\" has wrong value \"\(String(describing: json["pieces"]))\" for type \"[Piece]\"" }

		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Puzzle]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Puzzle.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Puzzle.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Puzzle]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Puzzle field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Puzzle.parse) else { throw "Puzzle field \"data\" contains items with unexpected format" }
		
		return result
	}
}
