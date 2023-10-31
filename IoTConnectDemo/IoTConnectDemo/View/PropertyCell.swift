//
//  PropertyCell.swift
//  DemoIOTConnectSDK_Swift
//
//  Created by rushabh.patel on 10/08/21.
//

import UIKit

class PropertyCell: UITableViewCell {

//MARK: @IBOutlet
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var txtField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //set textfield placeholder data 
    func setAttData(data:[AttData],index:Int){
        if index < data.count{
            let parentName = data[index].p
            let ln = data[index].ln
            self.txtField.placeholder = !(parentName?.isEmpty ?? true) ? "\(parentName ?? ""):\(ln ?? "")" : "\(ln ?? "")"
            self.txtField.text = data[index].value ?? ""
        }
    }
    
//    func setData(model:AttributesData,index:Int){
////        print("index \(index)")
//        let attCount = model.att?.count ?? 0
//        var dCount = 0
//        
//        for i in 0...attCount-1{
//            dCount += model.att?[i].d?.count ?? 0
//            
//            if index <= dCount-1{
//                let attDCount = model.att?[i].d?.count ?? 0
//                var dIndex = index
//                if dCount != attDCount{
//                    dIndex = (dCount - (index+1))-1
////                    print("att index \(i) index \(index) dIndex \(dIndex)")
//                    if dIndex == -1{
//                        if dCount == index + 1{
//                            dIndex = attDCount-1
//                        }else{
//                            dIndex = index-1
//                        }
//                    }
//                }
//               
//                let parentName = model.att?[i].p
//                let ln = model.att?[i].d?[dIndex].ln
//                self.txtField.placeholder = !(parentName?.isEmpty ?? true) ? "\(parentName ?? ""):\(ln ?? "")" : "\(ln ?? "")"
////                print("placeholder \(self.txtField.placeholder ?? "")")
//                break
//            }else{
//                continue
//            }
//        }
//    }

}
