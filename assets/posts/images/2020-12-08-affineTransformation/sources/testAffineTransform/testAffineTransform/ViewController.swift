//
//  ViewController.swift
//  testAffineTransform
//
//  Created by Kyryl Horbushko on 12/8/20.
//

import UIKit

final class ViewController: UIViewController {
    
    @IBOutlet private var aLabel: UILabel!
    @IBOutlet private var bLabel: UILabel!
    @IBOutlet private var cLabel: UILabel!
    @IBOutlet private var dLabel: UILabel!
    @IBOutlet private var txLabel: UILabel!
    @IBOutlet private var tyLabel: UILabel!
    
    @IBOutlet private var resultLabel: UILabel!
    
    @IBOutlet private var aSlider: UISlider!
    @IBOutlet private var bSlider: UISlider!
    @IBOutlet private var cSlider: UISlider!
    @IBOutlet private var dSlider: UISlider!
    @IBOutlet private var txSlider: UISlider!
    @IBOutlet private var tySlider: UISlider!
    
    @IBOutlet private var targetImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeAndDisplayAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    }
    
    @IBAction func onASliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(a: CGFloat(value))
    }
    
    @IBAction func onBSliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(b: CGFloat(value))
    }

    @IBAction func onCSliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(c: CGFloat(value))
    }

    @IBAction func onDSliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(d: CGFloat(value))
    }

    @IBAction func onTxSliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(tx: CGFloat(value))
    }

    @IBAction func onTySliderChange(_ slider: UISlider) {
        let value = slider.value
        changeAndDisplayAffineTransform(ty: CGFloat(value))
    }
    
    @IBAction func onIdentityButtonTap(_ sender: UIButton) {
        changeAndDisplayAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        
        aSlider.value = 1
        bSlider.value = 0
        cSlider.value = 0
        dSlider.value = 1
        txSlider.value = 0
        tySlider.value = 0
    }
    
    func changeAndDisplayAffineTransform(a: CGFloat? = nil, b: CGFloat? = nil, c: CGFloat? = nil, d: CGFloat? = nil, tx: CGFloat? = nil, ty: CGFloat? = nil) {
        let current = targetImageView.transform
        let new = CGAffineTransform(a: a ?? current.a,
                                    b: b ?? current.b,
                                    c: c ?? current.c,
                                    d: d ?? current.d,
                                    tx: tx ?? current.tx,
                                    ty: ty ?? current.ty)
        targetImageView.transform = new
        resultLabel.text =
            """
              |  a:  \(String(format:"%.02f", new.a))   b: \(String(format:"%.02f", new.b))  0.00 |
              |  c:  \(String(format:"%.02f", new.c))   d: \(String(format:"%.02f", new.d))  0.00 |
              |  tx: \(String(format:"%.02f", new.tx))  ty: \(String(format:"%.02f", new.ty))  1.00 |
            """
    }
}
