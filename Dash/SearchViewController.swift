//
//  UITableViewController.swift
//  Dash iOS
//
//  Created by chenhaoyu.1999 on 2021/3/26.
//  Copyright © 2021 Kapeli. All rights reserved.
//

import UIKit

@objc protocol SearchViewController where Self: UIViewController {
    var searchController: UISearchController { get }
    var searchResultTableView: UITableView { get }
    var tableView: UITableView { get }
}
