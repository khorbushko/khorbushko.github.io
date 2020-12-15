import SwiftUI

private struct CheckmarkStrokeColorKey: EnvironmentKey {
    static let defaultValue: Color = .green
}

extension EnvironmentValues {
    var checkmarkStrokeColor: Color {
        get { self[CheckmarkStrokeColorKey.self] }
        set { self[CheckmarkStrokeColorKey.self] = newValue }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            AnimatedCheckMarkView()
            AnimatedCheckMarkView()
            AnimatedCheckMarkView()
        }
        .checkmarkStrokeColor(.orange)
        .frame(width: 150, height: 450)
    }
}

struct Checkmark: Shape {
    
    func path(in rect: CGRect) -> Path {
        Path { checkMarkBezierPath in
            let origin = rect.origin
            let diameter = rect.height
            let point1 = CGPoint(
                x: origin.x + diameter * 0.1,
                y: origin.y + diameter * 0.4
            )
            let point2 = CGPoint(
                x: origin.x + diameter * 0.40,
                y: origin.y + diameter * 0.7
            )
            let point3 = CGPoint(
                x: origin.x + diameter * 0.95,
                y: origin.y + diameter * 0.2
            )
            
            checkMarkBezierPath.move(to: point1)
            checkMarkBezierPath.addLine(to: point2)
            checkMarkBezierPath.addLine(to: point3)
        }
    }
}

struct AnimatedCheckMarkView: View {
    @Environment(\.checkmarkStrokeColor) var strokeColor: Color
    
    var body: some View {
        Checkmark()
            .stroke(
                strokeColor,
                style: StrokeStyle(
                    lineWidth: 5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
    }
}

extension View {
    
    func checkmarkStrokeColor(_ color: Color) -> some View {
        environment(\.checkmarkStrokeColor, color)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
