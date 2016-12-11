//
//  SAMOrderDetailController.swift
//  SaleManager
//
//  Created by apple on 16/12/9.
//  Copyright © 2016年 YZH. All rights reserved.
//

import UIKit

///下面的小CELL重用标识符
private let SAMOrderDetailSmallCellReuseIdentifier = "SAMOrderDetailSmallCellReuseIdentifier"
///下面的小CELL重用标识符
private let SAMOrderDetailBigCellReuseIdentifier = "SAMOrderDetailBigCellReuseIdentifier"
///大CELL的size
private let SAMOrderDetailBigCellSize = CGSize(width: ScreenW, height: 225)
///小CELL的size
private let SAMOrderDetailSmallCellSize = CGSize(width: ScreenW, height: 44)

class SAMOrderDetailController: UIViewController {

    ///接收的订单模型
    var orderInfoModel: SAMSaleOrderInfoModel?
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        //初始化collectionView
        setupCollectionView()
    }

    //MARK: - 初始化orderDetailCollectionView
    private func setupCollectionView() {
        
        //设置内容边距
        collectionView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 10, right: 0)
        
        //设置代理数据源
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //注册大cell
        collectionView.registerNib(UINib(nibName: "SAMOrderDetailBigCell", bundle: nil), forCellWithReuseIdentifier: SAMOrderDetailBigCellReuseIdentifier)
        
        //注册小cell
        collectionView.registerNib(UINib(nibName: "SAMOrderDetailSmallCell", bundle: nil), forCellWithReuseIdentifier: SAMOrderDetailSmallCellReuseIdentifier)
    }
    
    //MARK: - viewWillAppear
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //设置标题
        navigationItem.title = "订单详情"
        
        //刷新数据
        collectionView.reloadData()
        
        //设置文本
        //设置客户名称
        if orderInfoModel!.CGUnitName != "" {
            customerLabel.text = orderInfoModel!.CGUnitName
        }else {
            customerLabel.text = "---"
        }
        //设置时间
        if orderInfoModel!.startDate != "" {
            startDateLabel.text = orderInfoModel!.startDate
        }else {
            startDateLabel.text = "---"
        }
        //设置订单编号
        if orderInfoModel!.billNumber != "" {
            orderNumberLabel.text = orderInfoModel!.billNumber
        }else {
            orderNumberLabel.text = "---"
        }
        
        //设置米数
        if orderDetailListModels.count > 0 {
            var count = 0.0
            for model in orderDetailListModels {
                let listModel = model as! SAMSaleOrderDetailListModel
                count += listModel.countM
            }
            mishuLabel.text = String(format: "%.1f米", count)
        }
        
        //设置金额
        priceLabel.text = String(format: "%.1f元", orderInfoModel!.actualMoney)
    }

    //MARK: - 对外提供加载订单详情的方法
    func loadOrderDetailModel(success: ()->(), noData: ()->(), error: ()->()) {
        
        //创建请求参数
        let parameters = ["billNumber": orderInfoModel!.billNumber!]
        
        //发送请求
        SAMNetWorker.sharedNetWorker().GET("getSellMainDataByBillNumber.ashx", parameters: parameters, progress: nil, success: { (Task, Json) in
            
            //获取模型数组
            let dictArr = Json!["body"] as? [[String: AnyObject]]
            let count = dictArr?.count ?? 0
            
            //判断是否有模型数据
            if count == 0 { //没有模型数据
                
               noData()
            }else { //有数据模型
                
                let arr = SAMSaleOrderDetailModel.mj_objectArrayWithKeyValuesArray(dictArr)!
                self.orderDetailModel = (arr[0] as! SAMSaleOrderDetailModel)
                success()
            }
        }) { (Task, Error) in
            
            error()
        }
    }
    
    //MARK: - 对外提供的加载订单列表详情模型数组的方法
    func loadOrderDetailListModels() {
        
        //清空数组
        orderDetailListModels.removeAllObjects()
        
        //创建请求参数
        let parameters = ["billNumber": orderInfoModel!.billNumber!]
        
        //发送请求
        SAMNetWorker.sharedNetWorker().GET("getSellDetailDataByBillNumber.ashx", parameters: parameters, progress: nil, success: { (Task, Json) in
            
            //获取模型数组
            let dictArr = Json!["body"] as? [[String: AnyObject]]
            let count = dictArr?.count ?? 0
            
            //判断是否有模型数据
            if count != 0 {
                
                let arr = SAMSaleOrderDetailListModel.mj_objectArrayWithKeyValuesArray(dictArr)!
                self.orderDetailListModels.addObjectsFromArray(arr as [AnyObject])
            }
        }) { (Task, Error) in
        }
    }
    
    //MARK: - 属性懒加载
    ///左边标题数组
    private let titles = [["仓库：", "备注："], ["运费金额：", "其他金额：", "应收金额：", "本单毛利："], ["本次收款：", "收款账户："], ["应收余额："], ["货运公司：", "快递单号：", "业务员：", "拼包地址："]]
    
    ///右边文字内容数组
    private var titleContents: [[String]]?
    
    ///数据模型
    private var orderDetailModel: SAMSaleOrderDetailModel? {
        didSet{
            //仓库字符串
            let storehouseNameStr = orderDetailModel!.storehouseName != "" ? orderDetailModel!.storehouseName : "---"
            
            //备注符串
            let memoInfoStr = orderDetailModel!.memoInfo != "" ? orderDetailModel!.memoInfo : "---"
            
            //运费金额符串
            let freightFeeStr = orderDetailModel!.freightFee != "" ? orderDetailModel!.freightFee : "---"
            
            //其他金额符串
            let cutMoneyStr = orderDetailModel!.cutMoney != "" ? orderDetailModel!.cutMoney : "---"
            
            //应收金额字符串
            let actualMoneyStr = orderDetailModel!.actualMoney != "" ? orderDetailModel!.actualMoney : "---"
            
            //本单毛利字符串
            let profitsStr = orderDetailModel!.profits != "" ? orderDetailModel!.profits : "---"
            
            //本次收款字符串
            let receivedMoneyStr = orderDetailModel!.receivedMoney != "" ? orderDetailModel!.receivedMoney : "---"
            
            //收款账户字符串
            let accountNameStr = orderDetailModel!.accountName != "" ? orderDetailModel!.accountName : "---"
            
            //应收余额字符串
            let dueMoneyStr = orderDetailModel!.dueMoney != "" ? orderDetailModel!.dueMoney : "---"
            
            //货运公司字符串
            let freightCompanyStr = orderDetailModel!.freightCompany != "" ? orderDetailModel!.freightCompany : "---"
            
            //快递单号字符串
            let freightNumberStr = orderDetailModel!.freightNumber != "" ? orderDetailModel!.freightNumber : "---"
            
            //业务员字符串
            let employeeNameStr = orderDetailModel!.employeeName != "" ? orderDetailModel!.employeeName : "---"
            
            //拼包地址字符串
            let PBAddressStr = orderDetailModel!.PBAddress != "" ? orderDetailModel!.PBAddress : "---"
            
            //设置右边文字内容数组
            titleContents = [[storehouseNameStr!, memoInfoStr!], [freightFeeStr!, cutMoneyStr!, actualMoneyStr!, profitsStr!], [receivedMoneyStr!, accountNameStr!], [dueMoneyStr!], [freightCompanyStr!, freightNumberStr!, employeeNameStr!, PBAddressStr!]]
        }
    }
    
    ///订单列表详情模型数组
    private var orderDetailListModels = NSMutableArray()
    
    //MARK: - XIB链接属性
    @IBOutlet weak var customerLabel: UILabel!
    @IBOutlet weak var orderNumberLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var mishuLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
}

//MARK: - UICollectionViewDataSource
extension SAMOrderDetailController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        let count = titleContents?.count ?? 0
        return count + 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }else {
            return titleContents![section - 1].count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let bigCell = collectionView.dequeueReusableCellWithReuseIdentifier(SAMOrderDetailBigCellReuseIdentifier, forIndexPath: indexPath) as! SAMOrderDetailBigCell
            
            //传递数据模型数组
            bigCell.orderDetailListModelArr = orderDetailListModels
            return bigCell
        }else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SAMOrderDetailSmallCellReuseIdentifier, forIndexPath: indexPath) as! SAMOrderDetailSmallCell
            
            //赋值
            cell.titleLabel.text = titles[indexPath.section - 1][indexPath.item]
            cell.contentLabel.text = titleContents![indexPath.section - 1][indexPath.item]
            
            return cell
        }
    }
}

//MARK: - collectionView布局代理
extension SAMOrderDetailController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return SAMOrderDetailBigCellSize
        }else {
            return SAMOrderDetailSmallCellSize
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        if section == 0 {
            return CGSizeZero
        }else {
            return CGSize(width: ScreenW, height: 20)
        }
    }
}