package flixel.graphics;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.graphics.frames.AtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FrameCollectionType;
import flixel.graphics.frames.ImageFrame;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;

/**
 * BitmapData wrapper which is used for rendering.
 * It stores info about all frames, generated for specific BitmapData object.
 */
class FlxGraphic
{
	/**
	 * Creates and caches FlxGraphic object from openfl.Assets key string.
	 * 
	 * @param	Source	openfl.Assets key string. For example: "assets/image.png".
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static function fromAssetKey(Source:String, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var key:String = FlxG.bitmap.generateKey(Source, Key, Unique);
		var graphic:FlxGraphic = FlxG.bitmap.get(key);
		if (graphic != null)
		{
			return graphic;
		}
		
		var bitmap:BitmapData = FlxAssets.getBitmapData(Source);
		graphic = createGraphic(bitmap, key, Unique);
		graphic.assetsKey = Source;
		return graphic;
	}
	
	/**
	 * Creates and caches FlxGraphic object from specified Class<BitmapData>.
	 * 
	 * @param	Source	Class<BitmapData> to create BitmapData for FlxGraphic from.
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static function fromClass(Source:Class<BitmapData>, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var key:String = FlxG.bitmap.getKeyForClass(Source);
		key = FlxG.bitmap.generateKey(key, Key, Unique);
		var graphic:FlxGraphic = FlxG.bitmap.get(key);
		if (graphic != null)
		{
			return graphic;
		}
		
		var bitmap:BitmapData = FlxAssets.getBitmapFromClass(Source);
		graphic = createGraphic(bitmap, key, Unique);
		graphic.assetsClass = Source;
		return graphic;
	}
	
	/**
	 * Creates and caches FlxGraphic object from specified BitmapData object.
	 * 
	 * @param	BitmapData for FlxGraphic object to use.
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static function fromBitmapData(Source:BitmapData, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var key:String = FlxG.bitmap.findKeyForBitmap(Source);
		
		var assetKey:String = null;
		var assetClass:Class<BitmapData> = null;
		var graphic:FlxGraphic = null;
		if (key != null)
		{
			graphic = FlxG.bitmap.get(key);
			assetKey = graphic.assetsKey;
			assetClass = graphic.assetsClass;
		}
		
		key = FlxG.bitmap.generateKey(key, Key, Unique);
		graphic = FlxG.bitmap.get(key);
		if (graphic != null)
		{
			return graphic;
		}
		
		graphic = createGraphic(Source, key, Unique);
		graphic.assetsKey = assetKey;
		graphic.assetsClass = assetClass;
		return graphic;
	}
	
	/**
	 * Creates and caches FlxGraphic object from specified FlxFrame object.
	 * It uses frame's BitmapData, not the frame.parent.bitmap.
	 * 
	 * @param	FlxFrame to get BitmapData from for FlxGraphic object.
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static function fromFrame(Source:FlxFrame, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var key:String = Source.name;
		if (key == null)
		{
			key = Source.frame.toString();
		}
		key = Source.parent.key + ":" + key;
		key = FlxG.bitmap.generateKey(key, Key, Unique);
		var graphic:FlxGraphic = FlxG.bitmap.get(key);
		if (graphic != null)
		{
			return graphic;
		}
		
		var bitmap:BitmapData = Source.getBitmap().clone();
		graphic = createGraphic(bitmap, key, Unique);
		var image:ImageFrame = ImageFrame.fromGraphic(graphic);
		image.getByIndex(0).name = Source.name;
		return graphic;
	}
	
	/**
	 * Creates and caches FlxGraphic object from specified FlxFramesCollection object.
	 * It uses frames.parent.bitmap as a source for FlxGraphic BitmapData.
	 * It also copies all the frames collections onto newly created FlxGraphic.
	 * 
	 * @param	FlxFramesCollection to get BitmapData from for FlxGraphic object.
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static inline function fromFrames(Source:FlxFramesCollection, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		return fromGraphic(Source.parent, Unique, Key);
	}
	
	/**
	 * Creates and caches FlxGraphic object from specified FlxGraphic object.
	 * It copies all the frames collections onto newly created FlxGraphic.
	 * 
	 * @param	FlxGraphic to get BitmapData from for FlxGraphic object.
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache. If true, then BitmapData for this FlxGraphic will be cloned, which means extra memory.
	 * @param	Key	Force the cache to use a specific Key to index the bitmap.
	 * @return	Cached FlxGraphic object we just created.
	 */
	public static function fromGraphic(Source:FlxGraphic, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		if (!Unique)
		{
			return Source;
		}
		
		var key:String = FlxG.bitmap.generateKey(Source.key, Key, Unique);
		var graphic:FlxGraphic = createGraphic(Source.bitmap, key, Unique);
		graphic.unique = Unique;
		graphic.assetsClass = Source.assetsClass;
		graphic.assetsKey = Source.assetsKey;
		return FlxG.bitmap.addGraphic(graphic);
	}
	
	/**
	 * Generates and caches new FlxGraphic object with a colored rectangle.
	 * 
	 * @param	Width	How wide the rectangle should be.
	 * @param	Height	How high the rectangle should be.
	 * @param	Color	What color the rectangle should be (0xAARRGGBB)
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key		Force the cache to use a specific Key to index the bitmap.
	 * @return	The FlxGraphic object we just created.
	 */
	public static function createRectangle(Width:Int, Height:Int, Color:Int, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var systemKey:String = Width + "x" + Height + ":" + Color;
		var key:String = FlxG.bitmap.generateKey(systemKey, Key, Unique);
		
		var graphic:FlxGraphic = FlxG.bitmap.get(key);
		if (graphic != null)
		{
			return graphic;
		}
		
		var bitmap:BitmapData = new BitmapData(Width, Height, true, Color);
		return createGraphic(bitmap, key);
	}
	
	/**
	 * Helper method for cloning specified BitmapData if necessary.
	 * Added to reduce code duplications.
	 * 
	 * @param	Bitmap 	BitmapData to process
	 * @param	Unique	Whether we need to clone specified BitmapData object or not
	 * @return	Processed BitmapData
	 */
	private static inline function getBitmap(Bitmap:BitmapData, Unique:Bool = false):BitmapData
	{
		if (Unique)
		{
			Bitmap = Bitmap.clone();
		}
		
		return Bitmap;
	}
	
	/**
	 * Creates and caches specified BitmapData object.
	 * 
	 * @param	Bitmap	BitmapData to use as a graphic source for new FlxGraphic.
	 * @param	Key		Key to use as a cache key for created FlxGraphic.
	 * @param	Unique	Whether new FlxGraphic object uses unique BitmapData or not. If true, then specified BitmapData will be cloned.
	 * @return	Created and cached FlxGraphic object.
	 */
	private static function createGraphic(Bitmap:BitmapData, Key:String, Unique:Bool = false):FlxGraphic
	{
		Bitmap = FlxGraphic.getBitmap(Bitmap, Unique);
		var graphic:FlxGraphic = new FlxGraphic(Key, Bitmap);
		graphic.unique = Unique;
		FlxG.bitmap.addGraphic(graphic);
		return graphic;
	}
	
	/**
	 * Key in BitmapFrontEnd cache
	 */
	public var key:String;
	/**
	 * Cached BitmapData object
	 */
	public var bitmap:BitmapData;
	
	/**
	 * The width of cached BitmapData.
	 * Added for faster access/typing
	 */
	public var width(default, null):Int = 0;
	/**
	 * The height of cached BitmapData.
	 * Added for faster access/typing
	 */
	public var height(default, null):Int = 0;
	
	/**
	 * Asset name from openfl.Assets
	 */
	public var assetsKey:String;
	/**
	 * Class name for the BitmapData
	 */
	public var assetsClass:Class<BitmapData>;
	
	/**
	 * Whether this graphic object should stay in cache after state changes or not.
	 */
	public var persist:Bool = false;
	/**
	 * Whether we should destroy this FlxGraphic object when useCount become zero.
	 * Default is true.
	 */
	public var destroyOnNoUse(get, set):Bool;
	
	/**
	 * Whether the BitmapData of this graphic object has been dumped or not.
	 */
	public var isDumped(default, null):Bool = false;
	/**
	 * Whether the BitmapData of this graphic object can be dumped for decreased memory usage,
	 * but may cause some issues (when you need direct access to pixels of this graphic.
	 * If the graphic is dumped then you should call undump() and have total access to pixels.
	 */
	public var canBeDumped(get, never):Bool;
	
	#if FLX_RENDER_TILE
	/**
	 * Tilesheet for this graphic object. It is used only for FLX_RENDER_TILE mode
	 */
	public var tilesheet(get, null):TileSheetExt;
	#end
	
	/**
	 * Usage counter for this FlxGraphic object.
	 */
	public var useCount(get, set):Int;
	
	/**
	 * ImageFrame object for the whole bitmap
	 */
	public var imageFrame(get, null):ImageFrame;
	
	/**
	 * Atlas frames for this graphic.
	 * You should fill it yourself with one of the AtlasFrames static methods
	 * (like texturePackerJSON(), texturePackerXML(), sparrow(), libGDX()).
	 */
	public var atlasFrames:AtlasFrames;
	
	// TODO: add font frames and bar frames
	
	/**
	 * Storage for all available frame collection of all types for this graphic object.
	 */
	private var frameCollections:Map<FrameCollectionType, Array<Dynamic>>;
	
	/**
	 * All types of frames collection which had been added to this graphic object.
	 * It helps to avoid map iteration, which produces a lot of garbage.
	 */
	private var frameCollectionTypes:Array<FrameCollectionType>;
	
	/**
	 * Shows whether this object unique in cache or not.
	 * 
	 * Whether undumped BitmapData should be cloned or not.
	 * It is false by default, since significantly reduces memory consumption.
	 */
	public var unique:Bool = false;
	
	/**
	 * Internal var holding ImageFrame for the whole bitmap of this graphic.
	 * Use public imageFrame var to access/generate it.
	 */
	private var _imageFrame:ImageFrame;
	
	#if FLX_RENDER_TILE
	/**
	 * Internal var holding Tilesheet for bitmap of this graphic.
	 * It is used only in FLX_RENDER_TILE mode
	 */
	private var _tilesheet:TileSheetExt;
	#end
	
	private var _useCount:Int = 0;
	
	private var _destroyOnNoUse:Bool = true;
	
	/**
	 * FlxGraphic constructor
	 * @param	Key			key string for this graphic object, with which you can get it from bitmap cache
	 * @param	Bitmap		BitmapData for this graphic object
	 * @param	Persist		Whether or not this graphic stay in the cache after reseting cache. Default value is false which means that this graphic will be destroyed at the cache reset.
	 */
	private function new(Key:String, Bitmap:BitmapData, Unique:Bool = false)
	{
		key = Key;
		bitmap = Bitmap;
		unique = Unique;
		
		width = bitmap.width;
		height = bitmap.height;
		
		frameCollections = new Map<FrameCollectionType, Array<Dynamic>>();
		frameCollectionTypes = new Array<FrameCollectionType>();
	}
	
	/**
	 * Dumps bits of bitmapdata == less memory, but you can't read/write pixels on it anymore
	 * (but you can call onContext() (or undump()) method which will restore it again)
	 */
	public function dump():Void
	{
		#if (FLX_RENDER_TILE && !flash && !nme)
		if (canBeDumped)
		{
			bitmap.dumpBits();
			isDumped = true;
		}
		#end
	}
	
	/**
	 * Undumps bits of bitmapdata - regenerates it and regenerate tilesheet data for this object
	 */
	public function undump():Void
	{
		var newBitmap:BitmapData = getBitmapFromSystem();	
		if (newBitmap != null)
		{
			bitmap = newBitmap;
			#if (FLX_RENDER_TILE && !flash && !nme)
			if (_tilesheet != null)
			{
				_tilesheet = TileSheetExt.rebuildFromOld(_tilesheet, this);
			}
			#end
		}
		
		isDumped = false;
	}
	
	/**
	 * Use this method to restore cached bitmapdata (if it's possible).
	 * It's called automatically when the RESIZE event occurs.
	 */
	public function onContext():Void
	{
		// no need to restore tilesheet if it haven't been dumped
		if (isDumped)
		{
			undump();	// restore everything
			dump();		// and dump bitmapdata again
		}
	}
	
	/**
	 * Asset reload callback for this graphic object.
	 * It regenerated its tilesheet and resets frame bitmaps.
	 */
	public function onAssetsReload():Void
	{
		if (!canBeDumped)	return;
		
		var dumped:Bool = isDumped;
		undump();
		resetFrameBitmaps();
		if (dumped)
		{
			dump();
		}
	}
	
	/**
	 * Trying to free the memory as much as possible
	 */
	public function destroy():Void
	{
		bitmap = FlxDestroyUtil.dispose(bitmap);
		#if FLX_RENDER_TILE
		_tilesheet = FlxDestroyUtil.destroy(_tilesheet);
		#end
		key = null;
		assetsKey = null;
		assetsClass = null;
		_imageFrame = null;	// no need to dispose _imageFrame since it exists in imageFrames
		atlasFrames = null;
		
		var collections:Array<FlxFramesCollection>;
		var collectionType:FrameCollectionType;
		for (collectionType in frameCollectionTypes)
		{
			collections = cast frameCollections.get(collectionType);
			FlxDestroyUtil.destroyArray(collections);
		}
		
		frameCollections = null;
		frameCollectionTypes = null;
	}
	
	/**
	 * Forces BitmapData regeneration for all frames in this graphic object.
	 */
	public inline function resetFrameBitmaps():Void
	{
		var collections:Array<FlxFramesCollection>;
		var collection:FlxFramesCollection;
		var collectionType:FrameCollectionType;
		for (collectionType in frameCollectionTypes)
		{
			collections = cast frameCollections.get(collectionType);
			for (collection in collections)
			{
				collection.destroyBitmaps();
			}
		}
	}
	
	/**
	 * Stores specified FlxFrame collection in internal map (this helps reduce object creation).
	 * 
	 * @param	collection	frame collection to store.
	 */
	public function addFrameCollection(collection:FlxFramesCollection):Void
	{
		if (collection.type != null)
		{
			var collections:Array<Dynamic> = getFramesCollections(collection.type);
			collections.push(this);
		}
	}
	
	/**
	 * Searches frames collections of specified type for this FlxGraphic object.
	 * 
	 * @param	type	The type of frames collections to search for.
	 * @return	Array of available frames collections of specified type for this object.
	 */
	public inline function getFramesCollections(type:FrameCollectionType):Array<Dynamic>
	{
		var collections:Array<Dynamic> = frameCollections.get(type);
		if (collections == null)
		{
			collections = new Array<FlxFramesCollection>();
			frameCollections.set(type, collections);
		}
		return collections;
	}
	
	#if FLX_RENDER_TILE
	/**
	 * Tilesheet getter. Generates new one (and regenerates) if there is no tilesheet for this graphic yet.
	 */
	private function get_tilesheet():TileSheetExt
	{
		if (_tilesheet == null)
		{
			var dumped:Bool = isDumped;
			
			if (dumped)	undump();
			
			_tilesheet = new TileSheetExt(bitmap);
			
			if (dumped)	dump();
		}
		
		return _tilesheet;
	}
	#end
	
	/**
	 * Gets BitmapData for this graphic object from OpenFl.
	 * This method is used for undumping graphic.
	 */
	private function getBitmapFromSystem():BitmapData
	{
		var newBitmap:BitmapData = null;
		if (assetsClass != null)
		{
			newBitmap = FlxAssets.getBitmapFromClass(assetsClass);
		}
		else if (assetsKey != null)
		{
			newBitmap = FlxAssets.getBitmapData(assetsKey);
		}
		
		return FlxGraphic.getBitmap(newBitmap, unique);
	}
	
	private inline function get_canBeDumped():Bool
	{
		return ((assetsClass != null) || (assetsKey != null));
	}
	
	private function get_useCount():Int
	{
		return _useCount;
	}
	
	private function set_useCount(Value:Int):Int
	{
		if ((Value <= 0) && _destroyOnNoUse && !persist)
		{
			FlxG.bitmap.remove(key);
		}
		
		return _useCount = Value;
	}
	
	private function get_destroyOnNoUse():Bool
	{
		return _destroyOnNoUse;
	}
	
	private function set_destroyOnNoUse(Value:Bool):Bool
	{
		if (Value && _useCount <= 0 && key != null && !persist)
		{
			FlxG.bitmap.remove(key);
		}
		
		return _destroyOnNoUse = Value;
	}
	
	private function get_imageFrame():ImageFrame
	{
		if (_imageFrame == null)
		{
			_imageFrame = ImageFrame.fromRectangle(this, bitmap.rect);
		}
		
		return _imageFrame;
	}
}