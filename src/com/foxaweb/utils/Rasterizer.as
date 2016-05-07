/**
*
*Rasterizer class
*
*@authorDidier Brun aka Foxy - www.foxaweb.com
*@version1.4
* @date 2006-01-06
* @linkhttp://www.foxaweb.com
* 
* AUTHORS ******************************************************************************
* 
*authorName : Didier Brun - www.foxaweb.com
* contribution : the original class
* date :2007-01-07
* 
* authorName :Drew Cummins - http://blog.generalrelativity.org
* contribution :added bezier curves
* date :2007-02-13
* 
* authorName :Thibault Imbert - http://www.bytearray.org
* contribution :Raster now extends BitmapData, performance optimizations
* date :2009-10-16
* 
* PLEASE CONTRIBUTE ? http://www.bytearray.org/?p=67
* 
* DESCRIPTION **************************************************************************
* 
* Raster is an AS3 Bitmap drawing library. It provide some functions to draw directly 
* into BitmapData instance.
*
*LICENSE ******************************************************************************
* 
* This class is under RECIPROCAL PUBLIC LICENSE.
* http://www.opensource.org/licenses/rpl.php
* 
* Please, keep this header and the list of all authors
* 
*/
package com.foxaweb.utils{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Point;

	public class Rasterizer {

		// ------------------------------------------------
		//
		// ---o public methods
		//
		// ------------------------------------------------
		
		public static function thickline(target:BitmapData, x0:int, y0:int, x1:int, y1:int, color:uint, r:int ):void {
			var r2:int=r*r;
			for (var xn:int=-r; xn<r; xn++) {
				var dx:int=xn*xn;
				for (var yn:int=-r; yn<r; yn++) {
					var d:int=dx+yn*yn;
					if (d<r2) {
						Rasterizer.line(target,x0+xn,y0+yn,x1+xn,y1+yn,color);
					}
				}
			}
		}
		
		public static function line(target:BitmapData, x0:int, y0:int, x1:int, y1:int, color:uint ):void {
			var dx:int;
			var dy:int;
			var i:int;
			var xinc:int;
			var yinc:int;
			var cumul:int;
			var x:int;
			var y:int;
			x=x0;
			y=y0;
			dx=x1-x0;
			dy=y1-y0;
			xinc = ( dx > 0 ) ? 1 : -1;
			yinc = ( dy > 0 ) ? 1 : -1;
			dx=dx<0?- dx:dx;
			dy=dy<0?- dy:dy;
			target.setPixel32(x,y,color);

			if (dx>dy) {
				cumul=dx>>1;
				for (i = 1; i <= dx; ++i) {
					x+=xinc;
					cumul+=dy;
					if (cumul>=dx) {
						cumul-=dx;
						y+=yinc;
					}
					target.setPixel32(x,y,color);
				}
			} else {
				cumul=dy>>1;
				for (i = 1; i <= dy; ++i) {
					y+=yinc;
					cumul+=dx;
					if (cumul>=dy) {
						cumul-=dy;
						x+=xinc;
					}
					target.setPixel32(x,y,color);
				}
			}
		}

		public static function triangle(target:BitmapData, x0:int, y0:int, x1:int, y1:int, x2:int, y2:int, color:uint ):void {
			Rasterizer.line(target,x0,y0,x1,y1,color);
			Rasterizer.line(target,x1,y1,x2,y2,color);
			Rasterizer.line(target,x2,y2,x0,y0,color);
		}

		public static function filledTri(target:BitmapData, x0:int, y0:int, x1:int, y1:int, x2:int, y2:int, color:uint ):void {
			var buffer:Array=[];
			Rasterizer.lineTri(target,buffer,x0,y0,x1,y1,color);
			Rasterizer.lineTri(target,buffer,x1,y1,x2,y2,color);
			Rasterizer.lineTri(target,buffer,x2,y2,x0,y0,color);
		}
		
		public static function circle(target:BitmapData, px:int, py:int, r:int, color:uint ):void {
			var x:int;
			var y:int;
			var d:int;
			x=0;
			y=r;
			d=1-r;
			target.setPixel32(px+x,py+y,color);
			target.setPixel32(px+x,py-y,color);
			target.setPixel32(px-y,py+x,color);
			target.setPixel32(px+y,py+x,color);

			while ( y > x ) {
				if (d<0) {
					d += (x+3) << 1;
				} else {
					d += ((x - y) << 1) + 5;
					y--;
				}
				x++;
				target.setPixel32(px+x,py+y,color);
				target.setPixel32(px-x,py+y,color);
				target.setPixel32(px+x,py-y,color);
				target.setPixel32(px-x,py-y,color);
				target.setPixel32(px-y,py+x,color);
				target.setPixel32(px-y,py-x,color);
				target.setPixel32(px+y,py-x,color);
				target.setPixel32(px+y,py+x,color);
			}
		}

		public static function aaCircle(target:BitmapData, px:int, py:int, r:int, color:uint ):void {
			var vx:int;
			var vy:int;
			var d:int;
			vx=r;
			vy=0;

			var t:Number=0;
			var dry:Number;
			var buff:int;

			target.setPixel(px+vx,py+vy,color);
			target.setPixel(px-vx,py+vy,color);
			target.setPixel(px+vy,py+vx,color);
			target.setPixel(px+vy,py-vx,color);

			while ( vx > vy+1 ) {
				vy++;
				buff=Math.sqrt(r*r-vy*vy)+1;
				dry=buff-Math.sqrt(r*r-vy*vy);
				if (dry<t) {
					vx--;
				}

				Rasterizer.drawAlphaPixel(target,px+vx,py+vy,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px+vx-1,py+vy,dry,color);
				Rasterizer.drawAlphaPixel(target,px-vx,py+vy,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px-vx+1,py+vy,dry,color);
				Rasterizer.drawAlphaPixel(target,px+vx,py-vy,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px+vx-1,py-vy,dry,color);
				Rasterizer.drawAlphaPixel(target,px-vx,py-vy,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px-vx+1,py-vy,dry,color);
				Rasterizer.drawAlphaPixel(target,px+vy,py+vx,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px+vy,py+vx-1,dry,color);
				Rasterizer.drawAlphaPixel(target,px-vy,py+vx,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px-vy,py+vx-1,dry,color);
				Rasterizer.drawAlphaPixel(target,px+vy,py-vx,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px+vy,py-vx+1,dry,color);
				Rasterizer.drawAlphaPixel(target,px-vy,py-vx,1-dry,color);
				Rasterizer.drawAlphaPixel(target,px-vy,py-vx+1,dry,color);
				t=dry;
			}
		}

		public static function aaLine(target:BitmapData, x1:int, y1:int, x2:int, y2:int, color:uint ):void {
			var steep:Boolean = (y2 - y1) < 0 ? -(y2 - y1) : (y2 - y1) > (x2 - x1) < 0 ? -(x2 - x1) : (x2 - x1);
			var swap:int;

			if (steep) {
				swap=x1;
				x1=y1;
				y1=swap;
				swap=x2;
				x2=y2;
				y2=swap;
			}

			if (x1>x2) {
				swap=x1;
				x1=x2;
				x2=swap;
				swap=y1;
				y1=y2;
				y2=swap;
			}

			var dx:int=x2-x1;
			var dy:int=y2-y1;
			var gradient:Number=dy/dx;

			var xend:int=x1;
			var yend:Number = y1 + gradient * (xend - x1);
			var xgap:Number = 1-((x1 + 0.5)%1);
			var xpx1:int=xend;
			var ypx1:int=yend;
			var alpha:Number;

			alpha = ((yend)%1) * xgap;

			var intery:Number=yend+gradient;

			xend=x2;
			yend = y2 + gradient * (xend - x2);
			xgap = (x2 + 0.5)%1;

			var xpx2:int=xend;
			var ypx2:int=yend;

			alpha = (1-((yend)%1)) * xgap;

			if (steep) {
				Rasterizer.drawAlphaPixel(target,ypx2,xpx2,alpha,color);
			} else {
				Rasterizer.drawAlphaPixel(target,xpx2, ypx2,alpha,color);

			}
			alpha = ((yend)%1) * xgap;

			if (steep) {
				Rasterizer.drawAlphaPixel(target,ypx2 + 1,xpx2,alpha,color);
			} else {
				Rasterizer.drawAlphaPixel(target,xpx2, ypx2 + 1,alpha,color);

			}
			var x:int=xpx1;

			while (x++<xpx2) {
				alpha = 1-((intery)%1);

				if (steep) {
					Rasterizer.drawAlphaPixel(target,intery,x,alpha,color);
				} else {
					Rasterizer.drawAlphaPixel(target,x,intery,alpha,color);

				}
				alpha=intery%1;

				if (steep) {
					Rasterizer.drawAlphaPixel(target,intery+1,x,alpha,color);
				} else {
					Rasterizer.drawAlphaPixel(target,x,intery+1,alpha,color);

				}
				intery=intery+gradient;
			}
		}
		public static function drawRect(target:BitmapData, rect:Rectangle, color:uint ):void {
			Rasterizer.line(target, rect.x, rect.y, rect.x+rect.width, rect.y, color );
			Rasterizer.line(target, rect.x+rect.width, rect.y, rect.x+rect.width, rect.y+rect.height, color );
			Rasterizer.line(target, rect.x+rect.width, rect.y+rect.height, rect.x, rect.y+rect.height, color );
			Rasterizer.line(target, rect.x, rect.y+rect.height, rect.x, rect.y, color );
		}

		public static function drawRoundRect(target:BitmapData, rect:Rectangle, ellipseWidth:int, color:uint ):void {
			var arc:Number = 4/3 * (Math.sqrt(2) - 1);
			var xc:Number=rect.x+rect.width-ellipseWidth;
			var yc:Number=rect.y+ellipseWidth;
			Rasterizer.line(target, rect.x+ellipseWidth, rect.y, xc, rect.y, color );
			Rasterizer.cubicBezier(target, xc, rect.y, xc + ellipseWidth*arc, yc - ellipseWidth, xc + ellipseWidth, yc - ellipseWidth*arc, xc + ellipseWidth, yc, color);
			xc=rect.x+rect.width-ellipseWidth;
			yc=rect.y+rect.height-ellipseWidth;
			Rasterizer.line(target, xc + ellipseWidth, rect.y+ellipseWidth, rect.x+rect.width, yc, color );
			Rasterizer.cubicBezier(target, rect.x+rect.width, yc, xc + ellipseWidth, yc + ellipseWidth*arc, xc + ellipseWidth*arc, yc + ellipseWidth, xc, yc + ellipseWidth, color);
			xc=rect.x+ellipseWidth;
			yc=rect.y+rect.height-ellipseWidth;
			Rasterizer.line(target, rect.x+rect.width-ellipseWidth, rect.y+rect.height, xc, yc + ellipseWidth, color );
			Rasterizer.cubicBezier(target, xc, yc + ellipseWidth, xc - ellipseWidth*arc, yc + ellipseWidth, xc - ellipseWidth, yc + ellipseWidth*arc, xc - ellipseWidth, yc, color );
			xc=rect.x+ellipseWidth;
			yc=rect.y+ellipseWidth;
			Rasterizer.line(target, xc - ellipseWidth, rect.y+rect.height-ellipseWidth, rect.x, yc, color );
			Rasterizer.cubicBezier(target,rect.x, yc, xc - ellipseWidth, yc - ellipseWidth*arc, xc - ellipseWidth*arc, yc - ellipseWidth, xc, yc - ellipseWidth, color);
		}

		public static function quadBezier(target:BitmapData, anchorX0:int, anchorY0:int, controlX:int, controlY:int, anchorX1:int, anchorY1:int, c:Number, resolution:int = 3):void {
			var ox:Number=anchorX0;
			var oy:Number=anchorY0;
			var px:int;
			var py:int;
			var dist:Number=0;

			var inverse:Number=1/resolution;
			var interval:Number;
			var intervalSq:Number;
			var diff:Number;
			var diffSq:Number;

			var i:int=0;

			while ( ++i <= resolution ) {
				interval=inverse*i;
				intervalSq=interval*interval;
				diff=1-interval;
				diffSq=diff*diff;

				px=diffSq*anchorX0+2*interval*diff*controlX+intervalSq*anchorX1;
				py=diffSq*anchorY0+2*interval*diff*controlY+intervalSq*anchorY1;

				dist += Math.sqrt( ( px - ox ) * ( px - ox ) + ( py - oy ) * ( py - oy ) );

				ox=px;
				oy=py;
			}

			//approximates the length of the curve
			var curveLength:int=dist;
			inverse=1/curveLength;

			var lastx:int=anchorX0;
			var lasty:int=anchorY0;

			i=-1;
			while ( ++i <= curveLength ) {
				interval=inverse*i;
				intervalSq=interval*interval;
				diff=1-interval;
				diffSq=diff*diff;

				px=diffSq*anchorX0+2*interval*diff*controlX+intervalSq*anchorX1;
				py=diffSq*anchorY0+2*interval*diff*controlY+intervalSq*anchorY1;

				Rasterizer.line(target,lastx,lasty,px,py,c);
				lastx=px;
				lasty=py;
			}
		}
		
		public static function cubicBezier(target:BitmapData, x0:int, y0:int, x1:int, y1:int, x2:int, y2:int, x3:int, y3:int, c:Number, resolution:int = 5 ):void {
			var ox:Number=x0;
			var oy:Number=y0;
			var px:int;
			var py:int;
			var dist:Number=0;

			var inverse:Number=1/resolution;
			var interval:Number;
			var intervalSq:Number;
			var intervalCu:Number;
			var diff:Number;
			var diffSq:Number;
			var diffCu:Number;
			var i:int=0;

			while ( ++i <= resolution ) {
				interval=inverse*i;
				intervalSq=interval*interval;
				intervalCu=intervalSq*interval;
				diff=1-interval;
				diffSq=diff*diff;
				diffCu=diffSq*diff;

				px=diffCu*x0+3*interval*diffSq*x1+3*x2*intervalSq*diff+x3*intervalCu;
				py=diffCu*y0+3*interval*diffSq*y1+3*y2*intervalSq*diff+y3*intervalCu;

				dist += Math.sqrt( ( px - ox ) * ( px - ox ) + ( py - oy ) * ( py - oy ) );

				ox=px;
				oy=py;
			}

			//approximates the length of the curve
			var curveLength:int=dist;
			inverse=1/curveLength;

			var lastx:int=x0;
			var lasty:int=y0;

			i=-1;

			while ( ++i <= curveLength ) {
				interval=inverse*i;
				intervalSq=interval*interval;
				intervalCu=intervalSq*interval;
				diff=1-interval;
				diffSq=diff*diff;
				diffCu=diffSq*diff;

				px=diffCu*x0+3*interval*diffSq*x1+3*x2*intervalSq*diff+x3*intervalCu;
				py=diffCu*y0+3*interval*diffSq*y1+3*y2*intervalSq*diff+y3*intervalCu;

				Rasterizer.line(target,lastx,lasty,px,py,c);
				lastx=px;
				lasty=py;
			}
		}

		public static function drawAlphaPixel(target:BitmapData, x:int, y:int, a:Number, c:Number ):void {
			var g:uint=target.getPixel32(x,y);

			var r0:uint = ((g & 0x00FF0000) >> 16);
			var g0:uint = ((g & 0x0000FF00) >> 8);
			var b0:uint = ((g & 0x000000FF));

			var r1:uint = ((c & 0x00FF0000) >> 16);
			var g1:uint = ((c & 0x0000FF00) >> 8);
			var b1:uint = ((c & 0x000000FF));

			var ac:Number=0xFF;
			var rc:Number = r1*a+r0*(1-a);
			var gc:Number = g1*a+g0*(1-a);
			var bc:Number = b1*a+b0*(1-a);

			var n:uint = (ac<<24)+(rc<<16)+(gc<<8)+bc;
			target.setPixel32(x,y,n);
		}

		public static function checkLine(target:BitmapData, o:Array, x:int, y:int, c:int, r:Rectangle ):void {
			if (o[y]) {
				if (o[y]>x) {
					r.width=o[y]-x;
					r.x=x;
					r.y=y;
					target.fillRect(r,c);
				} else {
					r.width=x-o[y];
					r.x=o[y];
					r.y=y;
					target.fillRect(r,c);
				}
			} else {
				o[y]=x;
			}
		}
		
		public static function lineTri(target:BitmapData, o:Array, x0:int, y0:int, x1:int, y1:int, c:Number ):void {
			var steep:Boolean= (y1-y0)*(y1-y0) > (x1-x0)*(x1-x0);
			var swap:int;

			if (steep) {
				swap=x0;
				x0=y0;
				y0=swap;
				swap=x1;
				x1=y1;
				y1=swap;
			}

			if (x0>x1) {
				x0^=x1;
				x1^=x0;
				x0^=x1;
				y0^=y1;
				y1^=y0;
				y0^=y1;
			}

			var deltax:int=x1-x0;
			var deltay:int = (y1 - y0) < 0 ? -(y1 - y0) : (y1 - y0);
			var error:int=0;
			var y:int=y0;
			var ystep:int=y0<y1?1:-1;
			var x:int=x0;
			var xend:int = x1-(deltax>>1);
			var fx:int=x1;
			var fy:int=y1;
			var px:int=0;
			var r:Rectangle=new Rectangle();
			r.x=0;
			r.y=0;
			r.width=0;
			r.height=1;

			while (x++<=xend) {
				if (steep) {
					Rasterizer.checkLine(target,o,y,x,c,r);
					if (fx!=x1&&fx!=xend) {
						Rasterizer.checkLine(target,o,fy,fx+1,c,r);
					}
				}

				error+=deltay;
				if ((error<<1) >= deltax) {
					if (! steep) {
						Rasterizer.checkLine(target,o,x-px+1,y,c,r);
						if (fx!=xend) {
							Rasterizer.checkLine(target,o,fx+1,fy,c,r);
						}
					}
					px=0;
					y+=ystep;
					fy-=ystep;
					error-=deltax;
				}
				px++;
				fx--;
			}

			if (! steep) {
				Rasterizer.checkLine(target,o,x-px+1,y,c,r);
			}
		}
	}
}