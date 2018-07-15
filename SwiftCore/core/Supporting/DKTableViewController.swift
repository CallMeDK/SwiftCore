//
//  DKTableViewController.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/13.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class DKTabelViewCell: UITableViewCell {
    var model:AnyObject?
    
    class func height(model:AnyObject? = nil) -> CGFloat {
        return 0
    }
    
    func tableView(tableView:UITableView, decelerate:Bool)  {
        
    }
}

class DKTableViewModel {
    var indexPath:IndexPath?

    var vClass:AnyClass!
    var model:AnyObject?
    
    var height: CGFloat {
        if let aClass:DKTabelViewCell.Type = vClass as? DKTabelViewCell.Type {
            return aClass.height(model: model)
        }
        return 0
    }
    
    init(vClass:AnyClass, m:AnyObject?) {
        self.vClass = vClass
        self.model = m
    }
}

class DKTableViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    let tableView:UITableView = UITableView.init(frame: CGRect.zero, style: UITableViewStyle.plain)
    var _viewModels:[DKTableViewModel]?
    var _vModels: [DKTableViewModel] {
        if _viewModels == nil {
            _viewModels = viewModels()
        }
        return _viewModels!
    }
    
    func viewModels() -> [DKTableViewModel] {
        return [DKTableViewModel]()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsHorizontalScrollIndicator = false
    }
    
    func reloadData() {
        _viewModels = nil
        tableView.reloadData()
    }
    
    //UTableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return _vModels[indexPath.row].height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _vModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let decelerate = (self.tableView.isDragging == false && self.tableView.isDecelerating == false);
        let vm = _vModels[indexPath.row]
        var cell:DKTabelViewCell?
        
        if let vClass = vm.vClass {
            let identifier = DKFounction.identify(aClass: vClass)
            vm.indexPath = indexPath
            
            cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? DKTabelViewCell
            cell?.model = vm.model
            cell?.tableView(tableView: tableView, decelerate: decelerate)
        }
        
        assert(cell != nil, "构造 TableView Cell \(NSStringFromClass(vm.vClass!)) 失败")
        return cell!
    }
    
    var indexPaths:[IndexPath] = [IndexPath]()
    func tableView(tableView:UITableView, decelerate: Bool) {
        self.tableView.visibleCells.forEach { (cell) in
            if let _cell:DKTabelViewCell = cell as? DKTabelViewCell {
                _cell.tableView(tableView: tableView, decelerate: decelerate)
            }
        }
        if decelerate {
            indexPaths.forEach({ (indexPath) in
                if let _cell = tableView.cellForRow(at: indexPath) as? DKTabelViewCell {
                    _cell.tableView(tableView: tableView, decelerate: decelerate)
                }
            })
        } else {
            indexPaths.removeAll()
            tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
                self.indexPaths.append(indexPath)
            })
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            tableView(tableView: tableView, decelerate: false)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tableView(tableView: tableView, decelerate: false)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        tableView(tableView: tableView, decelerate: true)
    }
}
