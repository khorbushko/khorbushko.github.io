//
//  ContentView.swift
//  affineTransformSwiftUI
//
//  Created by Kyryl Horbushko on 12/8/20.
//

import SwiftUI

struct ContentView: View {
    
    @State private var aTransform: CGFloat = 1
    @State private var bTransform: CGFloat = 0
    @State private var cTransform: CGFloat = 0
    @State private var dTransform: CGFloat = 1
    @State private var txTransform: CGFloat = 0
    @State private var tyTransform: CGFloat = 0
        
    var body: some View {
        VStack {
            Image("cat")
                .resizable()
                .aspectRatio(1.25, contentMode: .fit)
                .frame(height: 250, alignment: .center)
//                .transformEffect(
//                    .init(
//                        a: aTransform,
//                        b: bTransform,
//                        c: cTransform,
//                        d: dTransform,
//                        tx: txTransform,
//                        ty: tyTransform
//                    )
//                )
                .modifier(
                    AffineTransformEffect(
                        a: aTransform,
                        b: bTransform,
                        c: cTransform,
                        d: dTransform,
                        tx: txTransform,
                        ty: tyTransform
                    )
                )
                .animation(.linear)
            
            VStack {
                VStack {
                    Slider.buildFor(value: $aTransform, in: -1...1, text: { Text("a") })
                    Slider.buildFor(value: $bTransform, in: -1...1, text: { Text("b") })
                    Slider.buildFor(value: $cTransform, in: -1...1, text: { Text("c") })
                    Slider.buildFor(value: $dTransform, in: -1...1, text: { Text("d") })
                    Slider.buildFor(value: $txTransform, in: -1000...1000, text: { Text("tx") })
                    Slider.buildFor(value: $tyTransform, in: -1000...1000, text: { Text("ty") })
                }
                Spacer()
                HStack {
                    Text(
"""
|  a:  \(String(format:"%.02f", aTransform))   b: \(String(format:"%.02f", bTransform))  0.00 |
|  c:  \(String(format:"%.02f", cTransform))   d: \(String(format:"%.02f", dTransform))  0.00 |
|  tx: \(String(format:"%.02f", txTransform))  ty: \(String(format:"%.02f", tyTransform))  1.00 |
"""
                    )
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    
                    Spacer()
                    Button(action: {
                        withAnimation {
                            makeIdentityTransform()
                        }
                    }, label: {
                        Text("Identity")
                    })
                    .padding()
                }
                Spacer()
            }
            .padding()
        }
        .padding()
    }
    
    private func makeIdentityTransform() {
        aTransform = 1
        bTransform = 0
        cTransform = 0
        dTransform = 1
        txTransform = 0
        tyTransform = 0
    }
}

extension Slider where Label == EmptyView, ValueLabel == EmptyView {
    
    static func buildFor<V, C>(
        value: Binding<V>,
        in bounds: ClosedRange<V> = 0...1,
        text: () -> C,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) -> some View where V : BinaryFloatingPoint,
                         V.Stride : BinaryFloatingPoint,
                         C: View {
        HStack {
            // swift UI bug workaround https://stackoverflow.com/a/64821300/2012219
            text()
            Slider(
                value: value,
                in: bounds,
                onEditingChanged: onEditingChanged,
                label: { EmptyView() }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AffineTransformEffect: GeometryEffect {
    
    var transform: CGAffineTransform
    
    init(
        a: CGFloat? = nil,
        b: CGFloat? = nil,
        c: CGFloat? = nil,
        d: CGFloat? = nil,
        tx: CGFloat? = nil,
        ty: CGFloat? = nil
    ) {
        transform = CGAffineTransform(
            a: a ?? 1,
            b: b ?? 0,
            c: c ?? 0,
            d: d ?? 1,
            tx: tx ?? 0,
            ty: ty ?? 0
        )
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(transform)
    }
}
