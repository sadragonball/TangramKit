//
//  TGRelativeLayout.swift
//  TangramKit
//
//  Created by apple on 16/3/13.
//  Copyright © 2016年 youngsoft. All rights reserved.
//

import UIKit

/**
 *相对布局是一种里面的子视图通过相互之间的约束和依赖来进行布局和定位的布局视图。
 *相对布局里面的子视图的布局位置和添加的顺序无关，而是通过设置子视图的相对依赖关系来进行定位和布局的。
 *相对布局提供和AutoLayout等价的功能。
 */
open class TGRelativeLayout: TGBaseLayout,TGRelativeLayoutViewSizeClass {
    
    /**
     *子视图调用tg_width.equal([TGLayoutSize])均分宽度时当有子视图隐藏时是否参与宽度计算,这个属性只有在参与均分视图的子视图隐藏时才有效,默认是false
     */
    public var tg_autoLayoutViewGroupWidth: Bool {
        
        get {
            return (self.tgCurrentSizeClass as! TGRelativeLayoutViewSizeClass).tg_autoLayoutViewGroupWidth
        }
        
        set {
            let sc = self.tgCurrentSizeClass as! TGRelativeLayoutViewSizeClass
            if sc.tg_autoLayoutViewGroupWidth != newValue
            {
                sc.tg_autoLayoutViewGroupWidth = newValue;
                setNeedsLayout()
            }
        }
    }
    
    /**
     *子视图调用tg_height.equal([TGLayoutSize])均分高度时当有子视图隐藏时是否参与高度计算,这个属性只有在参与均分视图的子视图隐藏时才有效,默认是false
     */
    public var tg_autoLayoutViewGroupHeight: Bool {
        
        get {
            return (self.tgCurrentSizeClass as! TGRelativeLayoutViewSizeClass).tg_autoLayoutViewGroupHeight
        }
        
        set {
            let sc = self.tgCurrentSizeClass as! TGRelativeLayoutViewSizeClass
            if sc.tg_autoLayoutViewGroupHeight != newValue
            {
                sc.tg_autoLayoutViewGroupHeight = newValue
                setNeedsLayout()
            }
        }
    }
    
    //MARK: override method
    
    override func tgCalcLayoutRect(_ size: CGSize, isEstimate: Bool, sbs:[UIView]!, type: TGSizeClassType) -> (selfSize: CGSize, hasSubLayout: Bool) {
        
        var (selfSize, hasSubLayout) = super.tgCalcLayoutRect(size, isEstimate: isEstimate, sbs:sbs, type: type)
        
        for sbv: UIView in self.subviews
        {
            if sbv.tg_useFrame
            {
                continue
            }
            
            if !isEstimate {
                sbv.tgFrame.reset()
            }
            
            if (sbv.tgLeft?.hasValue ?? false) && (sbv.tgRight?.hasValue ?? false) {
                
                sbv.tgWidth?._dimeVal = nil
            }
            
            if (sbv.tgTop?.hasValue ?? false) && (sbv.tgBottom?.hasValue ?? false) {
                sbv.tgHeight?._dimeVal = nil
            }
            
            
            if let sbvl: TGBaseLayout = sbv as? TGBaseLayout
            {
                
                if (sbvl.tgWidth?.isWrap ?? false) || (sbvl.tgHeight?.isWrap ?? false)
                {
                    hasSubLayout = true
                }
                
                if isEstimate && ((sbvl.tgWidth?.isWrap ?? false) || (sbvl.tgHeight?.isWrap ?? false))
                {
                    
                    _ = sbvl.tg_sizeThatFits(sbvl.tgFrame.frame.size, inSizeClass:type)
                    
                    sbvl.tgFrame.left = CGFloat.greatestFiniteMagnitude
                    sbvl.tgFrame.right = CGFloat.greatestFiniteMagnitude
                    sbvl.tgFrame.top = CGFloat.greatestFiniteMagnitude
                    sbvl.tgFrame.bottom = CGFloat.greatestFiniteMagnitude;
                    
                    sbvl.tgFrame.sizeClass = sbvl.tgMatchBestSizeClass(type)
                }
            }
        }
        
        let (maxSize,reCalc) = tgCalcLayoutRectHelper(selfSize)
        
        if (self.tgWidth?.isWrap ?? false)  || (self.tgHeight?.isWrap ?? false) {
            if /*selfSize.height != maxSize.height*/ _tgCGFloatNotEqual(selfSize.height, maxSize.height) || /*selfSize.width != maxSize.width*/ _tgCGFloatNotEqual(selfSize.width, maxSize.width)
            {
                if (self.tgWidth?.isWrap ?? false) {
                    selfSize.width = maxSize.width
                }
                
                if (self.tgHeight?.isWrap ?? false) {
                    selfSize.height = maxSize.height
                }
                
                if reCalc
                {
                    for sbv: UIView in self.subviews {
                        
                        if let sbvl = sbv as? TGBaseLayout , isEstimate
                        {
                            sbvl.tgFrame.left = CGFloat.greatestFiniteMagnitude
                            sbvl.tgFrame.right = CGFloat.greatestFiniteMagnitude
                            sbvl.tgFrame.top = CGFloat.greatestFiniteMagnitude
                            sbvl.tgFrame.bottom = CGFloat.greatestFiniteMagnitude;
                        }
                        else
                        {
                            sbv.tgFrame.reset()
                        }
                    }
                    
                    _ = tgCalcLayoutRectHelper(selfSize)
                }
            }
        }
        
        selfSize.height = self.tgValidMeasure(self.tgHeight,sbv:self,calcSize:selfSize.height,sbvSize:selfSize,selfLayoutSize:(self.superview == nil ? CGSize.zero : self.superview!.bounds.size));
        selfSize.width = self.tgValidMeasure(self.tgWidth,sbv:self,calcSize:selfSize.width,sbvSize:selfSize,selfLayoutSize:(self.superview == nil ? CGSize.zero : self.superview!.bounds.size));
        
        return (self.tgAdjustSizeWhenNoSubviews(size: selfSize, sbs: self.tgGetLayoutSubviews()), hasSubLayout)
    }
    
    internal override func tgCreateInstance() -> AnyObject
    {
        return TGRelativeLayoutViewSizeClassImpl()
    }
}

extension TGRelativeLayout
{
    fileprivate func tgCalcSubviewLeftRight(_ sbv: UIView, selfSize: CGSize) {
        
        
        if sbv.tgFrame.left != CGFloat.greatestFiniteMagnitude &&
            sbv.tgFrame.right != CGFloat.greatestFiniteMagnitude &&
            sbv.tgFrame.width != CGFloat.greatestFiniteMagnitude
        {
            return
        }
        
        if tgCalcSubviewWidth(sbv, selfSize: selfSize)
        {
            return
        }
        
        if (sbv.tgCenterX?.hasValue ?? false)
        {
            if (sbv.tgWidth?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
            {
                sbv.tgFrame.width = sbv.tgWidth!.measure(selfSize.width - self.tg_leftPadding - self.tg_rightPadding)
            }
        }
        
        if sbv.tgCenterX?.posRelaVal != nil
        {
            let relaView = sbv.tgCenterX!.posRelaVal.view
            
            sbv.tgFrame.left = tgCalcRelationalSubview(relaView, gravity: sbv.tgCenterX!.posRelaVal._type, selfSize: selfSize) - sbv.tgFrame.width / 2 + sbv.tgCenterX!.margin
            
            if relaView != self && self.tgIsNoLayoutSubview(relaView)
            {
                sbv.tgFrame.left -= sbv.tgCenterX!.margin
            }
            
            
            sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
        }
        else if sbv.tgCenterX?.posNumVal != nil
        {
            sbv.tgFrame.left = (selfSize.width - self.tg_rightPadding - self.tg_leftPadding - sbv.tgFrame.width) / 2 + self.tg_leftPadding + sbv.tgCenterX!.margin
            sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
        }
        else if sbv.tgCenterX?.posWeightVal != nil
        {
            sbv.tgFrame.left = (selfSize.width - self.tg_rightPadding - self.tg_leftPadding - sbv.tgFrame.width) / 2 + self.tg_leftPadding + sbv.tgCenterX!.realMarginInSize(selfSize.width - self.tg_rightPadding - self.tg_leftPadding)
            sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
        }
        else
        {
            if (sbv.tgLeft?.hasValue ?? false)
            {
                if sbv.tgLeft?.posRelaVal != nil
                {
                    let relaView = sbv.tgLeft!.posRelaVal.view
                    sbv.tgFrame.left = tgCalcRelationalSubview(relaView, gravity:sbv.tgLeft!.posRelaVal._type, selfSize: selfSize) + sbv.tgLeft!.margin
                    
                    if relaView != self && self.tgIsNoLayoutSubview(relaView)
                    {
                        sbv.tgFrame.left -= sbv.tgLeft!.margin;
                    }
                }
                else if sbv.tgLeft?.posNumVal != nil
                {
                    sbv.tgFrame.left = sbv.tgLeft!.margin + self.tg_leftPadding
                }
                else if sbv.tgLeft?.posWeightVal != nil
                {
                    sbv.tgFrame.left = sbv.tgLeft!.realMarginInSize(selfSize.width - self.tg_rightPadding - self.tg_leftPadding) + self.tg_leftPadding
                }
                
                if (sbv.tgWidth?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    //self.tg_leftPadding 这里因为sbv.tgFrame.left已经包含了leftPadding所以这里不需要再减
                    sbv.tgFrame.width = sbv.tgWidth!.measure(selfSize.width - self.tg_rightPadding - sbv.tgFrame.left)
                }
                
                sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
            }
            
            if (sbv.tgRight?.hasValue ?? false)
            {
                if sbv.tgRight?.posRelaVal != nil
                {
                    let relaView = sbv.tgRight!.posRelaVal.view
                    
                    
                    sbv.tgFrame.right = tgCalcRelationalSubview(relaView, gravity: sbv.tgRight!.posRelaVal._type, selfSize: selfSize) - sbv.tgRight!.margin + (sbv.tgLeft?.margin ?? 0)
                    
                    if relaView != self && self.tgIsNoLayoutSubview(relaView)
                    {
                        sbv.tgFrame.right += sbv.tgRight!.margin;
                    }
                    
                }
                else if sbv.tgRight?.posNumVal != nil
                {
                    sbv.tgFrame.right = selfSize.width - self.tg_rightPadding - sbv.tgRight!.margin + (sbv.tgLeft?.margin ?? 0)
                }
                else if sbv.tgRight?.posWeightVal != nil
                {
                    sbv.tgFrame.right = selfSize.width - self.tg_rightPadding - sbv.tgRight!.realMarginInSize(selfSize.width - self.tg_rightPadding - self.tg_leftPadding) + (sbv.tgLeft?.margin ?? 0)
                }
                
                if (sbv.tgWidth?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.width = sbv.tgWidth!.measure(sbv.tgFrame.right - (sbv.tgLeft?.margin ?? 0) - self.tg_leftPadding)
                }
                
                sbv.tgFrame.left = sbv.tgFrame.right - sbv.tgFrame.width
                
            }
            
            if !(sbv.tgLeft?.hasValue ?? false) && !(sbv.tgRight?.hasValue ?? false)
            {
                if (sbv.tgWidth?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.width = sbv.tgWidth!.measure(selfSize.width - self.tg_leftPadding - self.tg_rightPadding)
                }
                
                sbv.tgFrame.left = (sbv.tgLeft?.margin ?? 0) + self.tg_leftPadding
                sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
            }
        }
        
        
        //这里要更新左边最小和右边最大约束的情况。
        
        if (sbv.tgLeft?.tgMinVal?.posRelaVal != nil && sbv.tgRight?.tgMaxVal?.posRelaVal != nil)
        {
            //让宽度缩小并在最小和最大的中间排列。
            let minLeft = self.tgCalcRelationalSubview(sbv.tgLeft!.tgMinVal!.posRelaVal.view, gravity: sbv.tgLeft!.tgMinVal!.posRelaVal._type, selfSize: selfSize) + sbv.tgLeft!.tgMinVal!.offsetVal
        
            
            let maxRight = self.tgCalcRelationalSubview(sbv.tgRight!.tgMaxVal!.posRelaVal.view, gravity: sbv.tgRight!.tgMaxVal!.posRelaVal._type, selfSize: selfSize) - sbv.tgRight!.tgMaxVal!.offsetVal
            
            
            //用maxRight减去minLeft得到的宽度再减去视图的宽度，然后让其居中。。如果宽度超过则缩小视图的宽度。
            if (maxRight - minLeft < sbv.tgFrame.width)
            {
                sbv.tgFrame.width = maxRight - minLeft
                sbv.tgFrame.left = minLeft
            }
            else
            {
                sbv.tgFrame.left = (maxRight - minLeft - sbv.tgFrame.width) / 2 + minLeft
            }
            
            sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
            
        }
        else if (sbv.tgLeft?.tgMinVal?.posRelaVal != nil)
        {
            //得到左边的最小位置。如果当前的左边距小于这个位置则缩小视图的宽度。
             let minLeft = self.tgCalcRelationalSubview(sbv.tgLeft!.tgMinVal!.posRelaVal.view, gravity: sbv.tgLeft!.tgMinVal!.posRelaVal._type, selfSize: selfSize) + sbv.tgLeft!.tgMinVal!.offsetVal
            
            if (sbv.tgFrame.left < minLeft)
            {
                sbv.tgFrame.left = minLeft
                sbv.tgFrame.width = sbv.tgFrame.right - sbv.tgFrame.left
            }
            
        }
        else if (sbv.tgRight?.tgMaxVal?.posRelaVal != nil)
        {
            //得到右边的最大位置。如果当前的右边距大于了这个位置则缩小视图的宽度。
            let maxRight = self.tgCalcRelationalSubview(sbv.tgRight!.tgMaxVal!.posRelaVal.view, gravity: sbv.tgRight!.tgMaxVal!.posRelaVal._type, selfSize: selfSize) - sbv.tgRight!.tgMaxVal!.offsetVal
            
            if (sbv.tgFrame.right > maxRight)
            {
                sbv.tgFrame.right = maxRight;
                sbv.tgFrame.width = sbv.tgFrame.right - sbv.tgFrame.left
            }
            
        }

        
    }
    
    fileprivate func tgCalcSubviewTopBottom(_ sbv: UIView, selfSize: CGSize) {
        
        
        if sbv.tgFrame.top != CGFloat.greatestFiniteMagnitude &&
            sbv.tgFrame.bottom != CGFloat.greatestFiniteMagnitude &&
            sbv.tgFrame.height != CGFloat.greatestFiniteMagnitude
        {
            return
        }
        
        if tgCalcSubviewHeight(sbv, selfSize: selfSize)
        {
            return
        }
        
        if (sbv.tgCenterY?.hasValue ?? false)
        {
            if (sbv.tgHeight?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
            {
                sbv.tgFrame.height = sbv.tgHeight!.measure(selfSize.height - self.tg_topPadding - self.tg_bottomPadding)
            }
        }
        if sbv.tgCenterY?.posRelaVal != nil
        {
            let relaView = sbv.tgCenterY!.posRelaVal.view
            
            sbv.tgFrame.top = tgCalcRelationalSubview(relaView, gravity: sbv.tgCenterY!.posRelaVal._type, selfSize: selfSize) - sbv.tgFrame.height / 2 + sbv.tgCenterY!.margin
            
            
            if  relaView != self && self.tgIsNoLayoutSubview(relaView)
            {
                sbv.tgFrame.top -= sbv.tgCenterY!.margin;
            }
            
            
            sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
        }
        else if sbv.tgCenterY?.posNumVal != nil
        {
            sbv.tgFrame.top = (selfSize.height - self.tg_topPadding - self.tg_bottomPadding - sbv.tgFrame.height) / 2 + self.tg_topPadding + sbv.tgCenterY!.margin
            sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
        }
        else if sbv.tgCenterY?.posWeightVal != nil
        {
            sbv.tgFrame.top = (selfSize.height - self.tg_topPadding - self.tg_bottomPadding - sbv.tgFrame.height) / 2 + self.tg_topPadding + sbv.tgCenterY!.realMarginInSize(selfSize.height - self.tg_topPadding - self.tg_bottomPadding)
            sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
        }
        else
        {
            if (sbv.tgTop?.hasValue ?? false)
            {
                if sbv.tgTop?.posRelaVal != nil
                {
                    let relaView = sbv.tgTop!.posRelaVal.view
                    
                    
                    sbv.tgFrame.top = tgCalcRelationalSubview(relaView, gravity: sbv.tgTop!.posRelaVal._type, selfSize: selfSize) + sbv.tgTop!.margin
                    
                    if  relaView != self && self.tgIsNoLayoutSubview(relaView)
                    {
                        sbv.tgFrame.top -= sbv.tgTop!.margin;
                    }
                    
                }
                else if sbv.tgTop?.posNumVal != nil
                {
                    sbv.tgFrame.top = sbv.tgTop!.margin + self.tg_topPadding
                }
                else if sbv.tgTop?.posWeightVal != nil
                {
                    sbv.tgFrame.top = sbv.tgTop!.realMarginInSize(selfSize.height - self.tg_topPadding - self.tg_bottomPadding) + self.tg_topPadding
                }
                
                if (sbv.tgHeight?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    //self.tg_topPadding 这里因为sbv.tgFrame.top已经包含了topPadding所以这里不需要再减
                    sbv.tgFrame.height = sbv.tgHeight!.measure(selfSize.height - self.tg_topPadding - sbv.tgFrame.top)
                }
                
                sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height

            }
            
            if (sbv.tgBottom?.hasValue ?? false)
            {
                if sbv.tgBottom!.posRelaVal != nil
                {
                    let relaView = sbv.tgBottom!.posRelaVal.view
                    
                    sbv.tgFrame.bottom = tgCalcRelationalSubview(relaView, gravity: sbv.tgBottom!.posRelaVal._type, selfSize: selfSize) - sbv.tgBottom!.margin + (sbv.tgTop?.margin ?? 0)
                    
                    if  relaView != self && self.tgIsNoLayoutSubview(relaView)
                    {
                        sbv.tgFrame.bottom += sbv.tgBottom!.margin;
                    }
                    
                }
                else if sbv.tgBottom!.posNumVal != nil
                {
                    sbv.tgFrame.bottom = selfSize.height - sbv.tgBottom!.margin - self.tg_bottomPadding + (sbv.tgTop?.margin ?? 0)
                }
                else if sbv.tgBottom!.posWeightVal != nil
                {
                    sbv.tgFrame.bottom = selfSize.height - sbv.tgBottom!.realMarginInSize(selfSize.height - self.tg_topPadding - self.tg_bottomPadding) - self.tg_bottomPadding + (sbv.tgTop?.margin ?? 0)
                }
                
                if (sbv.tgHeight?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.height = sbv.tgHeight!.measure(sbv.tgFrame.bottom - (sbv.tgTop?.margin ?? 0) - self.tg_topPadding)
                }
                
                sbv.tgFrame.top = sbv.tgFrame.bottom - sbv.tgFrame.height

            }
        
            if !(sbv.tgTop?.hasValue ?? false) && !(sbv.tgBottom?.hasValue ?? false)
            {
                if (sbv.tgHeight?.isFill ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.height = sbv.tgHeight!.measure(selfSize.height - self.tg_topPadding - self.tg_bottomPadding)
                }
                
                sbv.tgFrame.top = (sbv.tgTop?.margin ?? 0) + self.tg_topPadding
                sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
            }
        }
        
        
        //这里要更新上边最小和下边最大约束的情况。
        if (sbv.tgTop?.tgMinVal?.posRelaVal != nil && sbv.tgBottom?.tgMaxVal?.posRelaVal != nil)
        {
            //让高度缩小并在最小和最大的中间排列。
            let minTop = self.tgCalcRelationalSubview(sbv.tgTop!.tgMinVal!.posRelaVal.view, gravity: sbv.tgTop!.tgMinVal!.posRelaVal._type, selfSize: selfSize) + sbv.tgTop!.tgMinVal!.offsetVal
            
            
            let maxBottom = self.tgCalcRelationalSubview(sbv.tgBottom!.tgMaxVal!.posRelaVal.view, gravity: sbv.tgBottom!.tgMaxVal!.posRelaVal._type, selfSize: selfSize) - sbv.tgBottom!.tgMaxVal!.offsetVal
            
            
            //用maxBottom减去minTop得到的高度再减去视图的高度，然后让其居中。。如果高度超过则缩小视图的高度。
            if (maxBottom - minTop < sbv.tgFrame.height)
            {
                sbv.tgFrame.height = maxBottom - minTop
                sbv.tgFrame.top = minTop
            }
            else
            {
                sbv.tgFrame.top = (maxBottom - minTop - sbv.tgFrame.height) / 2 + minTop
            }
            
            sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
            
        }
        else if (sbv.tgTop?.tgMinVal?.posRelaVal != nil)
        {
            //得到上边的最小位置。如果当前的上边距小于这个位置则缩小视图的高度。
            let minTop = self.tgCalcRelationalSubview(sbv.tgTop!.tgMinVal!.posRelaVal.view, gravity: sbv.tgTop!.tgMinVal!.posRelaVal._type, selfSize: selfSize) + sbv.tgTop!.tgMinVal!.offsetVal
        
            
            if (sbv.tgFrame.top < minTop)
            {
                sbv.tgFrame.top = minTop
                sbv.tgFrame.height = sbv.tgFrame.bottom - sbv.tgFrame.top
            }
            
        }
        else if (sbv.tgBottom?.tgMaxVal?.posRelaVal != nil)
        {
            //得到下边的最大位置。如果当前的下边距大于了这个位置则缩小视图的高度。
            let maxBottom = self.tgCalcRelationalSubview(sbv.tgBottom!.tgMaxVal!.posRelaVal.view, gravity: sbv.tgBottom!.tgMaxVal!.posRelaVal._type, selfSize: selfSize) - sbv.tgBottom!.tgMaxVal!.offsetVal
            
            if (sbv.tgFrame.bottom > maxBottom)
            {
                sbv.tgFrame.bottom = maxBottom;
                sbv.tgFrame.height = sbv.tgFrame.bottom - sbv.tgFrame.top
            }
            
        }

    }
    
    
    fileprivate func tgCalcSubviewWidth(_ sbv: UIView, selfSize: CGSize) -> Bool {
        if sbv.tgFrame.width == CGFloat.greatestFiniteMagnitude {
            if sbv.tgWidth?.dimeRelaVal != nil {
                sbv.tgFrame.width = sbv.tgWidth!.measure(tgCalcRelationalSubview(sbv.tgWidth!.dimeRelaVal.view, gravity:sbv.tgWidth!.dimeRelaVal._type, selfSize: selfSize))
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgFrame.width, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            else if sbv.tgWidth?.dimeNumVal != nil {
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgWidth!.measure, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            else if sbv.tgWidth?.dimeWeightVal != nil
            {
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgWidth!.measure((selfSize.width - self.tg_leftPadding - self.tg_rightPadding) * sbv.tgWidth!.dimeWeightVal.rawValue/100), sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            
            if self.tgIsNoLayoutSubview(sbv)
            {
                sbv.tgFrame.width = 0
            }
            
            if (sbv.tgLeft?.hasValue ?? false) && (sbv.tgRight?.hasValue ?? false)
            {
                if sbv.tgLeft?.posRelaVal != nil {
                    sbv.tgFrame.left = tgCalcRelationalSubview(sbv.tgLeft!.posRelaVal.view, gravity:sbv.tgLeft!.posRelaVal._type, selfSize: selfSize) + sbv.tgLeft!.margin
                }
                else {
                    sbv.tgFrame.left = sbv.tgLeft!.realMarginInSize(selfSize.width - self.tg_leftPadding - self.tg_rightPadding) + self.tg_leftPadding
                }
                
                if sbv.tgRight?.posRelaVal != nil {
                    sbv.tgFrame.right = tgCalcRelationalSubview(sbv.tgRight!.posRelaVal.view, gravity:sbv.tgRight!.posRelaVal._type, selfSize: selfSize) - sbv.tgRight!.margin
                }
                else {
                    sbv.tgFrame.right = selfSize.width - sbv.tgRight!.realMarginInSize(selfSize.width - self.tg_leftPadding - self.tg_rightPadding) - self.tg_rightPadding
                }
                
                sbv.tgFrame.width = sbv.tgFrame.right - sbv.tgFrame.left
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgFrame.width, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
                
                if self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.width = 0
                    sbv.tgFrame.right = sbv.tgFrame.left + sbv.tgFrame.width
                }
                
                return true
            }
            
            if sbv.tgFrame.width == CGFloat.greatestFiniteMagnitude {
                sbv.tgFrame.width = sbv.bounds.size.width
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgFrame.width, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
        }
        
        if ( (sbv.tgWidth?.tgMinVal?.dimeNumVal != nil && sbv.tgWidth!.tgMinVal!.dimeNumVal != -CGFloat.greatestFiniteMagnitude) || (sbv.tgWidth?.tgMaxVal?.dimeNumVal != nil && sbv.tgWidth!.tgMaxVal!.dimeNumVal != CGFloat.greatestFiniteMagnitude))
        {
            sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: sbv.tgFrame.width, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
        }
        
        
        return false
    }
    
    fileprivate func tgCalcSubviewHeight(_ sbv: UIView, selfSize: CGSize) -> Bool {
        if sbv.tgFrame.height == CGFloat.greatestFiniteMagnitude {
            if sbv.tgHeight?.dimeRelaVal != nil {
                sbv.tgFrame.height = sbv.tgHeight!.measure(self.tgCalcRelationalSubview(sbv.tgHeight!.dimeRelaVal.view, gravity:sbv.tgHeight!.dimeRelaVal._type, selfSize: selfSize))
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            else if sbv.tgHeight?.dimeNumVal != nil {
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgHeight!.measure, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            else if sbv.tgHeight?.dimeWeightVal != nil
            {
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgHeight!.measure((selfSize.height - self.tg_topPadding - self.tg_bottomPadding) * sbv.tgHeight!.dimeWeightVal.rawValue/100), sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            
            if self.tgIsNoLayoutSubview(sbv)
            {
                sbv.tgFrame.height = 0
            }
            
            if (sbv.tgTop?.hasValue ?? false) && (sbv.tgBottom?.hasValue ?? false) {
                if sbv.tgTop?.posRelaVal != nil {
                    sbv.tgFrame.top = self.tgCalcRelationalSubview(sbv.tgTop!.posRelaVal.view, gravity:sbv.tgTop!.posRelaVal._type, selfSize: selfSize) + sbv.tgTop!.margin
                }
                else {
                    sbv.tgFrame.top = sbv.tgTop!.realMarginInSize(selfSize.height - self.tg_topPadding - self.tg_bottomPadding) + self.tg_topPadding
                }
                
                if sbv.tgBottom?.posRelaVal != nil {
                    sbv.tgFrame.bottom = self.tgCalcRelationalSubview(sbv.tgBottom!.posRelaVal.view, gravity:sbv.tgBottom!.posRelaVal._type, selfSize: selfSize) - sbv.tgBottom!.margin
                }
                else {
                    sbv.tgFrame.bottom = selfSize.height - sbv.tgBottom!.realMarginInSize(selfSize.height - self.tg_topPadding - self.tg_bottomPadding) - self.tg_bottomPadding
                }
                
                sbv.tgFrame.height = sbv.tgFrame.bottom - sbv.tgFrame.top
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
                
                if self.tgIsNoLayoutSubview(sbv)
                {
                    sbv.tgFrame.height = 0
                    sbv.tgFrame.bottom = sbv.tgFrame.top + sbv.tgFrame.height
                }
                
                
                return true
            }
            
            if sbv.tgFrame.height == CGFloat.greatestFiniteMagnitude {
                sbv.tgFrame.height = sbv.bounds.size.height
                
                
                if (sbv.tgHeight?.isFlexHeight ?? false) && !self.tgIsNoLayoutSubview(sbv)
                {
                    if sbv.tgFrame.width == CGFloat.greatestFiniteMagnitude
                    {
                        _ = self.tgCalcSubviewWidth(sbv, selfSize: selfSize)
                    }
                    
                    sbv.tgFrame.height = self.tgCalcHeightFromHeightWrapView(sbv, width: sbv.tgFrame.width)
                }
                
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
        }
        
        if ( (sbv.tgHeight?.tgMinVal?.dimeNumVal != nil && sbv.tgHeight!.tgMinVal!.dimeNumVal != -CGFloat.greatestFiniteMagnitude) || (sbv.tgHeight?.tgMaxVal?.dimeNumVal != nil && sbv.tgHeight!.tgMaxVal!.dimeNumVal != CGFloat.greatestFiniteMagnitude))
        {
            sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
        }
        
        return false
    }
    
    fileprivate func tgCalcLayoutRectHelper(_ selfSize: CGSize) -> (selfSize: CGSize, reCalc: Bool) {
        
        var recalc: Bool = false
        
        
        for sbv:UIView in self.subviews
        {
            self.tgCalcSizeFromSizeWrapSubview(sbv);
            
            if (sbv.tgFrame.width != CGFloat.greatestFiniteMagnitude)
            {
                if (sbv.tgWidth?.tgMaxVal?.dimeRelaVal != nil && sbv.tgWidth!.tgMaxVal!.dimeRelaVal.view != self)
                {
                    _ = self.tgCalcSubviewWidth(sbv.tgWidth!.tgMaxVal!.dimeRelaVal.view, selfSize:selfSize)
                }
                
                if (sbv.tgWidth?.tgMinVal?.dimeRelaVal != nil && sbv.tgWidth!.tgMinVal!.dimeRelaVal.view != self)
                {
                    _ = self.tgCalcSubviewWidth(sbv.tgWidth!.tgMinVal!.dimeRelaVal.view, selfSize:selfSize)
                }
                
                sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv:sbv, calcSize:sbv.tgFrame.width, sbvSize:sbv.tgFrame.frame.size,selfLayoutSize:selfSize)
            }
            
            if (sbv.tgFrame.height != CGFloat.greatestFiniteMagnitude)
            {
                if (sbv.tgHeight?.tgMaxVal?.dimeRelaVal != nil && sbv.tgHeight!.tgMaxVal!.dimeRelaVal.view != self)
                {
                    _ = self.tgCalcSubviewHeight(sbv.tgHeight!.tgMaxVal!.dimeRelaVal.view,selfSize:selfSize)
                }
                
                if (sbv.tgHeight?.tgMinVal?.dimeRelaVal != nil && sbv.tgHeight!.tgMinVal!.dimeRelaVal.view != self)
                {
                    _ = self.tgCalcSubviewHeight(sbv.tgHeight!.tgMinVal!.dimeRelaVal.view,selfSize:selfSize)
                }
                
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            
            
        }
        
        
        for sbv: UIView in self.subviews {
            
            if sbv.tgWidth?.dimeArrVal != nil {
                recalc = true
                
                let dimeArray: [TGLayoutSize] = sbv.tgWidth!.dimeArrVal
                var  isViewHidden = self.tgIsNoLayoutSubview(sbv) && self.tg_autoLayoutViewGroupWidth
                var totalMulti: CGFloat = isViewHidden ? 0 : sbv.tgWidth!.multiVal
                var totalAdd: CGFloat = isViewHidden ? 0 : sbv.tgWidth!.addVal
                
                for dime:TGLayoutSize in dimeArray
                {
                    if dime.isActive
                    {
                        isViewHidden = self.tgIsNoLayoutSubview(dime.view) && self.tg_autoLayoutViewGroupWidth
                        if !isViewHidden {
                            if dime.dimeNumVal != nil {
                                totalAdd += (-1 * dime.dimeNumVal)
                            }
                            else if (dime.view as? TGBaseLayout) == nil && dime.isWrap
                            {
                                totalAdd += -1 * dime.view.tgFrame.width
                            }
                            else {
                                totalMulti += dime.multiVal
                            }
                            
                            totalAdd += dime.addVal
                        }
                    }
                }
                
                var floatWidth: CGFloat = selfSize.width - self.tg_leftPadding - self.tg_rightPadding + totalAdd
                if /*floatWidth <= 0*/ _tgCGFloatLessOrEqual(floatWidth, 0)
                {
                    floatWidth = 0
                }
                
                if totalMulti != 0 {
                    sbv.tgFrame.width = self.tgValidMeasure(sbv.tgWidth, sbv: sbv, calcSize: floatWidth * (sbv.tgWidth!.multiVal / totalMulti), sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
                    
                    if self.tgIsNoLayoutSubview(sbv)
                    {
                        sbv.tgFrame.width = 0
                    }
                    
                    for dime:TGLayoutSize in dimeArray
                    {
                        if dime.isActive
                        {
                            if dime.dimeNumVal == nil {
                                dime.view.tgFrame.width = floatWidth * (dime.multiVal / totalMulti)
                            }
                            else {
                                dime.view.tgFrame.width = dime.dimeNumVal
                            }
                            
                            dime.view.tgFrame.width = self.tgValidMeasure(dime.view.tgWidth, sbv: dime.view, calcSize: dime.view.tgFrame.width, sbvSize: dime.view.tgFrame.frame.size, selfLayoutSize: selfSize)
                            
                            if self.tgIsNoLayoutSubview(dime.view)
                            {
                                dime.view.tgFrame.width = 0
                            }
                        }
                        
                    }
                }
            }
            
            
            if sbv.tgHeight?.dimeArrVal != nil {
                recalc = true
                
                let dimeArray: [TGLayoutSize] = sbv.tgHeight!.dimeArrVal
                var isViewHidden: Bool = self.tgIsNoLayoutSubview(sbv) && self.tg_autoLayoutViewGroupHeight
                var totalMulti = isViewHidden ? 0 : sbv.tgHeight!.multiVal
                var totalAdd = isViewHidden ? 0 : sbv.tgHeight!.addVal
                for dime:TGLayoutSize in dimeArray
                {
                    if dime.isActive
                    {
                        isViewHidden =  self.tgIsNoLayoutSubview(dime.view) && self.tg_autoLayoutViewGroupHeight
                        if !isViewHidden {
                            if dime.dimeNumVal != nil {
                                totalAdd += (-1 * dime.dimeNumVal!)
                            }
                            else if (dime.view as? TGBaseLayout) == nil && dime.isWrap
                            {
                                totalAdd += -1 * dime.view.tgFrame.height;
                            }
                            else {
                                totalMulti += dime.multiVal
                            }
                            
                            totalAdd += dime.addVal
                        }
                    }
                }
                
                var floatHeight = selfSize.height - self.tg_topPadding - self.tg_bottomPadding + totalAdd
                if /*floatHeight <= 0*/ _tgCGFloatLessOrEqual(floatHeight, 0)
                {
                    floatHeight = 0
                }
                if totalMulti != 0 {
                    sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: floatHeight * (sbv.tgHeight!.multiVal / totalMulti), sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
                    
                    if self.tgIsNoLayoutSubview(sbv)
                    {
                        sbv.tgFrame.height = 0
                    }
                    
                    for dime: TGLayoutSize in dimeArray
                    {
                        if dime.isActive
                        {
                            if dime.dimeNumVal == nil {
                                dime.view.tgFrame.height = floatHeight * (dime.multiVal / totalMulti)
                            }
                            else {
                                dime.view.tgFrame.height = dime.dimeNumVal
                            }
                            
                            dime.view.tgFrame.height = self.tgValidMeasure(dime.view.tgHeight, sbv: dime.view, calcSize: dime.view.tgFrame.height, sbvSize: dime.view.tgFrame.frame.size, selfLayoutSize: selfSize)
                            
                            if self.tgIsNoLayoutSubview(dime.view)
                            {
                                dime.view.tgFrame.height = 0
                            }
                        }
                        
                    }
                }
            }
            
            
            if sbv.tgCenterX?.posArrVal != nil
            {
                
                let centerArray: [TGLayoutPos] = sbv.tgCenterX!.posArrVal
                var totalWidth: CGFloat = 0.0
                var totalOffset:CGFloat = 0.0
                
                var nextPos:TGLayoutPos! = nil
                var i = centerArray.count - 1
                while (i >= 0)
                {
                    let pos = centerArray[i]
                    if !self.tgIsNoLayoutSubview(pos.view)
                    {
                        if totalWidth != 0
                        {
                            if nextPos != nil
                            {
                                totalOffset += nextPos.view.tgCenterX!.margin
                            }
                        }
                        
                        _ = self.tgCalcSubviewWidth(pos.view, selfSize: selfSize)
                        totalWidth += pos.view.tgFrame.width
                    }
                    
                    nextPos = pos
                    i -= 1
                }
                
                if !self.tgIsNoLayoutSubview(sbv)
                {
                    if totalWidth != 0
                    {
                        if nextPos != nil
                        {
                            totalOffset += nextPos.view.tgCenterX!.margin
                        }
                    }
                    
                    _ = self.tgCalcSubviewWidth(sbv, selfSize: selfSize)
                    totalWidth += sbv.tgFrame.width
                    totalOffset += sbv.tgCenterX!.margin
                    
                }
                
                var leftOffset: CGFloat = (selfSize.width - self.tg_leftPadding - self.tg_rightPadding - totalWidth - totalOffset) / 2.0
                leftOffset += self.tg_leftPadding
                
                var prev:AnyObject! = leftOffset as AnyObject!
                sbv.tg_left.equal(leftOffset)
                prev = sbv.tg_right
                
                for pos: TGLayoutPos in centerArray
                {
                    if let prevf = prev as? CGFloat
                    {
                        pos.view.tg_left.equal(prevf,offset:pos.view.tgCenterX!.margin)
                        
                    }
                    else
                    {
                        pos.view.tg_left.equal(prev as? TGLayoutPos, offset:pos.view.tgCenterX!.margin)
                    }
                    
                    prev = pos.view.tg_right
                }
            }
            
            if sbv.tgCenterY?.posArrVal != nil
            {
                let centerArray: [TGLayoutPos] = sbv.tgCenterY!.posArrVal
                var totalHeight: CGFloat = 0.0
                var totalOffset:CGFloat = 0.0
                
                var nextPos:TGLayoutPos! = nil
                var i = centerArray.count - 1
                while (i >= 0)
                {
                    let pos = centerArray[i]
                    if !self.tgIsNoLayoutSubview(pos.view)
                    {
                        if totalHeight != 0
                        {
                            if nextPos != nil
                            {
                                totalOffset += nextPos.view.tgCenterY!.margin
                            }
                        }
                        
                        _  = self.tgCalcSubviewHeight(pos.view, selfSize: selfSize)
                        totalHeight += pos.view.tgFrame.height
                    }
                    
                    nextPos = pos
                    i -= 1
                }
                
                if !self.tgIsNoLayoutSubview(sbv)
                {
                    if totalHeight != 0
                    {
                        if nextPos != nil
                        {
                            totalOffset += nextPos.view.tgCenterY!.margin
                        }
                    }
                    
                    _ = self.tgCalcSubviewHeight(sbv, selfSize: selfSize)
                    totalHeight += sbv.tgFrame.height
                    totalOffset += sbv.tgCenterY!.margin
                    
                }
                
                var topOffset: CGFloat = (selfSize.height - self.tg_topPadding - self.tg_bottomPadding - totalHeight - totalOffset) / 2.0
                topOffset += self.tg_topPadding
                
                var prev:AnyObject! = topOffset as AnyObject!
                sbv.tg_top.equal(topOffset)
                prev = sbv.tg_bottom
                
                for pos: TGLayoutPos in centerArray
                {
                    if let prevf = prev as? CGFloat
                    {
                        pos.view.tg_top.equal(prevf,offset:pos.view.tgCenterY!.margin)
                        
                    }
                    else
                    {
                        pos.view.tg_top.equal(prev as? TGLayoutPos, offset:pos.view.tgCenterY!.margin)
                    }
                    
                    prev = pos.view.tg_bottom
                }
                
            }
        }
        
        
        var maxWidth = self.tg_leftPadding
        var maxHeight = self.tg_topPadding
        
        for sbv: UIView in self.subviews {
            var canCalcMaxWidth = true
            var canCalcMaxHeight = true
            
            tgCalcSubviewLeftRight(sbv, selfSize: selfSize)
            
            if (sbv.tgRight?.posRelaVal != nil && sbv.tgRight!.posRelaVal.view == self) || sbv.tgRight?.posWeightVal != nil
            {
                recalc = true
            }
            
            if (sbv.tgWidth?.dimeRelaVal != nil && sbv.tgWidth!.dimeRelaVal.view == self) || sbv.tgWidth?.dimeWeightVal != nil || (sbv.tgWidth?.isFill ?? false)
            {
                canCalcMaxWidth = false
                recalc = true
            }
            
            if sbv.tgLeft?.posRelaVal != nil && sbv.tgLeft!.posRelaVal.view == self && sbv.tgRight?.posRelaVal != nil && sbv.tgRight!.posRelaVal.view == self
            {
                canCalcMaxWidth = false
            }
            
            
            
            if (sbv.tgHeight?.isFlexHeight ?? false) {
                sbv.tgFrame.height = self.tgCalcHeightFromHeightWrapView(sbv, width: sbv.tgFrame.width)
                sbv.tgFrame.height = self.tgValidMeasure(sbv.tgHeight, sbv: sbv, calcSize: sbv.tgFrame.height, sbvSize: sbv.tgFrame.frame.size, selfLayoutSize: selfSize)
            }
            
            tgCalcSubviewTopBottom(sbv, selfSize: selfSize)
            
                        
            if (sbv.tgBottom?.posRelaVal != nil && sbv.tgBottom!.posRelaVal.view == self) || sbv.tgBottom?.posWeightVal != nil
            {
                recalc = true
            }
            
            if (sbv.tgHeight?.dimeRelaVal != nil && sbv.tgHeight!.dimeRelaVal.view == self) ||  (sbv.tgHeight?.isFill ?? false) || sbv.tgHeight?.dimeWeightVal != nil
            {
                recalc = true
                canCalcMaxHeight = false
            }
            
           
            if sbv.tgTop?.posRelaVal != nil && sbv.tgTop!.posRelaVal.view == self && sbv.tgBottom?.posRelaVal != nil && sbv.tgBottom!.posRelaVal.view == self {
                canCalcMaxHeight = false
            }
            
            if self.tgIsNoLayoutSubview(sbv)
            {
                continue
            }
            
            
            if canCalcMaxWidth && maxWidth < sbv.tgFrame.right + (sbv.tgRight?.margin ?? 0) {
                maxWidth = sbv.tgFrame.right + (sbv.tgRight?.margin ?? 0)
            }
            
            if canCalcMaxHeight && maxHeight < sbv.tgFrame.bottom + (sbv.tgBottom?.margin ?? 0) {
                maxHeight = sbv.tgFrame.bottom + (sbv.tgBottom?.margin ?? 0)
            }
        }
        
        maxWidth += self.tg_rightPadding
        maxHeight += self.tg_bottomPadding
        return (CGSize(width: maxWidth, height: maxHeight), recalc);
    }
    
    fileprivate func tgCalcRelationalSubview(_ sbv: UIView!, gravity:TGGravity, selfSize: CGSize) -> CGFloat {
        switch gravity {
        case TGGravity.horz.left:
            if sbv == self || sbv == nil {
                return self.tg_leftPadding
            }
            
            if sbv.tgFrame.left != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.left
            }
            
            
            tgCalcSubviewLeftRight(sbv, selfSize: selfSize)
            
            return sbv.tgFrame.left
            
            
        case TGGravity.horz.right:
            if sbv == self || sbv == nil {
                return selfSize.width - self.tg_rightPadding
            }
            
            
            if sbv.tgFrame.right != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.right
            }
            
            tgCalcSubviewLeftRight(sbv, selfSize: selfSize)
            
            return sbv.tgFrame.right
            
        case TGGravity.vert.top:
            if sbv == self || sbv == nil {
                return self.tg_topPadding
            }
            
            if sbv.tgFrame.top != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.top
            }
            
            tgCalcSubviewTopBottom(sbv, selfSize: selfSize)
            
            return sbv.tgFrame.top
            
        case TGGravity.vert.bottom:
            if sbv == self || sbv == nil {
                return selfSize.height - self.tg_bottomPadding
            }
            
            if sbv.tgFrame.bottom != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.bottom
            }
            tgCalcSubviewTopBottom(sbv, selfSize: selfSize)
            
            return sbv.tgFrame.bottom
            
        case TGGravity.horz.fill:
            
            if sbv == self || sbv == nil {
                return selfSize.width - self.tg_leftPadding - self.tg_rightPadding
            }
            
            if sbv.tgFrame.width != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.width
            }
            
            tgCalcSubviewLeftRight(sbv, selfSize: selfSize)
            return sbv.tgFrame.width
            
        case TGGravity.vert.fill:
            if sbv == self || sbv == nil {
                return selfSize.height - self.tg_topPadding - self.tg_bottomPadding
            }
            
            if sbv.tgFrame.height != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.height
            }
            
            tgCalcSubviewTopBottom(sbv, selfSize: selfSize)
            return sbv.tgFrame.height
            
        case TGGravity.horz.center:
            if sbv == self || sbv == nil {
                return (selfSize.width - self.tg_leftPadding - self.tg_rightPadding) / 2 + self.tg_leftPadding
            }
            
            
            if sbv.tgFrame.left != CGFloat.greatestFiniteMagnitude && sbv.tgFrame.right != CGFloat.greatestFiniteMagnitude && sbv.tgFrame.width != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.left + sbv.tgFrame.width / 2
            }
            
            tgCalcSubviewLeftRight(sbv, selfSize: selfSize)
            
            return sbv.tgFrame.left + sbv.tgFrame.width / 2.0
            
        case TGGravity.vert.center:
            if sbv == self || sbv == nil {
                return (selfSize.height - self.tg_topPadding - self.tg_bottomPadding) / 2 + self.tg_topPadding
            }
            
            
            if sbv.tgFrame.top != CGFloat.greatestFiniteMagnitude && sbv.tgFrame.bottom != CGFloat.greatestFiniteMagnitude && sbv.tgFrame.height != CGFloat.greatestFiniteMagnitude {
                return sbv.tgFrame.top + sbv.tgFrame.height / 2.0
            }
            
            tgCalcSubviewTopBottom(sbv, selfSize: selfSize)
            return sbv.tgFrame.top + sbv.tgFrame.height / 2
            
        default:
            print("do nothing")
        }
        
        return 0
    }
    
    
    
    
}
