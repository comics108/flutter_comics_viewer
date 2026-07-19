//
//  TilingView.swift
//  Mahabharata
//
//  Created by Roman Developer on 12/5/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class CATiledLayerNoAnim: CATiledLayer {
	override open class func fadeDuration() -> CFTimeInterval {
		return 0
	}
}

class TileImageView: UIView {
	
	enum Constants {
		static let tileWidth: CGFloat = 512.0
		static let tileSize = CGSize(width: tileWidth, height: tileWidth)
	}
	
	let scale: CGFloat = 1.0	//at least for comix this is always true
	
	let image: Image
	var tiles = [String: UIImage]()
	var tilesLoaded = false
	
	override public class var layerClass: Swift.AnyClass {
		return CATiledLayerNoAnim.self
	}
	
	init(image: Image) {
		self.image = image
		
		super.init(frame: CGRect(x: 0, y: 0, width: image.width, height: image.height))
		
		self.backgroundColor = .clear
		
		if let tiledLayer = self.layer as? CATiledLayerNoAnim {
			tiledLayer.levelsOfDetail = 1	//at least for comix this is always true
			tiledLayer.tileSize = Constants.tileSize
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// to handle the interaction between CATiledLayer and high resolution screens, we need to
	// always keep the tiling view's contentScaleFactor at 1.0. UIKit will try to set it back
	// to 2.0 on retina displays, which is the right call in most cases, but since we're backed
	// by a CATiledLayer it will actually cause us to load the wrong sized tiles.
	override var contentScaleFactor: CGFloat {
		get {
			return super.contentScaleFactor
		}
		set {
			super.contentScaleFactor = 1
		}
	}
	
	override func draw(_ rect: CGRect) {
		//print("Rect draw \(self.image.file!): \(rect)")
		
//		let start = NSTimeIntervalSince1970
		
		guard let ctx = UIGraphicsGetCurrentContext() else { return }
		
		// get the scale from the context by getting the current transform matrix, then asking
		// for its "a" component, which is one of the two scale components. We could also ask
		// for "d". This assumes (safely) that the view is being scaled equally in both dimensions.
		let scale = ctx.ctm.a
		//print("Scale \(scale)")
		
		//Do not use layer property to avoid DispatchQueue.main.async & black screen
		var tileSize = Constants.tileSize

		// Even at scales lower than 100%, we are drawing into a rect in the coordinate system
		// of the full image. One tile at 50% covers the width (in original image coordinates)
		// of two tiles at 100%. So at 50% we need to stretch our tiles to double the width
		// and height; at 25% we need to stretch them to quadruple the width and height; and so on.
		// (Note that this means that we are drawing very blurry images as the scale gets low.
		// At 12.5%, our lowest scale, we are stretching about 6 small tiles to fill the entire
		// original image area. But this is okay, because the big blurry image we're drawing
		// here will be scaled way down before it is displayed.)
		tileSize.width /= scale
		tileSize.height /= scale
		//print("Tile size 2: \(tileSize)")

		// calculate the rows and columns of tiles that intersect the rect we have been asked to draw
		let firstCol = Int(floor(rect.minX / tileSize.width))
		let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
		let firstRow = Int(floor(rect.minY / tileSize.height))
		let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))
		
		for row in firstRow...lastRow {
			for col in firstCol...lastCol {
				var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
				let tileName = self.tileName(for: scale, row: row, col: col)
				
				if let tile = self.tiles[tileName] {
					// if the tile would stick outside of our bounds, we need to truncate it so as
					// to avoid stretching out the partial tiles at the right and bottom edges
					tileRect = rect.intersection(tileRect)
					tile.draw(in: tileRect)
					print("RENDERED: Tile with name: \(tileName)")
				}
				else {
					print("ERROR: No tile with name: \(tileName)")
				}
			}
		}
		
//		print("Draw Interval: \(NSTimeIntervalSince1970 - start)")
	}
	
	//MARK: - Functionality
	//TODO: This should be called on possible scale change. Also actually not all tiles should be loaded, but the ones needed (should be optimized)
	func prepareTiles() {
		
		if self.tilesLoaded {
			return
		} else {
			self.tilesLoaded = true
		}
		
		// calculate the rows and columns of tiles that intersect the rect we have been asked to draw
		let firstCol = 0
		let lastCol = Int(floor((CGFloat(self.image.width)) / Constants.tileWidth))
		let firstRow = 0
		let lastRow = Int(floor((CGFloat(self.image.height)) / Constants.tileWidth))
		
		let arcMan = ArchiveManager()
		arcMan.currentArchiveURL = ArchiveManager.shared.currentArchiveURL
		
		for row in firstRow...lastRow {
			for col in firstCol...lastCol {
				let tileName = self.tileName(for: self.scale, row: row, col: col)
				arcMan.layer(name: tileName, success: { [weak self] (image) in
					guard let self = self else { return }
					self.tiles[tileName] = image
					print("LOADED: Tile with name: \(tileName)")
					self.setNeedsDisplay()	//TODO:
				})
			}
		}
	}
	
	func killTiles() {
		self.tilesLoaded = false
		self.tiles.removeAll()
	}
	
	func tileName(for scale: CGFloat, row: Int, col: Int) -> String {
		return self.image.file!
			.replace("{0}", withValue: Int(scale * 1000).description)
			.replace("{1}", withValue: col.description)
			.replace("{2}", withValue: row.description)
	}
	
//	private class Tile {
//		var rect: CGRect = .zero
//		var fileName: String = ""
//
//		init(column: Int, row: Int, scale: CGFloat, tileSize: CGFloat, contentRect: CGRect, template: String) {
//			self.rect = CGRect(x: CGFloat(column) * tileSize / scale, y: CGFloat(row) * tileSize / scale,
//							   width: self.computeSize(contentSize: contentRect.size.width, zoomLevel: scale, index: column, tileSize: tileSize),
//							   height: self.computeSize(contentSize: contentRect.size.height, zoomLevel: scale, index: row, tileSize: tileSize))
//
//			self.fileName = template
//				.replace("{0}", withValue: Int(scale * 1000).description)
//				.replace("{1}", withValue: column.description)
//				.replace("{2}", withValue: row.description)
//		}
//
//		init(rect: CGRect, fileName: String) {
//			self.rect = rect
//			self.fileName = fileName
//		}
//
//		private func computeSize(contentSize: CGFloat, zoomLevel: CGFloat, index: Int, tileSize: CGFloat) -> CGFloat {
//			return CGFloat.minimum(tileSize, contentSize * zoomLevel - tileSize * CGFloat(index)) / zoomLevel
//		}
//
//		func isVisible(visibleRect: CGRect) -> Bool {
//			return self.rect.intersects(visibleRect)
//		}
//
//		func isPreloadBitmap(preloadBitmapRect: CGRect) -> Bool {
//			return self.rect.intersects(preloadBitmapRect)
//		}
//	}
}
