import SwiftUI
import PencilKit

struct ContentView: View {
    private let canvasView = PKCanvasView()
    var body: some View {
        MyCanvasView(canvasView: canvasView)
    }
}

struct MyCanvasView: UIViewRepresentable {
    var canvasView: PKCanvasView
    private let drawing = PKDrawing()
    private let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.alwaysBounceVertical = true
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(context.coordinator)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        let parent: MyCanvasView
        
        /// Standard amount of overscroll allowed in the canvas.
        static let canvasOverscrollHeight: CGFloat = 500
        
        /// Private drawing state.
        var hasModifiedDrawing = false
        
        init(_ parent: MyCanvasView) {
            self.parent = parent
        }
        
        // MARK: Canvas View Delegate
        
        /// Delegate method: Note that the drawing has changed.
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            hasModifiedDrawing = true
            updateContentSizeForDrawing()
        }
        
        /// Helper method to set a suitable content size for the canvas view.
        func updateContentSizeForDrawing() {
            // Update the content size to match the drawing.
            let drawing = self.parent.canvasView.drawing
            let contentHeight: CGFloat
            
            // Adjust the content size to always be bigger than the drawing height.
            if drawing.bounds.isNull {
                return
            }
            
            contentHeight = max(
                self.parent.canvasView.bounds.height,
                (drawing.bounds.maxY + Coordinator.canvasOverscrollHeight) * self.parent.canvasView.zoomScale
            )
            
            self.parent.canvasView.contentSize = CGSize(
                width: self.parent.canvasView.bounds.width,
                height: contentHeight
            )
        }
    }
}

#Preview {
    ContentView()
}
