//
//  ImageScrollView.swift
//  Mahabharata
//
//  Created by Roman Developer on 12/6/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import AVFoundation

protocol ImageScrollViewDelegate: class {
	func imageScrollViewDidScroll(_ view: ImageScrollView)
}

fileprivate extension SoundAnim {
	struct AssociatedKeys {
		static var playerKey: UInt8 = 0
		static var isPlayingKey: UInt8 = 0
	}

	var player: SoundManager? {
		get {
			guard let value = objc_getAssociatedObject(self, &AssociatedKeys.playerKey) as? SoundManager else {
				return nil
			}
			return value
		}

		set(newValue) {
			objc_setAssociatedObject(self, &AssociatedKeys.playerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	var isPlaying: Bool {
		get {
			guard let value = objc_getAssociatedObject(self, &AssociatedKeys.isPlayingKey) as? Bool else {
				return false
			}
			return value
		}

		set(newValue) {
			objc_setAssociatedObject(self, &AssociatedKeys.isPlayingKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
		}
	}
}

class ImageScrollView: UIScrollView, UIScrollViewDelegate {
	
	var comics: Comics? = nil {
		didSet {
			//TODO: ??
			//[self displayTiledImageNamed:kImageName size:CGSizeMake(_guide.mapInfo.width, _guide.mapInfo.height)];
			//or may be self.updateTiles()?
			//self.configureForImageSize()
			//print("Comics didSet contains \(self.comics!.layers.count) layers")
			if let comics = comics {
				comics.prepare()
				self.displayTiles()
			}
		}
	}
	
	weak var scrollDelegate: ImageScrollViewDelegate?
	
	let tilesContainer = UIView()
	var tilingViews = [TileImageView]()
	
	var isComics = true
		
	//Initial value is less that any real value to play music if its start is 0
	private var previousContentOffset: CGFloat = -1.0
	
	//Array of started players. Corresponds to Sound.SoundAnimation. <animation, SoundManager>
	private var players: [[SoundManager]] = [[SoundManager]]()
	
//	deinit {
//		print("--- deinit tile \(frame)")
//	}
	
	init() {
		super.init(frame: .zero)
		
		self.bouncesZoom = false
		self.bounces = false
		self.showsVerticalScrollIndicator = true
		self.showsHorizontalScrollIndicator = true
		self.delegate = self
		self.contentMode = .scaleToFill
		self.minimumZoomScale = 0
		self.maximumZoomScale = 10
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	//MARK: - Functionality
	func updateTiles() {
		//TODO: Update everything I guess
	}
	
	//MARK: - UIScrollViewDelegate
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.tilesContainer
	}
	
	//MARK: - Configure scrollView to display tiles
	func displayTiles() {
		guard let comics = self.comics, comics.width > 0 else { return }
		
		//For comics mode zoomScale is fixed
		if self.isComics {
			let realContentWidth = UIScreen.main.bounds.size.width
			let zoomScale = realContentWidth / CGFloat(comics.width)
			self.minimumZoomScale = zoomScale
			self.maximumZoomScale = zoomScale
			self.zoomScale = zoomScale
		}
		
		let scaledWidth = CGFloat(comics.width) * self.zoomScale
		let scaledHeight = CGFloat(comics.height) * self.zoomScale
		
		//Add container
		self.addSubview(self.tilesContainer)
		activateConstraints(
			self.tilesContainer.edges().width(CGFloat(comics.width)).height(CGFloat(comics.height))
		)
		
		self.contentSize = CGSize(width: scaledWidth, height: scaledHeight)
		self.tilesContainer.backgroundColor = .black
		
		//Add tiles
		for layer in comics.layers.enumerated() {
			if let image = layer.element.image {
				let tile = TileImageView(image: image)
				
				self.tilingViews.append(tile)
				self.tilesContainer.addSubview(tile)
			}
		}
		
		//Force to load first screen of comics
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.scrollViewDidScroll(self)
		}
	}
	
	private func addTiles() {
		guard let comics = self.comics else { return }
		
		for layer in comics.layers.enumerated() {
			if let image = layer.element.image {
				let tile = TileImageView(image: image)
				
				self.tilingViews.append(tile)
				self.tilesContainer.addSubview(tile)
			}
		}
	}
	
	private var isReloading = false
	
	func reloadLanguage() {
		guard !isReloading else {
			return
		}
		
		isReloading = true

		//Remove old tiles/UIImages to free memory
		var hiddenTiles: [TileImageView] = []
		var visibleTiles: [TileImageView] = []
		
		let visibleRectHeight = self.frame.size.height / self.zoomScale
		let visibleRectWidth = self.frame.size.width / self.zoomScale
		let intersectRect = CGRect(x: -visibleRectWidth, y: self.contentOffset.y / self.zoomScale - visibleRectHeight,
								   width: visibleRectWidth * 3, height: visibleRectHeight * 3)
		for tile in self.tilingViews {
			if !tile.frame.intersects(intersectRect) {
				hiddenTiles.append(tile)
			} else {
				visibleTiles.append(tile)
			}
		}
		
		//Forget all tiles
		self.tilingViews = []
		
		//Remove only invisible tiles
		for tile in hiddenTiles {
			tile.removeFromSuperview()
		}
		
		//Add tiles with info about images to reload. Thay are not actually reloaded until scroll
		self.addTiles()
		
		//Reload tiles to visible frame (without playing music again)
		self.loadComics(scrollView: self, sound: false)

		//Remove tiles that are visible/near to visible
		for tile in visibleTiles {
			tile.removeFromSuperview()
		}
		
		isReloading = false
	}
	
	//MARK: - UIScrollViewDelegate
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard let _ = self.comics else { return }
		
		self.scrollDelegate?.imageScrollViewDidScroll(self)
		
		loadComics(scrollView: self, sound: true)
	}

	func loadComics(scrollView: UIScrollView, sound: Bool) {
		guard let comics = self.comics else { return }
		
		if scrollView.contentOffset.y < 0.0 {
			previousContentOffset = scrollView.contentOffset.y
			return
		}
		
//		let start = NSTimeIntervalSince1970
		
		comics.process(scrollOffset: Int(scrollView.contentOffset.y / self.zoomScale))		
		
		//At this point all layer matrixes are processed
		//Now we should calculate layer frame based on matrix and size of layer
		//After that we should check if this frame intersects with current scroll region + some bounds
		//If yes, load TileImageView into memory. If not, do not load it and unload the ones not needed anymore
		//TileImageView seems to know nothing about zoomScale, so we will pass unscaled region
		//Should work flawlessly
		
		//3x height
		let visibleRectHeight = scrollView.frame.size.height / self.zoomScale
		let visibleRectWidth = scrollView.frame.size.width / self.zoomScale
		let intersectRect = CGRect(x: -visibleRectWidth, y: scrollView.contentOffset.y / self.zoomScale - visibleRectHeight,
										width: visibleRectWidth * 3, height: visibleRectHeight * 3)
		
		for layer in comics.layers.enumerated() {
			let tile = self.tilingViews[layer.offset]
			tile.transform = CATransform3DGetAffineTransform(layer.element.matrix)
			tile.alpha = CGFloat(layer.element.alpha)
			
			let intersects = tile.frame.intersects(intersectRect)
			if intersects {
				//TODO: we should keep order of subviews the same as in self.comics!.layers
				tile.prepareTiles()
			}
			else {
				//Remove info about images of tiles. Images will still be displayed
				//Do not remove from superview! It will result in black squares
				tile.killTiles()
			}
		}
		
		//Play comics sound when got content offset specified for sound
		if !Settings.shared.soundOff {
			self.playSoundsByOffset()
		}
		
//		print("Draw Interval: \(NSTimeIntervalSince1970 - start)")
		
		previousContentOffset = scrollView.contentOffset.y
	}
	
	private func playSoundsByOffset() {
		guard let comics = self.comics else { return }
		
		for sound in comics.sounds {
			if let file = sound.file {
				for animation in sound.animations {
					
					let animationStart = CGFloat(animation.start) * self.zoomScale
					let animationEnd = CGFloat(animation.end) * self.zoomScale
					
					if animationStart == animationEnd {
//						print("---- Single animation: \(animationStart)")
						
						//NOTE: previous content offset is for single animations (because we do not track their end), and isPlaying is for range animations
						//Do not play single sound if scrolls top
						if previousContentOffset > contentOffset.y {
							break
						}
						
						if previousContentOffset < animationStart && contentOffset.y >= animationStart {
							print("********** single sound: \(file)")
							self.playSound(animation: animation, file: file)
						}
					} else if animationStart < animationEnd {
//						print("---- Range animation: \(animationStart) - \(animationEnd)")

						//Play background sound if scrolled to animation offset range
						//Do not play animation that is already playing
						if !animation.isPlaying &&
							contentOffset.y >= animationStart && contentOffset.y <= animationEnd {
							
							print("********** range sound (loop): \(file)")
							self.playSound(animation: animation, file: file)
							
						} else if animation.player != nil && animation.isPlaying &&
							(contentOffset.y < animationStart || contentOffset.y > animationEnd) {
							
							print("********** stopped range sound: \(file)")
							//Stop background sound if went out animation offset range
							self.stopSound(animation: animation)
						}
					}
				}
			}
		}
	}
	
	private func playSound(animation: SoundAnim, file: String) {
		
		animation.isPlaying = true
		
		if let animationPlayer = animation.player, animationPlayer.isMuted  {
			animationPlayer.isMuted = false
		}
		else {
			if animation.player == nil {
				animation.player = SoundManager(audioSessionCategory: AVAudioSession.Category.ambient.rawValue)
			}
			else {
				animation.player?.seek(time: 0.0)
				SoundManager.shared.setupSharedAudioSession(audioSessionCategory: AVAudioSession.Category.ambient.rawValue)
			}
			
			DispatchQueue.main.async {
				//Get sound from archive
				let arcMan = ArchiveManager()
				arcMan.currentArchiveURL = ArchiveManager.shared.currentArchiveURL
				arcMan.sound(name: file, success: { (url) in
					if let url = url, let player = animation.player {
						//play sound from extracted data
						print("*** Extracted sound")
						player.play(url: url, loop: animation.start != animation.end)
						
						//NO need, because we use this flag only for range animations
						//					if animation.start == animation.end {
						//						DispatchQueue.main.asyncAfter(deadline: .now() + SoundManager.duration(url: url), execute: {
						//							animation.isPlaying = false
						//						})
						//					}
					}
					else {
						print("*** Missing sound file")
						animation.isPlaying = false
					}
				})
			}
		}
	}
	
	private func stopSound(animation: SoundAnim) {
		animation.isPlaying = false
		animation.player!.fadeOut(to: 0, duration: 0.6)
	}
	
	private func toggleSounds(play: Bool) {
		guard let comics = self.comics else { return }
		
		for sound in comics.sounds {
			if sound.file != nil {
				for animation in sound.animations {
					if let animationPlayer = animation.player {
						
						animationPlayer.isMuted = false
						
						if play {
							animationPlayer.resume()
						}
						else {
							animationPlayer.pause()
						}
						animation.isPlaying = play
					}
				}
			}
		}
	}
	
	func pauseSounds() {
		toggleSounds(play: false)
	}
	
	func resumeSounds() {
		toggleSounds(play: true)
	}

	func mute(_ muted: Bool) {
		guard let comics = self.comics else { return }
		
		for sound in comics.sounds {
			if sound.file != nil {
				for animation in sound.animations {
					if let animationPlayer = animation.player {
						
						animationPlayer.isMuted = muted
						animation.isPlaying = !muted
					}
				}
			}
		}
	}
}

//TODO: Check if usefull
//	func configureForImageSize() {	//:(CGSize)imageSize
//		self.contentSize = CGSize(width: comics!.width, height: comics!.height)
//		//[self setMaxMinZoomScalesForCurrentBounds];
//
//		//Initial scale
//		self.zoomScale = 1 //_guide.mapInfo.scale > self.maximumZoomScale ? self.maximumZoomScale : _guide.mapInfo.scale;
//
//		//Initial offset
//		//	CGPoint contentOffset = CGPointMake(_guide.mapInfo.centerX * self.zoomScale, _guide.mapInfo.centerY * self.zoomScale);
//		//	self.contentOffset = contentOffset;
//	}
//
//	func setMaxMinZoomScalesForCurrentBounds() {
//		let boundsSize = self.bounds.size
//
//		// calculate min/max zoomscale
//		let xScale = boundsSize.width  / CGFloat(self.comics!.width)    // the scale needed to perfectly fit the image width-wise
//		let yScale = boundsSize.height / CGFloat(self.comics!.height)   // the scale needed to perfectly fit the image height-wise
//
//		// fill width if the image and phone are both portrait or both landscape; otherwise take larger scale
//		//!!!
//		//BOOL imagePortrait = _imageSize.height > _imageSize.width;
//		//BOOL phonePortrait = boundsSize.height > boundsSize.width;
//		var minScale = /*imagePortrait == phonePortrait ? xScale :*/ CGFloat.maximum(xScale, yScale)
//
//		// on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
//		// maximum zoom scale to 0.5.
//		let maxScale: CGFloat = UIScreen.main.scale > 1 ? 0.8 : 1.0
//
//		// don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
//		if minScale > maxScale {
//			minScale = maxScale
//		}
//
//		self.maximumZoomScale = maxScale
//		self.minimumZoomScale = minScale
//	}
//
//	//MARK: - Methods called during rotation to preserve the zoomScale and the visible portion of the image
//	func prepareToResize() {
//		let boundsCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
//		self.pointToCenterAfterResize = self.convert(boundsCenter, to: self.tilesContainer)
//
//		self.scaleToRestoreAfterResize = self.zoomScale
//
//		// If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
//		// allowable scale when the scale is restored.
//		if self.scaleToRestoreAfterResize < self.minimumZoomScale {
//			self.scaleToRestoreAfterResize = 0
//		}
//	}
//
//	func recoverFromResizing() {
//		self.setMaxMinZoomScalesForCurrentBounds()
//
//		// Step 1: restore zoom scale, first making sure it is within the allowable range.
//		let maxZoomScale = CGFloat.maximum(self.minimumZoomScale, self.scaleToRestoreAfterResize);
//		self.zoomScale = CGFloat.minimum(self.maximumZoomScale, maxZoomScale);
//
//		// Step 2: restore center point, first making sure it is within the allowable range.
//
//		// 2a: convert our desired center point back to our own coordinate space
//		let boundsCenter = self.convert(self.pointToCenterAfterResize, from: self.tilesContainer)
//
//		// 2b: calculate the content offset that would yield that center point
//		var offset = CGPoint(x: boundsCenter.x - self.bounds.size.width / 2.0, y: boundsCenter.y - self.bounds.size.height / 2.0)
//
//		// 2c: restore offset, adjusted to be within the allowable range
//		let maxOffset = self.maximumContentOffset()
//		let minOffset = self.minimumContentOffset()
//
//		var realMaxOffset = CGFloat.minimum(maxOffset.x, offset.x)
//		offset.x = CGFloat.maximum(minOffset.x, realMaxOffset)
//
//		realMaxOffset = CGFloat.minimum(maxOffset.y, offset.y)
//		offset.y = CGFloat.maximum(minOffset.y, realMaxOffset)
//
//		self.contentOffset = offset
//	}
//
//	func maximumContentOffset() -> CGPoint {
//		return CGPoint(x: self.contentSize.width - self.bounds.size.width, y: self.contentSize.height - self.bounds.size.height)
//	}
//
//	func minimumContentOffset() -> CGPoint {
//		return .zero
//	}
