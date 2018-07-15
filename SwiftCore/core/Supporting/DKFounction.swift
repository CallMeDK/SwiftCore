//
//  DKFounction.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/11.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import UIKit

class DKFounction {
    //国际化
    static func TR(text:String) -> String {
        return NSLocalizedString(text, comment: text)
    }
    
    //图片处理
    static func stretchable(imageName:String) -> UIImage? {
        if let image:UIImage = UIImage(named: imageName) {
            return image.stretchableImage(withLeftCapWidth: Int(image.size.width/2), topCapHeight: Int(image.size.height/2))
        }
        return nil
    }
    
    //比例尺
    static func scale(f:CGFloat)->CGFloat {
        var size = UIScreen.main.bounds.size
        
        if  UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            size = CGSize.init(width: size.height, height: size.width)
        }
        
        switch size.width {
        case 320:
            return f*320/375
        case 414:
            return f*414/375
        default:
            return f
        }
    }

    //Cell  identify
    static func identify(aClass:AnyClass)->String {
        return "cell_\(NSStringFromClass(aClass))_identify"
    }
    
    static func inset(t:CGFloat,_ l:CGFloat,_ b:CGFloat,_ r:CGFloat)->UIEdgeInsets {
        return UIEdgeInsetsMake(t, l, b, r)
    }
    
    //UIImage
    static func image(name:String) ->UIImage? {
        if let image = UIImage(named: name) {
            return image
        }
        print("素材图片不存在 \(name)")
        return nil
    }
    
    //字体
    static func FONT(s:CGFloat, _ bold:Bool = false)->UIFont {
        if bold {
            return UIFont.boldSystemFont(ofSize: s)
        }else {
            if let font = UIFont.init(name:  "HelveticaNeue-Light", size: s) {
                return font
            }
        }
        return UIFont.boldSystemFont(ofSize: s)
    }
    
    //颜色值
    static func RGB(_ r:CGFloat,_ g:CGFloat, _ b:CGFloat)->UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1)
    }
    
    static func RGBA (_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat)->UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
    static func HDA (h:Int)->UIColor {
        let red:CGFloat = CGFloat((h >> 16) & 0xff)
        let green:CGFloat = CGFloat((h >> 8) & 0xff)
        let blue:CGFloat = CGFloat((h) & 0xff)
        return DKFounction.RGB(red, green, blue)
    }
    
    static func RGB_R()->UIColor {
        return UIColor(red:CGFloat(arc4random())/CGFloat(RAND_MAX), green: CGFloat(arc4random()) / CGFloat(RAND_MAX), blue: CGFloat(arc4random()) / CGFloat(RAND_MAX), alpha: 1.0)
    }
    
}

public extension UILabel {
    class func view(font:UIFont, color:UIColor) -> UILabel {
        let lable = UILabel.init(frame: CGRect.zero)
        lable.textColor = color
        lable.font = font
        return lable
    }
    
    class func view(fSize:CGFloat) -> UILabel {
        let lable = UILabel.init(frame: CGRect.zero)
        lable.textColor = UIColor.black
        lable.font = DKFounction.FONT(s: fSize)
        return lable
    }
}

public extension UIView {
    func addSubviews(views:[UIView]) {
        for view in views {
            addSubview(view)
        }
    }
    
    convenience init(bColor backgroundColor:UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
}
