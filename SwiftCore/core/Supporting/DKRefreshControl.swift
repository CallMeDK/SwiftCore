//
//  DKRefreshControl.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/11.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import UIKit

var KVOContext = ""
let contentOffsetKeyPath = "contentOffset"
let contentSizeKeyPath = "contentSize"
let DKSwitchRefreshFootViewHeight:CGFloat = 40

enum DKRefreshType: Int {
    case Header
    case Footer
}

enum DKRefreshStatus: Int {
    case Normal = 1
    case Visible
    case Targger
    case Loading
}

class DKrefreshControl {
    
}

class DKHeaderControl: UIRefreshControl {
    var scrollView:UIScrollView?
    var refreshAction:(()->Void)?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(_ scrollView:UIScrollView, _ action:(()->Void)?) {
        super.init()
        self.scrollView = scrollView
        self.refreshAction = action
        
        self.scrollView?.addSubview(self)
        self.attributedTitle = NSAttributedString.init(string: "松开后自动刷新")
        self.addTarget(self, action: "_refreshActioin", for: UIControlEvents.valueChanged)
        self.beginRefreshing()
        self.endRefreshing()
    }
    
    internal func _refreshActioin() {
        self.attributedTitle = NSAttributedString(string: "加载中...")
        refreshAction?()
    }
    
    override func beginRefreshing() {
        self.attributedTitle = NSAttributedString(string: "加载中...")
        super.beginRefreshing()
    }
    
    override func endRefreshing() {
        self.attributedTitle = NSAttributedString(string: "松开后自动刷新")
        super.endRefreshing()
    }
}

class DKFooterControl: UIControl {
    class DKFooterView: UIView {
        let textLabel = UILabel.view(font: DKFounction.FONT(s: 13), color: UIColor.black)
        let activityView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            activityView.hidesWhenStopped = true
            self.backgroundColor = DKFounction.RGB(237, 237, 237)
            self.addSubviews(views: [textLabel, activityView])
            
            activityView.snp.makeConstraints { (make) in
                make.right.equalTo(textLabel.snp.left).offset(-10)
                make.centerY.equalTo(textLabel.snp.centerY)
            }
            textLabel.textAlignment = NSTextAlignment.center
            textLabel.snp.makeConstraints { (make) in
                make.center.equalTo(self)
                make.width.equalTo(100)
            }
            self.layoutIfNeeded()
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setStatus(status:DKRefreshStatus) {
            switch status {
            case .Normal,.Visible:
                activityView.stopAnimating()
                textLabel.text = "上拉加载更多"
            case .Targger:
                activityView.stopAnimating()
                textLabel.text = "上拉加载更多"
            case .Loading:
                activityView.startAnimating()
                textLabel.text = "正在加载..."
        }
            UIView.animate(withDuration: 0.1) {
                self.layoutIfNeeded()
            }
        }
    }
    
    
    weak var scrollView:UIScrollView?
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var contentInset:UIEdgeInsets = UIEdgeInsets.zero
    var refreshAction:(()->Void)?
    let contentView = DKFooterView.init(frame: CGRect.zero)
    
    init(_ scrollView:UIScrollView? , _ action:(()->Void)?) {
        super.init(frame: CGRect.zero)
        self.scrollView = scrollView
        self.refreshAction = action
        self.scrollView?.addSubview(self)
        
//        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self)
            make.height.equalTo(44)
        }
        
        self.backgroundColor = DKFounction.RGB(237, 237, 237)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let _scrollView = newSuperview as? UIScrollView {
            self.contentInset = _scrollView.contentInset
            newSuperview?.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .new, context: nil)
            newSuperview?.addObserver(self, forKeyPath: contentSizeKeyPath, options: .new, context: nil)
            self.frame = CGRect.init(x: 0, y: _scrollView.contentSize.height, width: _scrollView.frame.width, height: 100)
        }
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context:nil)
        scrollView?.removeObserver(self, forKeyPath: contentSizeKeyPath, context: nil)
        scrollView = nil
    }
    
    func updateContentOffset(ei: UIEdgeInsets) {
        UIView.animate(withDuration: 0.25) {
            self.scrollView?.contentInset = ei
        }
    }
    
    
    private var _refreshStatus = DKRefreshStatus.Normal
    var refreshStatus: DKRefreshStatus {
        get {
            return _refreshStatus
        }
        set {
            if isEnabled {
                _refreshStatus = newValue
                switch newValue {
                case .Normal:
                    var ei: UIEdgeInsets = contentInset; ei.top = 0
                    self.updateContentOffset(ei: ei)
                case .Visible:
                    print("Visible")
                case .Targger:
                    print("Targger")
                case .Loading:
                    var ei: UIEdgeInsets = contentInset ; ei.top = 0
                    ei.bottom = ei.bottom + kRefreshHeight
                    self.updateContentOffset(ei: ei)
                    refreshAction?()
                }
                contentView.setStatus(status: newValue)
            }
        }
    }
    
    let kRefreshHeight: CGFloat = 44.0
    override var isEnabled: Bool {
        didSet {
            if isEnabled == false {
                contentView.activityView.stopAnimating()
                contentView.textLabel.text = "全部加载完!"
                var ei: UIEdgeInsets = contentInset
                ei.bottom = ei.bottom + kRefreshHeight
                self.updateContentOffset(ei: ei)
            } else {
                refreshStatus = .Normal
            }
        }
    }
    
    //MARK: KVO methods
    var currentOffsetY:CGFloat = 0
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if refreshAction == nil {
            return
        }
        
        if let _scrollView = self.scrollView, let _keyPath = keyPath {
            let cOffsetY = _scrollView.contentOffset.y
            let dOffsetY = (cOffsetY + _scrollView.frame.height) - _scrollView.contentSize.height
            
            switch _keyPath {
            case contentSizeKeyPath:
                if(_scrollView.isKind(of: UICollectionView.self) == true) {
                    let collectionView:UICollectionView = _scrollView as! UICollectionView
                    let height = collectionView.collectionViewLayout.collectionViewContentSize.height
                    self.frame.origin.y = height
                } else {
                    if (_scrollView.contentSize.height == 0){
                        self.frame.origin.y = 0
                    }else if(_scrollView.contentSize.height < self.frame.size.height){
                        self.frame.origin.y = _scrollView.frame.size.height - self.frame.height
                    }else{
                        self.frame.origin.y = _scrollView.contentSize.height
                    }
                }
            case contentOffsetKeyPath:
                if dOffsetY > 5 {
                    self.frame.size.height = dOffsetY + kRefreshHeight * 2
                }
                
                if _refreshStatus == .Loading || isEnabled == false {
                    return
                }
                if dOffsetY > 5 {
                    if _scrollView.isDragging == false && _refreshStatus == .Targger {
                        refreshStatus = .Loading
                    } else if dOffsetY >= kRefreshHeight * 2 &&
                        _scrollView.isDragging && _refreshStatus != .Targger
                    {
                        refreshStatus = .Targger
                    } else if (dOffsetY > kRefreshHeight && dOffsetY<kRefreshHeight * 2) {
                        refreshStatus = .Visible
                    } else if (dOffsetY < kRefreshHeight && _refreshStatus != .Normal) {
                        refreshStatus = .Normal
                    }
                }
                break
            default: break
                
            }
            
        }
    }
    
    public func beginRefreshing() {
        refreshStatus = .Loading
    }
    
    public func endRefreshing() {
        refreshStatus = .Normal
    }
    
    
}
