//setup
//imports
import flash.display.MovieClip;
import com.adobe.images.*;
import com.foxaweb.utils.Rasterizer;
import com.ctyeung.WindowsBitmap.*;
import com.ctyeung.Targa.*;
import com.ctyeung.TIFF6.*;
import tiffencoder.*;
import org.bytearray.gif.encoder.GIFEncoder;
import fl.controls.RadioButtonGroup;
import fl.controls.ColorPicker;
import fl.events.ScrollEvent;
import fl.events.SliderEvent;
import fl.events.ListEvent;


//setup variables
var lineDrawing:Boolean=false;
var startX:int=0;
var startY:int=0;
var oldx:int=0;
var oldy:int=0;
var mx:int=0;
var my:int=0;
var over:Boolean=false;

var isDoneLoading:Boolean=false;

var palletBit:Bitmap;
var palletData:BitmapData;
var mousePalletIsDown:Boolean=false;
var mousePalletIsDownInBox:Boolean=false;

var selectedColorARGB:uint=0xff000000;

var dialog:Boolean=false;
var dial:MovieClip=null;

var fr:FileReference = new FileReference();
var filename:String="image";
var oktofile:Boolean=true;
var typ:String="";

var gifEncoder:GIFEncoder=new GIFEncoder();
var jpgEncoder:JPGEncoder=new JPGEncoder(90);

var size:Point=new Point(550,400);
var data:BitmapData=new BitmapData(size.x,size.y,true,0x00ffffff);
var old:BitmapData;
var bit:Bitmap=new Bitmap(data);

var hscrollco:Number=0;
var vscrollco:Number=0;

var loader:MediaLoader=new MediaLoader();

var undos:Vector.<BitmapData>=new Vector.<BitmapData>();
var undoNames:Vector.<String>=new Vector.<String>();

var color:ColorPicker=null;

var job:PrintJob;

var spri:Sprite;

var graphicsSprite:Sprite=new Sprite();

//setup methods
gifEncoder.start();
gifEncoder.setRepeat(0);
gifEncoder.setDelay(70);

sp.y=48;
sp.x=20;
sp.addChild(bit);
sp.addChild(graphicsSprite);

hscroll.minScrollPosition=0;
hscroll.maxScrollPosition=1000;
vscroll.minScrollPosition=0;
vscroll.maxScrollPosition=1000;

stage.scaleMode=StageScaleMode.NO_SCALE;
stage.align=StageAlign.TOP_LEFT;

cursor.width=cursor.height=2*5;
cursor.mouseEnabled=false;

setupLoader();

drawCurrentColor();

function setupLoader():void {
	dialog=true;
	dial=new LoadingDialog();
	dial.prog.maximum=1;
	dial.x=(stage.stageWidth-dial.width)/2;
	dial.y=(stage.stageHeight-dial.height)/2;
	addChild(dial);
	loader.addURLLoader("onecolor.pbj");
	loader.addURLLoader("inferred.pbj");
	loader.addURLLoader("invertRGB.pbj");
	loader.addURLLoader("SaturationValuePalletByHue.pbj");
	loader.addURLLoader("pixel.pbj");
	loader.addLoader("rainbow.png");
	
	loader.addEventListener(Event.COMPLETE,doneLoading);
	loader.addEventListener(IOErrorEvent.IO_ERROR,ioerror);
	loader.addEventListener(ProgressEvent.PROGRESS,progress);
	loader.load();
}

//setup event listeners
zoom.addEventListener(Event.CHANGE, toolSettingsChange);
toolSettings.addEventListener(Event.CHANGE, toolSettingsChange);
sp.addEventListener(MouseEvent.MOUSE_MOVE,mover);
sp.addEventListener(MouseEvent.MOUSE_DOWN,downer);
stage.addEventListener(MouseEvent.MOUSE_UP,upper);
stage.addEventListener(Event.RESIZE, resizeApplication);
newer.addEventListener(MouseEvent.CLICK,renews);
opener.addEventListener(MouseEvent.CLICK,opens);
compiler.addEventListener(MouseEvent.CLICK, compiles);
zoom.addEventListener(Event.CHANGE,changezoom);
hscroll.addEventListener(ScrollEvent.SCROLL,scroll);
vscroll.addEventListener(ScrollEvent.SCROLL,scroll);
filtering.addEventListener(MouseEvent.CLICK,filterimage);
changes.addEventListener(MouseEvent.CLICK,undoimage);
undo.addEventListener(MouseEvent.CLICK, lastUndo);
printere.addEventListener(MouseEvent.CLICK, printimage);
tool.addEventListener(Event.CHANGE, changeTool);
palletPreview.addEventListener(MouseEvent.CLICK,createColorPalletDialog);


//*
//Undoing
//*
function storeimage(chng:String='Change'):void {
	//var saved:BitmapData=new BitmapData(size.x,size.y,true,0x00ffffff);
	//saved.copyPixels(data, new Rectangle(0,0,size.x,size.y), new Point());
	var saved:BitmapData=data.clone();
	undos.push(saved);
	undoNames.push(chng);
}

function undoimage(event:MouseEvent):void {
	if (! dialog) {
		if (undos.length>=1) {
			//make a dialog
			dialog=true;
			var dia=new UndoDialog();
			dia.x=(stage.stageWidth-dia.width)/2;
			dia.y=(stage.stageHeight-dia.height)/2;
			dia.rest.addEventListener(MouseEvent.CLICK,undoer);
			dia.cancel.addEventListener(MouseEvent.CLICK,cancelundo);
			addChild(dia);
			//
			for (var n:int=undos.length-1; n>=0; n--) {
				dia.typ.addItem( { label: undoNames[n], data:undoNames[n]+"-"+n } );
			}
			dia.typ.addEventListener(ListEvent.ITEM_ROLL_OVER, previewundo);
			dia.typ.addEventListener(Event.CHANGE, choseundo);
			dia.typ.addEventListener(Event.CLOSE, choseundo);
			preundo(dia, undos.length-1);
		}
	}
}

function lastUndo(event:MouseEvent):void {
	if (undos.length>0) {
		storeimage('Undone');
		var saved:BitmapData=undos[undos.length-2];
		
		//data=new BitmapData(saved.width,saved.height,true,0x00ffffff);
		//data.copyPixels(saved, new Rectangle(0,0,saved.width,saved.height), new Point());
		data=saved.clone();
		
		bit.bitmapData=data;
		
		size.x=data.width;
		size.y=data.height;
		
		changezoom();
	}
}

function undoer(event:MouseEvent):void {
	var val:String=event.target.parent.typ.value;
	val=val.substr(val.indexOf('-')+1);
	var index:int=parseInt(val);
	if (! isNaN(index)) {
		storeimage('Undone');
		var saved:BitmapData=undos[index];
		
		//data=new BitmapData(saved.width,saved.height,true,0x00ffffff);
		//data.copyPixels(saved, new Rectangle(0,0,saved.width,saved.height), new Point());
		data=saved.clone();
		
		bit.bitmapData=data;
		
		size.x=data.width;
		size.y=data.height;
		
		changezoom();
	}
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function preundo(dia:*, index:int):void {
	var saved:BitmapData=undos[index];
	if (dia.bit!=null) {
		dia.removeChild(dia.bit);
	}
	dia.bit=new Bitmap(saved.clone());
	dia.addChild(dia.bit);
	if (dia.bit.width>dia.bit.height) {
		dia.bit.scaleX=dia.bit.scaleY=100/dia.bit.width;
	} else {
		dia.bit.scaleX=dia.bit.scaleY=100/dia.bit.height;
	}
	dia.bit.x=dia.bord.x;
	dia.bit.y=dia.bord.y;
	dia.bord.width=dia.bit.width;
	dia.bord.height=dia.bit.height;
}

function previewundo(event:ListEvent):void {
	var index:int=int(event.rowIndex);
	index=(undos.length-1)-index;
	preundo(event.target.parent, index);
}

function choseundo(event:Event):void {
	var index:int=int(event.target.selectedIndex);
	index=(undos.length-1)-index;
	preundo(event.target.parent, index);
}

function cancelundo(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelundo);
	event.target.parent.rest.removeEventListener(MouseEvent.CLICK,undoer);
	dialog=false;
	event.target.parent.parent.removeChild(event.target.parent);
}

//*
//Filters
//*

function createColorPalletDialog(event:MouseEvent):void{
	if (! dialog) {
		dial=new ColorPalletDialog();
		dial.x=stage.stageWidth/2;
		dial.y=stage.stageHeight/2;
		palletData=new BitmapData(257,257);
		palletBit=new Bitmap(palletData);
		palletBit.x=dial.palletBorder.x-palletBit.width/2;
		palletBit.y=dial.palletBorder.y-palletBit.height/2;
		dial.below.addChild(palletBit);
		dial.palletBorder.mouseEnabled=false;
		
		dial.hueSlider.addEventListener(SliderEvent.CHANGE, hueChanged);
		dial.satSlider.addEventListener(SliderEvent.CHANGE, satChanged);
		dial.valSlider.addEventListener(SliderEvent.CHANGE, valChanged);
		dial.redSlider.addEventListener(SliderEvent.CHANGE, colorChannelChanged);
		dial.greenSlider.addEventListener(SliderEvent.CHANGE, colorChannelChanged);
		dial.blueSlider.addEventListener(SliderEvent.CHANGE, colorChannelChanged);
		dial.alphaSlider.addEventListener(SliderEvent.CHANGE, colorChannelChanged);
		dial.hexValue.addEventListener(Event.CHANGE, hexChanged);
		dial.hueValue.addEventListener(Event.CHANGE, hueValueChanged);
		dial.satValue.addEventListener(Event.CHANGE, satValueChanged);
		dial.valValue.addEventListener(Event.CHANGE, valValueChanged);
		dial.redValue.addEventListener(Event.CHANGE, channelValueChanged);
		dial.greenValue.addEventListener(Event.CHANGE, channelValueChanged);
		dial.blueValue.addEventListener(Event.CHANGE, channelValueChanged);
		dial.alphaValue.addEventListener(Event.CHANGE, channelValueChanged);
		dial.cancel.addEventListener(MouseEvent.CLICK, cancelSetPallet);
		dial.ok.addEventListener(MouseEvent.CLICK, setPallet);
	
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mousePalletButtonDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, mousePalletButtonUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, movePalletMouse);
	
		addChild(dial);
	
		dialog=true;
	
		setPalletColor(selectedColorARGB>>24&0xff,selectedColorARGB>>16&0xff,selectedColorARGB>>8&0xff,selectedColorARGB&0xff);
	}
}

function setPallet(event:MouseEvent):void{
	selectedColorARGB=parseInt(dial.hexValue.text,16);
	drawCurrentColor();
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cancelSetPallet(event:MouseEvent):void{
	dial.hueSlider.removeEventListener(SliderEvent.CHANGE, hueChanged);
	dial.satSlider.removeEventListener(SliderEvent.CHANGE, satChanged);
	dial.valSlider.removeEventListener(SliderEvent.CHANGE, valChanged);
	dial.redSlider.removeEventListener(SliderEvent.CHANGE, colorChannelChanged);
	dial.greenSlider.removeEventListener(SliderEvent.CHANGE, colorChannelChanged);
	dial.blueSlider.removeEventListener(SliderEvent.CHANGE, colorChannelChanged);
	dial.alphaSlider.removeEventListener(SliderEvent.CHANGE, colorChannelChanged);
	dial.hexValue.removeEventListener(Event.CHANGE, hexChanged);
	dial.hueValue.removeEventListener(Event.CHANGE, hueValueChanged);
	dial.satValue.removeEventListener(Event.CHANGE, satValueChanged);
	dial.valValue.removeEventListener(Event.CHANGE, valValueChanged);
	dial.redValue.removeEventListener(Event.CHANGE, channelValueChanged);
	dial.greenValue.removeEventListener(Event.CHANGE, channelValueChanged);
	dial.blueValue.removeEventListener(Event.CHANGE, channelValueChanged);
	dial.alphaValue.removeEventListener(Event.CHANGE, channelValueChanged);
	dial.cancel.removeEventListener(MouseEvent.CLICK, cancelSetPallet);
	dial.ok.removeEventListener(MouseEvent.CLICK, setPallet);
	
	stage.removeEventListener(MouseEvent.MOUSE_DOWN, mousePalletButtonDown);
	stage.removeEventListener(MouseEvent.MOUSE_UP, mousePalletButtonUp);
	stage.removeEventListener(MouseEvent.MOUSE_MOVE, movePalletMouse);

	removeChild(dial);
	
	dialog=false;
}

function hueValueChanged(event:Event):void{
	dial.hueSlider.value=parseTextInt(dial.hueValue.text);
	hueChanged(null);
}

function hueChanged(event:SliderEvent):void{
	reDrawPallet(dial.hueSlider.value);
}

function satValueChanged(event:Event):void{
	dial.satSlider.value=parseTextInt(dial.satValue.text);
	satChanged(null);
}

function satChanged(event:SliderEvent):void{
	dial.selector.x=palletBit.x+dial.satSlider.value+1;
	calculateColor(false);
}

function valValueChanged(event:Event):void{
	dial.valSlider.value=parseTextInt(dial.valValue.text);
	valChanged(null);
}

function valChanged(event:SliderEvent):void{
	dial.selector.y=palletBit.y+256-dial.valSlider.value;
	calculateColor(false);
}

function hexChanged(event:Event):void{
	var color:uint=parseInt(dial.hexValue.text,16);
	var alp:Number=color>>24&0xff;
	var red:Number=color>>16&0xff;
	var green:Number=color>>8&0xff;
	var blue:Number=color&0xff;
	dial.alphaSlider.value=alp;
	dial.redSlider.value=red;
	dial.greenSlider.value=green;
	dial.blueSlider.value=blue;
	colorChannelChanged(null);
}

function channelValueChanged(event:Event):void{
	dial.redSlider.value=parseTextInt(dial.redValue.text);
	dial.greenSlider.value=parseTextInt(dial.greenValue.text);
	dial.blueSlider.value=parseTextInt(dial.blueValue.text);
	dial.alphaSlider.value=parseTextInt(dial.alphaValue.text);
	colorChannelChanged(new SliderEvent(SliderEvent.CHANGE,4,"cow","blue"));
}

function colorChannelChanged(event:SliderEvent):void{
	var alp:Number=dial.alphaSlider.value;
	var red:Number=dial.redSlider.value;
	var green:Number=dial.greenSlider.value;
	var blue:Number=dial.blueSlider.value;
	setPalletColor(alp,red,green,blue,event!=null);
}

//255,128,64,64
function setPalletColor(alp:Number,red:Number,green:Number,blue:Number,reHex:Boolean=true):void{
	var hsv:Vector3D=RGBToHSV(red,green,blue);
	var hue:Number=hsv.x;
	var saturation:Number=hsv.y;
	var value:Number=hsv.z;
	
	palletBit.alpha=alp/255;
	
	dial.hueSlider.value=hue*255;
	dial.satSlider.value=saturation*255;
	dial.valSlider.value=value;
	dial.redSlider.value=red;
	dial.blueSlider.value=blue;
	dial.greenSlider.value=green;
	dial.alphaSlider.value=alp;
	
	dial.hueValue.text=dial.hueSlider.value.toString(10);
	dial.satValue.text=dial.satSlider.value.toString(10);
	dial.valValue.text=dial.valSlider.value.toString(10);
	dial.redValue.text=dial.redSlider.value.toString(10);
	dial.greenValue.text=dial.greenSlider.value.toString(10);
	dial.blueValue.text=dial.blueSlider.value.toString(10);
	dial.alphaValue.text=dial.alphaSlider.value.toString(10);
	
	purePalletReDraw(dial.hueSlider.value);
	dial.selector.x=palletBit.x+(255*saturation)+1;
	dial.selector.y=palletBit.y+256-value;
	if(reHex){
		dial.hexValue.text=RGBAToHex(alp, red, green, blue);
	}
	drawPalletPreview();
}

function reDrawPallet(hue:int):void{
	if(isDoneLoading){
		purePalletReDraw(hue);
		calculateColor();
	}
}

function parseTextInt(str:String):int{
	var ine:int=parseInt(str,10);
	if(isNaN(ine)){
		return 0;
	}else{
		return ine;
	}
}

function purePalletReDraw(hue:int):void{
	var h:Number=hue/255;
	var huePalletShader:Shader = new Shader(loader.getURLLoader("SaturationValuePalletByHue.pbj").data);
	huePalletShader.data.hue.value=[h];
	palletData.lock();
	palletData.applyFilter(palletData,new Rectangle(0,0,palletData.width,palletData.height),new Point(),new ShaderFilter(huePalletShader));
	palletData.unlock();
}

function movePalletMouse(event:MouseEvent):void{
	if(mousePalletIsDownInBox){
		dial.selector.x=event.stageX-dial.x;
		dial.selector.y=event.stageY-dial.y;
		if(dial.selector.x<(dial.palletBorder.x-dial.palletBorder.width/2)){
			dial.selector.x=dial.palletBorder.x-dial.palletBorder.width/2;
		}else if(dial.selector.x>(dial.palletBorder.x+dial.palletBorder.width/2)){
			dial.selector.x=dial.palletBorder.x+dial.palletBorder.width/2;
		}
		if(dial.selector.y<(dial.palletBorder.y-dial.palletBorder.height/2)){
			dial.selector.y=dial.palletBorder.y-dial.palletBorder.height/2;
		}else if(dial.selector.y>(dial.palletBorder.y+dial.palletBorder.height/2)){
			dial.selector.y=dial.palletBorder.y+dial.palletBorder.height/2;
		}
		calculateColor();
	}
}

function mousePalletButtonDown(event:MouseEvent):void{
	var evx:int=event.stageX-dial.x;
	var evy:int=event.stageY-dial.y;
	if(evx>=(dial.palletBorder.x-dial.palletBorder.width/2)&&evx<=(dial.palletBorder.x+dial.palletBorder.width/2)&&evy>=(dial.palletBorder.y-dial.palletBorder.height/2)&&evy<=(dial.palletBorder.y+dial.palletBorder.height/2)){
		mousePalletIsDownInBox=true;
		movePalletMouse(event);
	}
	mousePalletIsDown=true;
}

function mousePalletButtonUp(event:MouseEvent):void{
	mousePalletIsDownInBox=false;
	mousePalletIsDown=false;
}

function calculateColor(reCalcSV:Boolean=true):void{
	var color:uint=getCurrentColor();
	var alp:Number=Math.round(palletBit.alpha*255);
	var red:Number=color>>16&0xff;
	var green:Number=color>>8&0xff;
	var blue:Number=color&0xff;
	var hsv:Vector3D=RGBToHSV(red,green,blue);
	var hue:Number=hsv.x;
	var saturation:Number;
	var value:Number;
	if(reCalcSV){
		saturation=hsv.y;
		value=hsv.z;
	}else{
		saturation=(dial.selector.x-1-palletBit.x)/255;
		value=palletBit.y+256-dial.selector.y;
	}
	
	dial.satSlider.value=saturation*255;
	dial.valSlider.value=value;
	dial.redSlider.value=red;
	dial.greenSlider.value=green;
	dial.blueSlider.value=blue;
	dial.alphaSlider.value=alp;
	
	dial.hueValue.text=dial.hueSlider.value.toString(10);
	dial.satValue.text=dial.satSlider.value.toString(10);
	dial.valValue.text=dial.valSlider.value.toString(10);
	dial.redValue.text=dial.redSlider.value.toString(10);
	dial.greenValue.text=dial.greenSlider.value.toString(10);
	dial.blueValue.text=dial.blueSlider.value.toString(10);
	dial.alphaValue.text=dial.alphaSlider.value.toString(10);
	
	
	dial.hexValue.text=RGBAToHex(alp, red, green, blue);
	
	drawPalletPreview();
}

function getCurrentColor():uint{
	var localX:int=Math.round(dial.selector.x-palletBit.x);
	var localY:int=Math.round(dial.selector.y-palletBit.y-1);
	if(localX<0){
		localX=0;
	}else if(localX>=palletData.width){
		localX=palletData.width-1;
	}
	if(localY<0){
		localY=0;
	}else if(localY>=palletData.height){
		localY=palletData.height-1;
	}
	return palletData.getPixel(localX,localY);
	
}

function drawPalletPreview():void{
	var color:uint=getCurrentColor();
	dial.below.graphics.clear();
	dial.below.graphics.beginFill(color,palletBit.alpha);
	dial.below.graphics.drawRect(dial.colorPreviewBorder.x-0.5,dial.colorPreviewBorder.y,dial.colorPreviewBorder.width,dial.colorPreviewBorder.height);
}

function RGBAToHex(a:int, r:int, g:int, b:int):String{
	return channelToHex(a)+channelToHex(r)+channelToHex(g)+channelToHex(b);
}

function channelToHex(c:int,digits:int=2):String{
	var s:String=c.toString(16);
	while(s.length<digits){
		s="0"+s;
	}
	return s;
}

function RGBToHSV(r:Number, g:Number, b:Number):Vector3D {
	var h:Number=0;
	var s:Number=0;
	var v:Number=0;

	var min:Number=Math.min(r,g,b);
	var max:Number=Math.max(r,g,b);

	v=max;

	var delta:Number=max-min;

	if (max!=0) {
		s=delta/max;
	} else {
		s=0;
		h=-1;
	}

	if (r==max) {
		// between yellow & magenta
		h = ( g - b ) / delta;
	} else if ( g == max ) {
		// between cyan & yellow
		h = 2 + ( b - r ) / delta;
	} else {
		// between magenta & cyan
		h = 4 + ( r - g ) / delta;
	}

	h*=60;
	if (h<0) {
		h+=360;
	}
	h/=360;

	if (isNaN(h)) {
		h=0;
	}
	return new Vector3D(h,s,v);
}

function convolutionfilter(event:MouseEvent):void {
	storeimage('Convolution');
	var mat=new Array();
	mat=new Array(event.target.parent.tl.value,event.target.parent.tc.value,event.target.parent.tr.value,
	  event.target.parent.cl.value,event.target.parent.cc.value,event.target.parent.cr.value,
	  event.target.parent.bl.value,event.target.parent.bc.value,event.target.parent.br.value);
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new ConvolutionFilter(3,3,mat));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cancelconvfilter(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelconvfilter);
	event.target.parent.ok.removeEventListener(MouseEvent.CLICK,convolutionfilter);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

//color matrix filter
function colormatfilter(event:MouseEvent):void {
	storeimage('Color Matrix');
	var mat:Array = new Array();
	mat=mat.concat([event.target.parent.rr.value,event.target.parent.rg.value,event.target.parent.rb.value,event.target.parent.ra.value,event.target.parent.ryt.value]);// red
	mat=mat.concat([event.target.parent.gr.value,event.target.parent.gg.value,event.target.parent.gb.value,event.target.parent.ga.value,event.target.parent.gyt.value]);// green
	mat=mat.concat([event.target.parent.br.value,event.target.parent.bg.value,event.target.parent.bb.value,event.target.parent.ba.value,event.target.parent.byt.value]);// blue
	mat=mat.concat([event.target.parent.ar.value,event.target.parent.ag.value,event.target.parent.ab.value,event.target.parent.aa.value,event.target.parent.ayt.value]);// alpha

	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new ColorMatrixFilter(mat));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cancelcolormatfilter(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelcolormatfilter);
	event.target.parent.ok.removeEventListener(MouseEvent.CLICK,colormatfilter);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

//flip filter
function flipfilter(event:MouseEvent):void {
	storeimage('Flip');
	var dat:BitmapData=new BitmapData(data.width,data.height,true,0x00000000);
	var n:int;
	var en:int;
	if (RadioButtonGroup.getGroup("grom").selection==event.target.parent.hor) {
		for (n=0; n<dat.width; n++) {
			for (en=0; en<dat.height; en++) {
				dat.setPixel32(dat.width-n-1,en,data.getPixel32(n,en));
			}
		}
	} else {
		for (n=0; n<dat.width; n++) {
			for (en=0; en<dat.height; en++) {
				dat.setPixel32(n,dat.height-en-1,data.getPixel32(n,en));
			}
		}
	}
	//make a new BitmapData of the right size
	size=new Point(Math.min(dat.width,2880),Math.min(dat.height,2880));
	data=new BitmapData(size.x,size.y,true,0x00ffffff);
	//house keeping
	bit.bitmapData=data;
	data.draw(dat);
	oktofile=true;
	changezoom();
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cancelflipfilter(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelflipfilter);
	event.target.parent.ok.removeEventListener(MouseEvent.CLICK,flipfilter);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

//crop filter
function cropfilter(event:MouseEvent):void {
	storeimage('Crop');
	var start:Point=new Point(Math.floor(event.target.parent.holder.start.x*data.width),Math.floor(event.target.parent.holder.start.y*data.height));
	var end:Point=new Point(Math.floor(event.target.parent.holder.end.x*data.width),Math.floor(event.target.parent.holder.end.y*data.height));
	var rect:Rectangle=new Rectangle();
	rect.width=Math.abs(start.x-end.x);
	rect.height=Math.abs(start.y-end.y);
	if (start.x<end.x) {
		rect.x=start.x;
	} else {
		rect.x=end.x;
	}
	if (start.y<end.y) {
		rect.y=start.y;
	} else {
		rect.y=end.y;
	}
	
	var dat:BitmapData=new BitmapData(rect.width,rect.height,true,0x00000000);
	dat.copyPixels(data,rect,new Point());
	
	//make a new BitmapData of the right size
	size=new Point(Math.min(dat.width,2880),Math.min(dat.height,2880));
	data=new BitmapData(size.x,size.y,true,0x00ffffff);
	//house keeping
	bit.bitmapData=data;
	data.draw(dat);
	oktofile=true;
	changezoom();

	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));

}

function cropstart(event:MouseEvent):void {
	event.target.cropping=true;
	event.target.start=new Point(event.localX/event.target.width*event.target.scaleX,event.localY/event.target.height*event.target.scaleY);
	event.target.parent.borde.x=event.target.x+event.target.start.x*event.target.width;
	event.target.parent.borde.y=event.target.y+event.target.start.y*event.target.height;
	event.target.parent.borde.scaleX=event.target.parent.borde.scaleY=0;

}
function cropping(event:MouseEvent):void {
	if (event.target.cropping) {
		var spote:Point=new Point(event.localX/event.target.width*event.target.scaleX,event.localY/event.target.height*event.target.scaleY);
		event.target.parent.borde.scaleX=(event.target.x+spote.x*event.target.width-event.target.parent.borde.x)/200;
		event.target.parent.borde.scaleY=(event.target.y+spote.y*event.target.height-event.target.parent.borde.y)/200;
	}
}
function cropend(event:MouseEvent):void {
	//event.target=dia.holder
	event.target.cropping=false;
	event.target.end=new Point(event.localX/event.target.width*event.target.scaleX,event.localY/event.target.height*event.target.scaleY);
}

function cancelcropfilter(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelcropfilter);
	event.target.parent.ok.removeEventListener(MouseEvent.CLICK,cropfilter);
	event.target.parent.holder.removeEventListener(MouseEvent.MOUSE_DOWN, cropstart);
	event.target.parent.holder.removeEventListener(MouseEvent.MOUSE_MOVE, cropping);
	event.target.parent.holder.removeEventListener(MouseEvent.MOUSE_UP, cropend);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}


//applies filters
function filterimage(event:MouseEvent):void {
	if (! dialog) {
		dialog=true;
		var dia=new FilterDialog();
		dia.x=(stage.stageWidth-dia.width)/2;
		dia.y=(stage.stageHeight-dia.height)/2;
		dia.inv.addEventListener(MouseEvent.CLICK,invertfilter);
		dia.infr.addEventListener(MouseEvent.CLICK,inferredfilter);
		dia.blr.addEventListener(MouseEvent.CLICK,blurfilter);
		dia.cust.addEventListener(MouseEvent.CLICK,convfilter);
		dia.pix.addEventListener(MouseEvent.CLICK,pixelfilter);
		dia.shad.addEventListener(MouseEvent.CLICK,shadowfilter);
		dia.matri.addEventListener(MouseEvent.CLICK, cmatrixfilter);
		dia.cro.addEventListener(MouseEvent.CLICK, crofilter);
		dia.fli.addEventListener(MouseEvent.CLICK, flifilter);
		dia.cancel.addEventListener(MouseEvent.CLICK,cancelfilter);
		addChild(dia);
	}
}

function shadowfilter(event:MouseEvent):void {
	storeimage('Shadow');
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new DropShadowFilter(4.0, 45, 0, 1.0, 10.0, 10.0, 1.0, 3));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function pixelfilter(event:MouseEvent):void {
	storeimage('Pixel');
	var shad:Shader=new Shader(loader.getURLLoader("pixel.pbj").data);
	shad.data.pixelsize.value=[10];
	var shadf:ShaderFilter=new ShaderFilter(shad);
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),shadf);
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cmatrixfilter(event:MouseEvent):void {
	var dia=new ColorMatrixDialog();
	dia.x=(stage.stageWidth-dia.width)/2;
	dia.y=(stage.stageHeight-dia.height)/2;
	dia.ok.addEventListener(MouseEvent.CLICK,colormatfilter);
	dia.cancel.addEventListener(MouseEvent.CLICK,cancelcolormatfilter);
	addChild(dia);
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	dialog=true;
}

function crofilter(event:MouseEvent):void {
	var dia=new CropDialog();
	dia.x=(stage.stageWidth-dia.width)/2;
	dia.y=(stage.stageHeight-dia.height)/2;
	var btc:BitmapData=data.clone();
	dia.holder.addChild(new Bitmap(btc));
	if (btc.width>btc.height) {
		dia.holder.scaleX=dia.holder.scaleY=200/btc.width;
	} else {
		dia.holder.scaleX=dia.holder.scaleY=200/btc.height;
	}
	dia.borde.mouseEnabled=false;
	dia.borde.width=dia.bord.width=dia.holder.width;
	dia.borde.height=dia.bord.height=dia.holder.height;
	dia.holder.addEventListener(MouseEvent.MOUSE_DOWN, cropstart);
	dia.holder.addEventListener(MouseEvent.MOUSE_MOVE, cropping);
	dia.holder.addEventListener(MouseEvent.MOUSE_UP, cropend);
	dia.holder.start=new Point(0,0);
	dia.holder.end=new Point(1,1);
	dia.holder.x=dia.bord.x=dia.borde.x=(265-dia.holder.width)/2;
	dia.cropping=false;
	dia.ok.addEventListener(MouseEvent.CLICK,cropfilter);
	dia.cancel.addEventListener(MouseEvent.CLICK,cancelcropfilter);
	addChild(dia);
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	dialog=true;
}

function flifilter(event:MouseEvent):void {
	var dia=new FlipDialog();
	dia.x=(stage.stageWidth-dia.width)/2;
	dia.y=(stage.stageHeight-dia.height)/2;
	dia.ok.addEventListener(MouseEvent.CLICK,flipfilter);
	dia.cancel.addEventListener(MouseEvent.CLICK,cancelflipfilter);
	addChild(dia);
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	dialog=true;
}

function convfilter(event:MouseEvent):void {
	var dia=new ConvolutionDialog();
	dia.x=(stage.stageWidth-dia.width)/2;
	dia.y=(stage.stageHeight-dia.height)/2;
	dia.ok.addEventListener(MouseEvent.CLICK,convolutionfilter);
	dia.cancel.addEventListener(MouseEvent.CLICK,cancelconvfilter);
	addChild(dia);
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	dialog=true;
}

function invertfilter(event:MouseEvent):void {
	storeimage('Invert');
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new ShaderFilter(new Shader(loader.getURLLoader("invertRGB.pbj").data)));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function blurfilter(event:MouseEvent):void {
	storeimage('Blur');
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new BlurFilter(10, 10, 3));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function inferredfilter(event:MouseEvent):void {
	storeimage('Inferred');
	data.applyFilter(data,new Rectangle(0,0,data.width,data.height),new Point(),new ShaderFilter(new Shader(loader.getURLLoader("inferred.pbj").data)));
	//house keeping
	event.target.parent.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

function cancelfilter(event:MouseEvent):void {
	event.target.parent.inv.removeEventListener(MouseEvent.CLICK,invertfilter);
	event.target.parent.infr.removeEventListener(MouseEvent.CLICK,inferredfilter);
	event.target.parent.blr.removeEventListener(MouseEvent.CLICK,blurfilter);
	event.target.parent.cust.removeEventListener(MouseEvent.CLICK,convfilter);
	event.target.parent.pix.removeEventListener(MouseEvent.CLICK,pixelfilter);
	event.target.parent.shad.removeEventListener(MouseEvent.CLICK,shadowfilter);
	event.target.parent.matri.removeEventListener(MouseEvent.CLICK, cmatrixfilter);
	event.target.parent.cro.removeEventListener(MouseEvent.CLICK, crofilter);
	event.target.parent.fli.removeEventListener(MouseEvent.CLICK, flifilter);
	event.target.removeEventListener(MouseEvent.CLICK,cancelfilter);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

//changes view
function scroll(...rest):void {
	background.x=sp.x=20+Math.round((hscroll.scrollPosition/hscroll.maxScrollPosition)*hscrollco/(zoom.value/100))*(zoom.value/100);
	background.y=sp.y=48+Math.round((vscroll.scrollPosition/vscroll.maxScrollPosition)*vscrollco/(zoom.value/100))*(zoom.value/100);
	if (borders.width==border.width) {
		borders.x=20;
	} else {
		borders.x=background.x;
	}
	if (borders.height==border.height) {
		borders.y=48;
	} else {
		borders.y=background.y;
	}
	background.back.x=Math.round((background.masky.width-background.back.width)*(hscroll.scrollPosition/hscroll.maxScrollPosition)/(zoom.value/100))*(zoom.value/100);
	background.back.y=Math.round((background.masky.height-background.back.height)*(vscroll.scrollPosition/vscroll.maxScrollPosition)/(zoom.value/100))*(zoom.value/100);
}

function changezoom(...rest):void {
	sp.scaleY=sp.scaleX=zoom.value/100;
	borders.width=Math.min(sp.width,border.width);
	borders.height=Math.min(sp.height,border.height);
	background.masky.width=sp.width;
	background.masky.height=sp.height;
	hscrollco=border.width-size.x*zoom.value/100;
	vscrollco=border.height-size.y*zoom.value/100;
	scroll();
	toolSettingsChange();
}

function resizeApplication(event:Event):void {
	border.width=hscroll.width=masker.width=Math.max(550,stage.stageWidth-55);
	border.height=vscroll.height=masker.height=Math.max(400,stage.stageHeight-68);
	background.back.graphics.clear();
	for (var xn:int=0; xn<border.width; xn+=10) {
		for (var yn:int=0; yn<border.height; yn+=10) {
			if ((xn/10+yn/10)%2==0) {
				background.back.graphics.beginFill(0xcccccc);
			} else {
				background.back.graphics.beginFill(0x999999);
			}
			background.back.graphics.drawRect(xn, yn, 10, 10);
			background.back.graphics.endFill();
		}
	}
	hscroll.y=vscroll.height+48;
	vscroll.x=hscroll.width+20;
	changezoom();
}

//drawing
function upper(event:MouseEvent):void {
	over=false;
	if(old!=null){
		//bit.bitmapData.copyPixels(old, new Rectangle(0,0,size.x,size.y), new Point());
		data=bit.bitmapData=old.clone();
		old=null;
	}
	if (tool.value=="line"||tool.value=="rectangle"||tool.value=="oval") {
		if (lineDrawing) {
			var po:Point=new Point(event.stageX,event.stageY);
			po=sp.globalToLocal(po);
			mx=po.x;
			my=po.y;
			graphicsSprite.graphics.clear();
			if (tool.value=="line") {
				storeimage('Line');
				Rasterizer.thickline(data,startX, startY, mx ,my, selectedColorARGB, toolSettings.sizer.value);
			} else if (tool.value=="rectangle") {
				storeimage('Rectangle');
				Rasterizer.thickline(data,startX, startY, mx, startY, selectedColorARGB, toolSettings.sizer.value);
				Rasterizer.thickline(data,mx, startY, mx, my, selectedColorARGB, toolSettings.sizer.value);
				Rasterizer.thickline(data,mx, my, startX, my, selectedColorARGB, toolSettings.sizer.value);
				Rasterizer.thickline(data,startX, my, startX, startY, selectedColorARGB, toolSettings.sizer.value);
				if (toolSettings.fillShape.selected) {
					data.fillRect(new Rectangle(Math.min(mx, startX), Math.min(my, startY), Math.abs(mx-startX), Math.abs(my-startY)), selectedColorARGB);
				}
			}/* else if (tool.value=="oval") {
				storeimage('Oval');
				//render the graphics
				var lineWidth:int=1;
				if (toolSettings.sizer.value!=1) {
					lineWidth=2*toolSettings.sizer.value;
				}
				graphicsSprite.graphics.lineStyle(lineWidth, color.selectedColor, trance.value/255, true);
				var circWidth:int=Math.abs(mx-startX);
				var circHeight:int=Math.abs(my-startY);
				if (toolSettings.fillShape.selected) {
					graphicsSprite.graphics.beginFill(color.selectedColor, trance.value/255);
				}
				graphicsSprite.graphics.drawEllipse(Math.min(mx, startX), Math.min(my, startY), circWidth, circHeight);
				if (toolSettings.fillShape.selected) {
					graphicsSprite.graphics.endFill();
				}
				//draw the graphics
				var linecolor:uint=parseInt("0x"+color.hexValue,16);
				var shad:Shader=new Shader(loader.getURLLoader("onecolor.pbj").data);
				shad.data.color.value=[linecolor>>16&0xff/255,linecolor>>8&0xff/255,linecolor&0xff/255,trance.value/255];
				var shadf:ShaderFilter=new ShaderFilter(shad);
				graphicsSprite.filters=[shadf];
				//graphicsSprite.filters=[new BlurFilter()];
				data.draw(graphicsSprite);
				//clear up
				graphicsSprite.graphics.clear();
				graphicsSprite.filters=[];
			}*/
			lineDrawing=false;
		}
	}
}
function downer(event:MouseEvent):void {
	if (! dialog) {
		over=true;
		mx=event.localX;
		my=event.localY;
		if (tool.value=="brush") {
			storeimage('Brush');
			Rasterizer.thickline(data,oldx,oldy,mx,my,selectedColorARGB, toolSettings.sizer.value);
		} else if (tool.value=="fill") {
			storeimage('Fill');
			fillBitmapData(data, mx, my, selectedColorARGB, toolSettings.senstivity.maximum-toolSettings.senstivity.value);
			//data.floodFill(mx,my,parseInt("0x"+trance.value.toString(16)+color.hexValue,16));
		} else if (tool.value=="picker") {
			selectedColorARGB=data.getPixel32(mx,my);
			drawCurrentColor();
		} else if (tool.value=="line"||tool.value=="rectangle"||tool.value=="oval") {
			//old=new BitmapData(size.x,size.y,true,0x00ffffff);
			//old.copyPixels(data, new Rectangle(0,0,size.x,size.y), new Point());
			old=data.clone();
			
			startX=mx;
			startY=my;
			lineDrawing=true;
		}
		oldx=event.localX;
		oldy=event.localY;
	}
}

function mover(event:MouseEvent):void {
	if (! dialog) {
		mx=event.localX;
		my=event.localY;
		if (over) {
			
			if (tool.value=="brush") {
				//render
				Rasterizer.thickline(data,oldx,oldy,mx,my,selectedColorARGB,toolSettings.sizer.value);
			} else if (tool.value=="line"||tool.value=="rectangle"||tool.value=="oval") {
				//preview
				//setup canvas
				if(old!=null){
					//data=new BitmapData(size.x,size.y,true,0x00ffffff);
					//data.copyPixels(old, new Rectangle(0,0,size.x,size.y), new Point());
					//bit.bitmapData.copyPixels(old, new Rectangle(0,0,size.x,size.y), new Point());
					data=bit.bitmapData=old.clone();
					//bit.bitmapData=data;
				}
				
				//draw
				
				if (tool.value=="line") {
					Rasterizer.thickline(data,startX, startY, mx ,my, selectedColorARGB, toolSettings.sizer.value);
				} else if (tool.value=="rectangle") {
					Rasterizer.thickline(data,startX, startY, mx, startY, selectedColorARGB, toolSettings.sizer.value);
					Rasterizer.thickline(data,mx, startY, mx, my, selectedColorARGB, toolSettings.sizer.value);
					Rasterizer.thickline(data,mx, my, startX, my, selectedColorARGB, toolSettings.sizer.value);
					Rasterizer.thickline(data,startX, my, startX, startY, selectedColorARGB, toolSettings.sizer.value);
					if (toolSettings.fillShape.selected) {
						data.fillRect(new Rectangle(Math.min(mx, startX), Math.min(my, startY), Math.abs(mx-startX), Math.abs(my-startY)), selectedColorARGB);
					}
				}/* else if (tool.value=="oval") {
					//render the graphics
					var lineWidth:int=1;
					if (toolSettings.sizer.value!=1) {
						lineWidth=2*toolSettings.sizer.value;
					}
					trace(color.selectedColor);
					graphicsSprite.graphics.lineStyle(lineWidth, color.selectedColor, trance.value/255, true);
					var circWidth:int=Math.abs(mx-startX);
					var circHeight:int=Math.abs(my-startY);
					if (toolSettings.fillShape.selected) {
						graphicsSprite.graphics.beginFill(color.selectedColor, trance.value/255);
					}
					graphicsSprite.graphics.drawEllipse(Math.min(mx, startX), Math.min(my, startY), circWidth, circHeight);
					if (toolSettings.fillShape.selected) {
						graphicsSprite.graphics.endFill();
					}
					//draw the graphics
					var linecolor:uint=parseInt("0x"+color.hexValue,16);
					var shad:Shader=new Shader(loader.getURLLoader("onecolor.pbj").data);
					shad.data.color.value=[linecolor>>16&0xff/255,linecolor>>8&0xff/255,linecolor&0xff/255,trance.value/255];
					var shadf:ShaderFilter=new ShaderFilter(shad);
					graphicsSprite.filters=[shadf];
					//graphicsSprite.filters=[new BlurFilter()];
					data.draw(graphicsSprite);
					//clear up
					graphicsSprite.graphics.clear();
					graphicsSprite.filters=[];
				}*/
			}
		}
		oldx=event.localX;
		oldy=event.localY;
	}
	//cursor
	cursor.x=event.stageX;
	cursor.y=event.stageY;
}

function fillBitmapData(bitData:BitmapData, cordX:int, cordY:int, setColor:uint, sense:int=32):void {
	//color being searched for
	var getColor:int=bitData.getPixel32(cordX,cordY);
	var getColorA:int=getColor>>24&0xff;
	var getColorR:int=getColor>>16&0xff;
	var getColorG:int=getColor>>8&0xff;
	var getColorB:int=getColor&0xff;
	
	var cords:Vector.<Point>=new Vector.<Point>();
	cords.push(new Point(cordX, cordY));
	while (cords.length>0) {
		var n:int=cords.length-1;
		var cord:Point=cords[n];
		if (checkPixelForFill(bitData,cord.x,cord.y,setColor,sense,getColor,getColorA,getColorR,getColorG,getColorB)) {
			
			bitData.setPixel32(cord.x, cord.y, setColor);
			
			
			cords.push(new Point(cord.x+1, cord.y));
			cords.push(new Point(cord.x-1, cord.y));
			cords.push(new Point(cord.x, cord.y+1));
			cords.push(new Point(cord.x, cord.y-1));
		}
		cords.splice(n, 1);
	}
}
function checkPixelForFill(bitData:BitmapData, cordX:int, cordY:int, setColor:int, sense:int, getColor:int, getColorA:int, getColorR:int, getColorG:int, getColorB:int):Boolean {
	var ok:Boolean=false;
	if (cordX>=0&&cordY>=0&&cordX<bitData.width&&cordY<bitData.height) {
		var current:int=bitData.getPixel32(cordX,cordY);
		if (setColor!=current) {
			if (sense==0) {
				if (current==getColor) {
					ok=true;
				}
			} else {
				var diff:int=Math.abs((current>>24&0xff)-getColorA)+Math.abs((current>>16&0xff)-getColorR)+Math.abs((current>>8&0xff)-getColorG)+Math.abs((current&0xff)-getColorB);
				if (diff<=sense) {
					ok=true;
				}
			}
		}
	}
	return ok;
}

//print
function printimage(event:MouseEvent):void {
	if (! dialog) {
		sp.graphics.clear();
		dialog=true;
		dial=new PrintDialog();
		dial.x=(stage.stageWidth-dial.width)/2;
		dial.y=(stage.stageHeight-dial.height)/2;
		dial.sav.addEventListener(MouseEvent.CLICK,printfile);
		dial.cancel.addEventListener(MouseEvent.CLICK,cancelprint);
		addChild(dial);
	}
}

function printfile(event:MouseEvent):void {
	removeChild(dial);
	spri=new Sprite();
	spri.addChild(new Bitmap(data.clone()));
	spri.addEventListener(Event.ENTER_FRAME, printforreal);
	addChild(spri);
}

function cancelprint(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelnew);
	event.target.parent.sav.removeEventListener(MouseEvent.CLICK,printfile);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

function printforreal(event:Event):void {
	spri.removeEventListener(Event.ENTER_FRAME, printforreal);
	spri.addEventListener(Event.ENTER_FRAME, printforrea);
}
function printforrea(event:Event):void {
	spri.removeEventListener(Event.ENTER_FRAME, printforrea);
	job=new PrintJob();
	if (job.start()) {
		if (dial.scal.selected) {
			spri.scaleX=job.pageWidth/spri.width;
			spri.scaleY=job.pageHeight/spri.height;
			if (dial.fit.selected) {
				if (spri.scaleX<spri.scaleY) {
					spri.scaleY=spri.scaleX;
				} else {
					spri.scaleX=spri.scaleY;
				}
			}
		}
		job.addPage(spri, null, new PrintJobOptions(true));
		job.send();
	}
	removeChild(spri);
	dialog=false;
	dial=null;
}

//loads a file
function loadcomplete(event:Event):void {
	storeimage('Load');
	//make a new BitmapData of the right size
	size=new Point(Math.min(event.target.content.width,2880),Math.min(event.target.content.height,2880));
	data=new BitmapData(size.x,size.y,true,0x00ffffff);
	//house keeping
	bit.bitmapData=data;
	data.draw(event.target.content);
	oktofile=true;
	changezoom();
}
function filecomplete(event:Event):void {
	typ=event.target.name;
	filename=typ.substr(0,typ.indexOf("."));
	typ=typ.toLowerCase();
	typ=typ.substr(typ.indexOf(".")+1);
	if (typ=="jpg"||typ=="gif"||typ=="png") {
		//built in decoders
		var lod:Loader=new Loader();
		lod.contentLoaderInfo.addEventListener(Event.COMPLETE,loadcomplete);
		lod.loadBytes(event.target.data);
	} else {
		//non built in decoders
		storeimage('Load');
		var dat:BitmapData;
		if (typ=="bmp") {
			var decbmp:WinBmpDecoder=new WinBmpDecoder();
			decbmp.decode(event.target.data);
			dat=decbmp.bitmapData;
		} else if (typ=="tga") {
			var dectga:TGADecoder=new TGADecoder();
			dectga.decode(event.target.data);
			var dater:BitmapData=dectga.bitmapData;
			dat=new BitmapData(dater.width,dater.height,true,0x00000000);
			for (var n:uint=0; n<dater.width; n++) {
				for (var en:uint=0; en<dater.height; en++) {
					dat.setPixel32(n, dater.height-en,dater.getPixel32(n,en));
				}
			}
		} else if (typ=="tiff") {
			var dectiff:TIFF6Decoder=new TIFF6Decoder();
			dectiff.decode(event.target.data);
			dat=dectiff.bitmapData;
		}
		//make a new BitmapData of the right size
		size=new Point(Math.min(dat.width,2880),Math.min(dat.height,2880));
		data=new BitmapData(size.x,size.y,true,0x00ffffff);
		//house keeping
		bit.bitmapData=data;
		data.draw(dat);
		oktofile=true;
		changezoom();
	}
	event.target.removeEventListener(Event.COMPLETE,filecomplete);
	event.target.cancel();
}
function opens(event:MouseEvent):void {
	if (! dialog) {
		if (oktofile) {
			oktofile=false;
			fr.addEventListener(Event.SELECT, fileselecter);
			fr.addEventListener(Event.CANCEL, filecanceler);
			fr.browse(getTypes());
		} else {
			fr.cancel();
			oktofile=true;
		}
	}
}
function fileselecter(event:Event):void {
	event.target.addEventListener(Event.COMPLETE,filecomplete);
	event.target.load();
	event.target.removeEventListener(Event.SELECT, fileselecter);
	event.target.removeEventListener(Event.CANCEL, filecanceler);
}
function filecanceler(event:Event):void {
	event.target.cancel();
	event.target.removeEventListener(Event.SELECT, fileselecter);
	event.target.removeEventListener(Event.CANCEL, filecanceler);
}

function getTypes():Array {
	var all:FileFilter=new FileFilter("All Formats","*.bmp;*.gif;*.jpg;*.png;*.tga");
	var bmp:FileFilter=new FileFilter("Bmp *.bmp (24 Bit Encoding)","*.bmp");
	var gif:FileFilter=new FileFilter("Giff *.gif","*.gif");
	var jpg:FileFilter=new FileFilter("Jpg *.jpg","*.jpg");
	var png:FileFilter=new FileFilter("Png *.png","*.png");
	var tga:FileFilter=new FileFilter("Tga *.tga","*.tga");
	//var tiff:FileFilter=new FileFilter("Tiff *.tiff", "*.tiff");
	var allTypes:Array=[all,bmp,gif,jpg,png,tga];
	return allTypes;
}

//saving code
function compiles(event:MouseEvent):void {
	if (! dialog) {
		dialog=true;
		var dia=new SaveDialog();
		dia.nam.text=filename;
		dia.x=(stage.stageWidth-dia.width)/2;
		dia.y=(stage.stageHeight-dia.height)/2;
		if(typ==""){
		}else if(typ=="bmp"){
			dia.typ.selectedIndex=0;
		}else if(typ=="gif"){
			dia.typ.selectedIndex=1;
		}else if(typ=="jpg"){
			dia.typ.selectedIndex=2;
		}else if(typ=="png"){
			dia.typ.selectedIndex=3;
		}else if(typ=="tga"){
			dia.typ.selectedIndex=4;
		}
		dia.sav.addEventListener(MouseEvent.CLICK,savefile);
		dia.cancel.addEventListener(MouseEvent.CLICK,cancelsave);
		addChild(dia);
	}
}

function cancelsave(event:MouseEvent):void {
	event.target.parent.cancel.removeEventListener(MouseEvent.CLICK,cancelsave);
	event.target.parent.sav.removeEventListener(MouseEvent.CLICK,savefile);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}

function savefile(event:MouseEvent):void {
	var clone:BitmapData;
	var n:int;
	var en:int;
	var pixelValue:uint;
	var alphar:uint;
	var fil:String=event.target.parent.typ.value;
	var nam:String=event.target.parent.nam.text+"."+fil;
	var out:ByteArray;
	if (fil=="png") {
		out=PNGEncoder.encode(data);
	} else if (fil=="tiff") {
		clone=new BitmapData(data.width,data.height,false,0xAAB696);
		for (n=0; n<data.width; n++) {
			for (en=0; en<data.height; en++) {
				pixelValue=data.getPixel32(n,en);
				alphar=pixelValue>>24&0xFF;
				if (alphar==0) {
					clone.setPixel(n,en,0xffffff);
				} else {
					clone.setPixel(n,en,data.getPixel(n,en));
				}
			}
		}
		out=TiffEncoder.encode(clone);
	} else if (fil=="jpg") {
		clone=new BitmapData(data.width,data.height,false,0x000000);
		for (n=0; n<data.width; n++) {
			for (en=0; en<data.height; en++) {
				pixelValue=data.getPixel32(n,en);
				alphar=pixelValue>>24&0xFF;
				if (alphar==0) {
					clone.setPixel(n,en,0xffffff);
				} else {
					clone.setPixel(n,en,data.getPixel(n,en));

				}
			}
		}
		out=jpgEncoder.encode(clone);
	} else if (fil=="gif") {
		clone=new BitmapData(data.width,data.height,false,0xAAB696);
		for (n=0; n<data.width; n++) {
			for (en=0; en<data.height; en++) {
				pixelValue=data.getPixel32(n,en);
				alphar=pixelValue>>24&0xFF;
				if (alphar==0) {
					clone.setPixel(n,en,0xffffff);
				} else {
					clone.setPixel(n,en,data.getPixel(n,en));
				}
			}
		}
		gifEncoder.addFrame(clone);
		gifEncoder.finish();
		out=gifEncoder.stream;
		gifEncoder=new GIFEncoder();
		gifEncoder.start();
		gifEncoder.setRepeat(0);
		gifEncoder.setDelay( 70);
	} else if (fil=="bmp") {
		clone=new BitmapData(data.width,data.height,false,0xAAB696);
		for (n=0; n<data.width; n++) {
			for (en=0; en<data.height; en++) {
				pixelValue=data.getPixel32(n,en);
				alphar=pixelValue>>24&0xFF;
				if (alphar==0) {
					clone.setPixel(n,en,0xffffff);
				} else {
					clone.setPixel(n,en,data.getPixel(n,en));
				}
			}
		}
		var encbmp:WinBmpEncoder=new WinBmpEncoder();
		encbmp.encode(clone);
		out=encbmp.bytes;
	} else if (fil=="tga") {
		clone=new BitmapData(data.width,data.height,false,0xAAB696);
		for (n=0; n<data.width; n++) {
			for (en=0; en<data.height; en++) {
				pixelValue=data.getPixel32(n,en);
				alphar=pixelValue>>24&0xFF;
				if (alphar==0) {
					clone.setPixel(n,en,0xffffff);
				} else {
					clone.setPixel(n,en,data.getPixel(n,en));
				}
			}
		}
		var enctga:TGAEncoder=new TGAEncoder();
		enctga.encode(clone);
		out=enctga.bytes;
	}
	dial=event.target.parent;
	fr.addEventListener(Event.COMPLETE, finishedSaving);
	fr.addEventListener(Event.CANCEL, finishedSaving);
	fr.save(out, nam);
}

function finishedSaving(event:Event):void{
	fr.removeEventListener(Event.COMPLETE, finishedSaving);
	fr.removeEventListener(Event.CANCEL, finishedSaving);
	//house keeping
	dial.cancel.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
}

//makes a new file
function oknew(event:MouseEvent):void {
	storeimage('New');
	event.target.removeEventListener(MouseEvent.CLICK,oknew);
	event.target.parent.cancel.removeEventListener(MouseEvent.CLICK,cancelnew);
	//important part
	size=new Point(event.target.parent.wide.value,event.target.parent.high.value);
	var bac:uint=0x00ffffff;
	if (! event.target.parent.al.selected) {
		bac=0xffffffff;
	}
	data=new BitmapData(size.x,size.y,event.target.parent.al.selected,bac);
	bit.bitmapData=data;
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
	changezoom();
}
function cancelnew(event:MouseEvent):void {
	event.target.removeEventListener(MouseEvent.CLICK,cancelnew);
	event.target.parent.ok.removeEventListener(MouseEvent.CLICK,oknew);
	event.target.parent.parent.removeChild(event.target.parent);
	dialog=false;
}
function renews(event:MouseEvent):void {
	var dia=new NewDialog();
	dia.x=(stage.stageWidth-dia.width)/2;
	dia.y=(stage.stageHeight-dia.height)/2;
	dia.wide.value=size.x;
	dia.high.value=size.y;
	dia.ok.addEventListener(MouseEvent.CLICK,oknew);
	dia.cancel.addEventListener(MouseEvent.CLICK,cancelnew);
	addChild(dia);
	dialog=true;
}

//loads assets
function doneLoading(event:Event):void {
	/*var lode:Loader=loader.getLoader("rainbow.png");
	if (lode==null) {
		color=new ColorPicker();
		color.x=colorLabel.x+45;
		color.y=colorLabel.y;
		color.height=color.width=20;
		addChild(color);
	} else {
		color=makePicker(lode.content,lode.content.width,lode.content.height);
		color.x=colorText.x+56;
		color.y=colorText.y;
		color.height=color.width=20;
		addChild(color);
	}*/
	isDoneLoading=true;
	removeChild(dial);
	dial=null;
	dialog=false;
}
function progress(event:ProgressEvent):void {
	dial.prog.value=event.bytesLoaded/event.bytesTotal;
}
function ioerror(event:IOErrorEvent):void {
}

function makePicker(source:IBitmapDrawable,wide:int,high:int):ColorPicker {
	var pallet:BitmapData=new BitmapData(256,256);
	var mat:Matrix=new Matrix();
	mat.scale(256/wide,256/high);
	pallet.draw(source,mat);
	var pic:ColorPicker = new ColorPicker();
	pic.colors=new Array();
	for (var yn:int=0; yn<pallet.height; yn+=8) {
		for (var xn:int=0; xn<pallet.width; xn+=8) {
			pic.colors.push(pallet.getPixel(xn,yn));
		}
	}
	pic.setStyle("columnCount",32);
	pic.setStyle("swatchHeight",5);
	pic.setStyle("swatchWidth",5);
	return pic;
}

//misc callbacks
function toolSettingsChange(...rest):void {
	try{
		if (tool.value=="brush") {
			cursor.scaleX=cursor.scaleY=2*toolSettings.sizer.value/100*zoom.value/100;
		}
	}catch(error:TypeError){
		//do nothing
	}
}

function changeTool(...rest):void {
	toolSettings.fillShape.visible=false;
	toolSettings.sizer.visible=false;
	toolSettings.sizerLabel.visible=false;
	toolSettings.senstivity.visible=false;
	toolSettings.senstivityLabel.visible=false;
	switch (tool.value) {
		case "brush" :
			toolSettings.sizer.visible=true;
			toolSettings.sizerLabel.visible=true;
			graphicsSprite.graphics.clear();
			cursor.gotoAndStop(1);
			cursor.scaleX=cursor.scaleY=2*toolSettings.sizer.value/100;
			lineDrawing=false;
			break;
		case "line" :
			toolSettings.sizer.visible=true;
			toolSettings.sizerLabel.visible=true;
			graphicsSprite.graphics.clear();
			cursor.gotoAndStop(3);
			cursor.scaleX=cursor.scaleY=1;
			break;
		case "rectangle" :
			toolSettings.sizer.visible=true;
			toolSettings.sizerLabel.visible=true;
			toolSettings.fillShape.visible=true;
			graphicsSprite.graphics.clear();
			cursor.gotoAndStop(3);
			cursor.scaleX=cursor.scaleY=1;
			break;
		/*case "oval" :
			toolSettings.sizer.visible=true;
			toolSettings.sizerLabel.visible=true;
			toolSettings.fillShape.visible=true;
			graphicsSprite.graphics.clear();
			cursor.gotoAndStop(3);
			cursor.scaleX=cursor.scaleY=1;
			break;*/
		case "fill" :
			toolSettings.senstivity.visible=true;
			toolSettings.senstivityLabel.visible=true;
			graphicsSprite.graphics.clear();
			cursor.scaleX=cursor.scaleY=1;
			cursor.gotoAndStop(2);
			lineDrawing=false;
			break;
		case "picker" :
			graphicsSprite.graphics.clear();
			cursor.scaleX=cursor.scaleY=1;
			lineDrawing=false;
			cursor.gotoAndStop(2);
			break;
	}
}

function drawCurrentColor():void{
	palletPreview.mid.graphics.clear();
	palletPreview.mid.graphics.beginFill(selectedColorARGB&0xffffff,(selectedColorARGB>>24&0xff)/255);
	palletPreview.mid.graphics.drawRect(0,0,42,20);
	palletPreview.mid.graphics.endFill();
}