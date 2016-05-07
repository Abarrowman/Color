package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	public class MediaLoader extends EventDispatcher {
		//url loaders
		private var urlLoaderURLs:Vector.<String>=new Vector.<String>();
		private var urlLoaders:Vector.<URLLoader>=new Vector.<URLLoader>();
		private var urlLoadersProgress:Vector.<Point>=new Vector.<Point>();
		//loaders
		private var loaderURLs:Vector.<String>=new Vector.<String>();
		private var loaders:Vector.<Loader>=new Vector.<Loader>();
		private var loadersProgress:Vector.<Point>=new Vector.<Point>();
		//progress
		public var bytesLoaded:int=0;
		public var bytesTotal:int=0;
		//are we done
		public var done:Boolean=false;
		//are we loading currently
		public var loading:Boolean=false;
		//constructor
		public function MediaLoader() {
			//isn't it exciting?
		}
		//public methods
		public function getLoader(url:String):Loader {
			if (done) {
				var index:int=loaderURLs.indexOf(url);
				if (index!=-1) {
					return loaders[index];
				} else {
					return null;
				}
			} else {
				return null;
			}
		}
		public function getLoaderBitmapData(url:String):BitmapData {
			var loader:Loader=getLoader(url);
			if (loader!=null) {
				if (loader.content is Bitmap) {
					var bitmap:Bitmap=loader.content as Bitmap;
					return bitmap.bitmapData;
				} else {
					return null;
				}
			} else {
				return null;
			}
		}

		public function getURLLoader(url:String):URLLoader {
			if (done) {
				var index:int=urlLoaderURLs.indexOf(url);
				if (index!=-1) {
					return urlLoaders[index];
				} else {
					return null;
				}
			} else {
				return null;
			}
		}

		public function addLoader(url:String):void {
			if (url!="") {
				//adds a url to be loaded
				var loader:Loader=new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,completed);
				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,progression);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,ioerror);
				loaders.push(loader);
				loadersProgress.push(new Point(0,0));
				loaderURLs.push(url);
			}
		}

		public function addLoaders(urls:Vector.<String>):void {
			//adds several urls to be loaded
			for (var n:int=0; n<urls.length; n++) {
				addLoader(urls[n]);
			}
		}

		public function addURLLoader(url:String):void {
			if (url!="") {
				//adds a url to be loaded
				var urlLoader:URLLoader=new URLLoader();
				urlLoader.dataFormat=URLLoaderDataFormat.BINARY;
				urlLoader.addEventListener(Event.COMPLETE,completed);
				urlLoader.addEventListener(ProgressEvent.PROGRESS,progression);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR,ioerror);
				urlLoaders.push(urlLoader);
				urlLoadersProgress.push(new Point(0,0));
				urlLoaderURLs.push(url);
			}
		}

		public function addURLLoaders(urls:Vector.<String>):void {
			//adds several urls to be loaded
			for (var n:int=0; n<urls.length; n++) {
				addURLLoader(urls[n]);
			}
		}
		public function load():void {
			//Are we loading something already?
			if (loading) {
				close();
			}
			//loads all the url requests
			var n:int=0;
			var urlloader:URLLoader;
			var loader:Loader;
			for (n=0; n<urlLoaders.length; n++) {
				urlLoaders[n].load(new URLRequest(urlLoaderURLs[n]));
			}
			for (n=0; n<loaders.length; n++) {
				loaders[n].load(new URLRequest(loaderURLs[n]));
			}
			loading=true;
			done=false;
		}
		public function close():void {
			for (var n:int=0; n<loaders.length; n++) {
				loaders[n].close();
			}
			for (n=0; n<urlLoaders.length; n++) {
				urlLoaders[n].close();
			}
		}
		public function clear():void {
			//resets mediaLoader
			//stop things currently loading
			close();
			//reset easy things
			urlLoaderURLs=new Vector.<String>();
			urlLoadersProgress=new Vector.<Point>();
			loaderURLs=new Vector.<String>();
			loadersProgress=new Vector.<Point>();
			bytesLoaded=0;
			bytesTotal=0;
			done=false;
			loading=false;
			//reset hard things
			for (var n:int=0; n<loaders.length; n++) {
				var loader:Loader=loaders[n];
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,completed);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS,progression);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,ioerror);
			}
			for (n=0; n<urlLoaders.length; n++) {
				var urlLoader:URLLoader=urlLoaders[n];
				urlLoader.removeEventListener(Event.COMPLETE,completed);
				urlLoader.removeEventListener(ProgressEvent.PROGRESS,progression);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR,ioerror);
			}
			loaders=new Vector.<Loader>();
			urlLoaders=new Vector.<URLLoader>();
		}
		//private methods
		private function ioerror(event:IOErrorEvent):void {
			trace(event);
			dispatchEvent(event);
			var index:int=urlLoaders.indexOf(event.target);
			if (index!=-1) {
				//URL Loaders
				urlLoaders.splice(index,1);
				urlLoaderURLs.splice(index,1);
				urlLoadersProgress.splice(index,1);
			} else {
				//Loaders
				index=loaders.indexOf(event.target);
				if (index!=-1) {
					loaders.splice(index,1);
					loaderURLs.splice(index,1);
					loadersProgress.splice(index,1);
				} else {
					//doom and gloom
				}
			}
			//are we done
			isDone();
		}
		private function progression(event:ProgressEvent):void {

			var index:int=urlLoaders.indexOf(event.target);
			if (index!=-1) {
				//URL Loaders
				if (urlLoadersProgress[index].y==0) {
					bytesTotal+=urlLoadersProgress[index].y=event.bytesTotal;
					bytesLoaded+=urlLoadersProgress[index].x=event.bytesLoaded;
				} else {
					bytesLoaded+=(event.bytesLoaded-urlLoadersProgress[index].x);
					urlLoadersProgress[index].x=event.bytesLoaded;
				}
			} else {

				index=loaders.indexOf(event.target);
				if (index!=-1) {
					//Loaders
					if (loadersProgress[index].y==0) {
						bytesTotal+=loadersProgress[index].y=event.bytesTotal;
						bytesLoaded+=loadersProgress[index].x=event.bytesLoaded;
					} else {
						bytesLoaded+=(event.bytesLoaded-loadersProgress[index].x);
						loadersProgress[index].x=event.bytesLoaded;
					}
				} else {
					//doom and gloom
				}
			}
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS,false,false,bytesLoaded,bytesTotal));
		}
		private function completed(event:Event):void {
			//Yay
			//are we done
			isDone();
		}
		private function isDone():Boolean {
			//are we done
			var doner:Boolean=true;
			for (var n:int=0; n<urlLoaders.length; n++) {
				if (urlLoaders[n].data==null) {
					doner=false;
				}
			}
			for (n=0; n<loaders.length; n++) {
				if (loaders[n].content==null) {
					doner=false;
				}
			}
			if (doner) {
				loading=false;
				done=true;
				dispatchEvent(new Event(Event.COMPLETE));
				return true;
			} else {
				return false;
			}
		}
	}
}