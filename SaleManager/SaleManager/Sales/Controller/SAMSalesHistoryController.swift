//
//  SAMSalesHistoryController.swift
//  SaleManager
//
//  Created by apple on 16/12/6.
//  Copyright © 2016年 YZH. All rights reserved.
//

import UIKit
import MJRefresh

///SAMSaleInfoCell重用标识符
private let SAMSaleInfoCellReuseIdentifier = "SAMSaleInfoCellReuseIdentifier"
///SAMSaleInfoCell尺寸
private let SAMSaleInfoCellSize = CGSize(width: ScreenW, height: 95)

class SAMSalesHistoryController: UIViewController {

    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //初始化UI
        setupUI()
        
        //设置collectionView
        setupCollectionView()
    }
    
    //MARK: - 初始化UI
    private func setupUI() {
        
        //设置dateBtnView的锚点, transform
        dateBtnView.layer.anchorPoint = CGPoint(x: 1, y: 0)
        dateBtnView.transform = CGAffineTransformMakeScale(0.6, 0.6)
        dateBtnView.alpha = 0.00001
        
        //设置时间按钮控件边框
        dateBtnContentView.layer.cornerRadius = 5
        
        //设置文本框
        let arr = NSArray(array: [beginDateTF, endDateTF, customerSearchTF])
        arr.enumerateObjectsUsingBlock { (obj, _, _) in
            let textField = obj as! UITextField
            
            //设置代理
            textField.delegate = self
            
            //设置inputView
            if textField != self.customerSearchTF {
                
                //设置inputView
                textField.inputView = datePicker
                
                //监听事件
                textField.addTarget(self, action: #selector(SAMSalesHistoryController.textFieldidChangeText), forControlEvents: .EditingChanged)
            }
        }
        
        //设置hudView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SAMSalesHistoryController.hudViewDidClick))
        hudView.addGestureRecognizer(tapGesture)
    }
    
    //MARK: - 初始化collectionView
    private func setupCollectionView() {
        
        //设置代理数据源
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //注册cell
        collectionView.registerNib(UINib(nibName: "SAMSaleInfoCell", bundle: nil), forCellWithReuseIdentifier: SAMSaleInfoCellReuseIdentifier)
        
        //设置上拉下拉
        collectionView.mj_header = MJRefreshNormalHeader.init(refreshingTarget: self, refreshingAction: #selector(SAMSalesHistoryController.loadNewSalesInfo))
        collectionView.mj_footer = MJRefreshBackNormalFooter(refreshingTarget: self, refreshingAction: #selector(SAMSalesHistoryController.loadMoreSalesInfo))
        
        //没有数据自动隐藏footer
        collectionView.mj_footer.automaticallyHidden = true
    }
    
    //MARK: - viewWillAppear
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //设置标题
        navigationItem.title = "历史订单"
        
        //设置时间选择器最大时间
        datePicker!.maximumDate = NSDate()
    }
    
    //MARK: - 加载数据
    func loadNewSalesInfo() {
        
        //结束下拉刷新
        collectionView.mj_footer.endRefreshing()
        
        //创建请求参数
        requestSearchPageIndex = 1
        let employeeID = SAMUserAuth.shareUser()!.employeeID!
        let CGUnitName = customerSearchCon()!
        let pageSize = String(format: "%d", requestSearchPageSize)
        let pageIndex = String(format: "%d", requestSearchPageIndex)
        let startDate = beginDateTF.text!
        let endDate = endDateTF.text!
        let parameters = ["employeeID": employeeID, "CGUnitName": CGUnitName, "pageSize": pageSize, "pageIndex": pageIndex, "startDate": startDate, "endDate": endDate]
        
        //发送请求
        SAMNetWorker.sharedNetWorker().GET(saleInfoRequestURLStr, parameters: parameters, progress: nil, success: {[weak self] (Task, Json) in
            
            //清空原先数据
            self!.saleOrderModels.removeAllObjects()
            
            //获取模型数组
            let dictArr = Json!["body"] as? [[String: AnyObject]]
            let count = dictArr?.count ?? 0
            
            //判断是否有模型数据
            if count == 0 { //没有模型数据
                //TODO: 符合条件替换成其他的
                SAMHUD.showMessage("没有符合条件的订单", superView: self!.view, hideDelay: SAMHUDNormalDuration, animated: true)
            }else { //有数据模型
                
                let arr = SAMSaleOrderInfoModel.mj_objectArrayWithKeyValuesArray(dictArr)!
                if arr.count < self!.requestSearchPageSize { //设置footer状态，提示用户没有更多信息
                    
                    self!.collectionView.mj_footer.endRefreshingWithNoMoreData()
                }else { //设置pageIndex，可能还有更多信息
                    
                    self!.requestSearchPageIndex += 1
                    self!.saleInfoRequestParameters = parameters
                }
                self!.saleOrderModels.addObjectsFromArray(arr as [AnyObject])
            }
            
            //结束上拉
            self!.collectionView.mj_header.endRefreshing()
        
            //回主线程
            dispatch_async(dispatch_get_main_queue(), {
                
                UIView.animateWithDuration(0, animations: {
                    
                    //刷新数据
                    self!.collectionView.reloadData()
                    }, completion: { (_) in
                        
                        //判断顶部条是否隐藏
                        if self!.searchViewTopDis.constant != 0 {
                            
                            //展示顶部条
                            UIView.animateWithDuration(0.5, delay: 0.2, options: .LayoutSubviews, animations: {
                                //设置stockView顶部距离
                                self!.searchViewTopDis.constant = 0
                                self!.view.layoutIfNeeded()
                                }, completion: { (_) in
                            })
                        }
                })
            })
        }) {[weak self] (Task, Error) in
            //处理上拉
            self!.collectionView.mj_header.endRefreshing()
            SAMHUD.showMessage("请检查网络", superView: self!.view, hideDelay: SAMHUDNormalDuration, animated: true)
        }
    }
    
    //MARK: - 加载更多数据
    func loadMoreSalesInfo() {
        
        //结束下拉刷新
        collectionView.mj_header.endRefreshing()
        
        //创建请求参数
        let index = String(format: "%d", requestSearchPageIndex)
        saleInfoRequestParameters!["pageIndex"] = index
        
        //发送请求
        SAMNetWorker.sharedNetWorker().GET(saleInfoRequestURLStr, parameters: saleInfoRequestParameters!, progress: nil, success: {[weak self] (Task, Json) in
            
            //获取模型数组
            let dictArr = Json!["body"] as? [[String: AnyObject]]
            let count = dictArr?.count ?? 0
            
            //判断是否有模型数据
            if count == 0 { //没有模型数据
                
                //提示用户
                SAMHUD.showMessage("没有更多订单", superView: self!.view, hideDelay: SAMHUDNormalDuration, animated: true)
                
                //设置footer
                self!.collectionView.mj_footer.endRefreshingWithNoMoreData()
            }else {//有数据模型
                
                let arr = SAMSaleOrderInfoModel.mj_objectArrayWithKeyValuesArray(dictArr)!
                
                //判断是否还有更多数据
                if arr.count < self!.requestSearchPageSize { //没有更多数据
                    
                    //设置footer状态
                    self!.collectionView.mj_footer.endRefreshingWithNoMoreData()
                }else { //可能有更多数据
                    
                    //设置pageIndex
                    self!.requestSearchPageIndex += 1
                    
                    //处理下拉
                    self!.collectionView.mj_footer.endRefreshing()
                }
                self!.saleOrderModels.addObjectsFromArray(arr as [AnyObject])
                
                //刷新数据
                dispatch_async(dispatch_get_main_queue(), {
                    self!.collectionView.reloadData()
                })
            }
        }) {[weak self] (Task, Error) in
            //处理下拉
            self!.collectionView.mj_footer.endRefreshing()
            SAMHUD.showMessage("请检查网络", superView: self!.view, hideDelay: SAMHUDNormalDuration, animated: true)
        }
    }

    //MARK: - 获取客户搜索字符串
    private func customerSearchCon() -> String? {
        let searchStr = customerSearchTF.text?.lxm_stringByTrimmingWhitespace()
        if searchStr == "" { //没有内容
            return ""
        }
        return searchStr?.componentsSeparatedByString(" ")[0]
    }
    
    //MARK: - 点击下拉按钮
    @IBAction func dropDownBtnClick(sender: UIButton) {
        
        //退出第一相应textField
        endFirstTextFieldEditing()
        
        if !dropDownBtn.selected {
            
            //显示hudView
            hudView.hidden = false
            
            //动画展示dateBtnView
            UIView.animateWithDuration(0.3, animations: {
                self.dateBtnView.transform = CGAffineTransformIdentity
                self.dateBtnView.alpha = 1
                }, completion: { (_) in
                self.dropDownBtn.selected = !self.dropDownBtn.selected
            })
        }else {
            //动画隐藏dateBtnView
            UIView.animateWithDuration(0.3, animations: {
                self.dateBtnView.transform = CGAffineTransformMakeScale(0.6, 0.6)
                self.dateBtnView.alpha = 0.00001
                }, completion: { (_) in
                self.dropDownBtn.selected = !self.dropDownBtn.selected
                    
                //隐藏HUDView
                self.hideHUDView()
            })
        }
    }
    
    //MARK: - 搜索时间按钮点击
    @IBAction func searchBtnClick(sender: AnyObject) {
        
        //结束当前第一响应者编辑状态
        endFirstTextFieldEditing()
        
        //开始刷新
        collectionView.mj_header.beginRefreshing()
    }
    
    //MARK: - 4个时间按钮的点击
    @IBAction func todayBtnClick(sender: AnyObject) {
        
        dateBtnViewdidClick(0.0)
    }
    @IBAction func yesterdayBtnClick(sender: AnyObject) {
        
       dateBtnViewdidClick(1.0)
    }
    @IBAction func last7daysBtnClick(sender: AnyObject) {
        
        dateBtnViewdidClick(7.0)
    }
    @IBAction func last30daysBtnClick(sender: AnyObject) {
        
        dateBtnViewdidClick(30.0)
    }

    //MARK: - 4个时间按钮点击时调用
    private func dateBtnViewdidClick(days: Double) {
        
        //隐藏时间按钮控件
        dropDownBtnClick(dropDownBtn)
        
        //获取今天日期字符串
        let todayDate = NSDate()
        let todayStr = todayDate.yyyyMMddStr()
        
        //获取目标日期字符串
        let disDate = todayDate.beforeOrAfter(days, before: true)
        let disStr = disDate.yyyyMMddStr()
        
        //设置字符串
        endDateTF.text = todayStr
        beginDateTF.text = disStr
        
        //调用文本框内容监听方法
        textFieldidChangeText()
    }
    
    //时间选择器 选择时间
    func dateChanged(datePicker: UIDatePicker) {
        
        //设置文本框时间
        firstTF?.text = datePicker.date.yyyyMMddStr()
        
        //调用文本框内容监听方法
        textFieldidChangeText()
    }
    
    //MARK: - 文本框改变内容
    func textFieldidChangeText() {
        if beginDateTF.hasText() && endDateTF.hasText() { //三个文本框都有真实内容
            searchBtn.enabled = true
        }else {
            searchBtn.enabled = false
        }
    }
    
    //MARK: - 点击了hudView
    func hudViewDidClick() {
        
        //结束textfield编辑状态
        endFirstTextFieldEditing()
        
        //关闭dateButtonView
        if dropDownBtn.selected {
            dropDownBtnClick(dropDownBtn)
        }
    }
    
    //MARK: - 结束textField编辑状态
    private func endFirstTextFieldEditing() {
        if firstTF != nil {
            firstTF?.resignFirstResponder()
        }
    }
    
    //MARK: - 隐藏HUDView
    private func hideHUDView() {
        if firstTF == nil && dropDownBtn.selected == false {
            hudView.hidden = true
        }
    }
    
    //MARK: - 属性懒加载
    ///时间选择器
    private lazy var datePicker: UIDatePicker? = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.addTarget(self, action: #selector(SAMSalesHistoryController.dateChanged(_:)), forControlEvents: .ValueChanged)
        return datePicker
    }()
    
    ///第一响应者
    private var firstTF: UITextField?
    
    ///条件搜索请求URLStr
    private let saleInfoRequestURLStr = "getSellMainData.ashx"
    ///条件搜索参数字典
    private var saleInfoRequestParameters: [String: AnyObject]?
    ///一次数据请求获取的数据最大条数
    private let requestSearchPageSize = 15
    ///当前数据的页码
    private var requestSearchPageIndex = 1
    
    ///数据模型数组
    private let saleOrderModels = NSMutableArray()
    
    //MARK: - XIB链接属性
    @IBOutlet weak var searchConView: UIView!
    @IBOutlet weak var beginDateTF: SAMLoginTextField!
    @IBOutlet weak var endDateTF: SAMLoginTextField!
    @IBOutlet weak var dropDownBtn: UIButton!
    @IBOutlet weak var customerSearchTF: SAMLoginTextField!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var searchViewTopDis: NSLayoutConstraint!
    
    @IBOutlet weak var dateBtnView: UIView!
    @IBOutlet weak var dateBtnContentView: UIView!
    
    @IBOutlet weak var hudView: UIView!
    
    @IBOutlet weak var constLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - 其他方法
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        //隐藏底部条
        hidesBottomBarWhenPushed = true
    }
    override func loadView() {
        view = NSBundle.mainBundle().loadNibNamed("SAMSalesHistoryController", owner: self, options: nil)![0] as! UIView
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - UITextFieldDelegate
extension SAMSalesHistoryController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        
        //展现hudView
        hudView.hidden = false
        
        //判断dateBtnView是否展现
        if dropDownBtn.selected {
            
            //隐藏界面
            dropDownBtnClick(dropDownBtn)
        }
        
        //设置第一响应者
        firstTF = textField
    }
    func textFieldDidEndEditing(textField: UITextField) {
        
        //清空firstTF
        firstTF = nil
        
        //隐藏hudView
        hideHUDView()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //结束第一响应者编辑状态
        endFirstTextFieldEditing()
        
        return true
    }
}

//MARK: - UICollectionViewDelegate
extension SAMSalesHistoryController: UICollectionViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //监听滚动，达到某一条件的时候让顶部搜索条件控件上滚消失
        let offsetY = scrollView.contentOffset.y
        
        if saleOrderModels.count != 0 {
            if offsetY > 50 {
                if searchViewTopDis.constant == 0{
                    UIView.animateWithDuration(0.6, animations: {
                        self.searchViewTopDis.constant = -self.searchConView.bounds.height
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //设置加载hud
        let hud = SAMHUD.showHUDAddedTo(KeyWindow, animated: true)
        hud.labelText = NSLocalizedString("正在加载...", comment: "HUD loading title")
        
        //取出模型
        let selectedModel = saleOrderModels[indexPath.item] as! SAMSaleOrderInfoModel
        
        //创建控制器
        let detailVC = SAMOrderDetailController()
        
        //传递订单模型
        detailVC.orderInfoModel = selectedModel
        
        //加载订单详情列表数组模型数组
        detailVC.loadOrderDetailListModels()
        
        //加载订单详情数组模型
        detailVC.loadOrderDetailModel({ 
            
                dispatch_async(dispatch_get_main_queue(), { 
                    //隐藏hud
                    hud.hide(true)
                    //成功回调闭包
                    self.navigationController?.pushViewController(detailVC, animated: true)
                })
            }, noData: { 
                
                dispatch_async(dispatch_get_main_queue(), {
                    //隐藏hud
                    hud.hide(true)
                    
                    //提示用户
                    SAMHUD.showMessage("没有数据", superView: self.view, hideDelay: SAMHUDNormalDuration, animated: true)
                })
            }) {
                
                dispatch_async(dispatch_get_main_queue(), {
                    //隐藏hud
                    hud.hide(true)
                    
                    //提示用户
                    SAMHUD.showMessage("请检查网络", superView: self.view, hideDelay: SAMHUDNormalDuration, animated: true)
                })
        }
    }
}

//MARK: - UICollectionViewDataSource
extension SAMSalesHistoryController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let count = saleOrderModels.count ?? 0
        
        //如果有数据则计算统计总数
        if count != 0 {
            var countMoney = 0.0
            for model in saleOrderModels {
                let orderModel = model as! SAMSaleOrderInfoModel
                countMoney += orderModel.actualMoney
            }
            
            //设置统计文本
            constLabel.text = String(format: "订单总数：%d，总金额：%.1f元", count, countMoney)
        }else { //没有数据
            
            //设置统计文本
            constLabel.text = "暂无数据"
        }
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SAMSaleInfoCellReuseIdentifier, forIndexPath: indexPath) as! SAMSaleInfoCell
        
        //取出模型，传递模型
        let model = saleOrderModels[indexPath.row] as! SAMSaleOrderInfoModel
        cell.saleOrderInfoModel = model
        
        return cell
    }
}

//MARK: - collectionView布局代理
extension SAMSalesHistoryController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return SAMSaleInfoCellSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
}