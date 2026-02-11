import Cocoa
import MetalKit
import ObjectiveC

private var sliderActionKey: UInt8 = 0

class GameViewController: NSViewController {
    var renderer: Renderer!
    
    let scrollView = NSScrollView()
    let stackView = NSStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        setupUI()
    }

    private func setupMetal() {
        guard let mtkView = self.view as? MTKView else { return }
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        renderer = Renderer(metalView: mtkView)
        mtkView.delegate = renderer
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        scrollView.contentView = FlippedClipView()
        
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        scrollView.layer?.cornerRadius = 10
        scrollView.layer?.zPosition = 100
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        scrollView.documentView = stackView
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            scrollView.widthAnchor.constraint(equalToConstant: 220),
            
            stackView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])

        addControl(label: "Raio Schwarzschild (rs)", min: 0.1, max: 5.0, value: 1.0) { self.renderer.rsValue = $0 }
        addControl(label: "Gravidade (Aceleração)", min: -5.0, max: -0.1, value: -1.5) { self.renderer.gravityFactor = $0 }
        addControl(label: "Delta Tempo (dt)", min: 0.01, max: 0.2, value: 0.1) { self.renderer.deltaTime = $0 }
        
        addControl(label: "Disco: Limite Interno", min: 1.1, max: 4.0, value: 2.6) { self.renderer.diskInner = $0 }
        addControl(label: "Disco: Limite Externo", min: 4.1, max: 15.0, value: 8.5) { self.renderer.diskOuter = $0 }
        addControl(label: "Efeito Doppler", min: 0.0, max: 2.0, value: 0.75) { self.renderer.dopplerFactor = $0 }
        addControl(label: "Frequência (Flow)", min: 1.0, max: 30.0, value: 10.0) { self.renderer.flowFreq = $0 }
        
        addControl(label: "Estrelas Próximas", min: 0.999, max: 0.95, value: 0.98) { self.renderer.nearStarsDensity = $0 }
        addControl(label: "Estrelas Distantes", min: 0.99, max: 0.90, value: 0.95) { self.renderer.distantStarsDensity = $0 }
        addControl(label: "Intensidade Nebulosa", min: 0.0, max: 5.0, value: 1.0) { self.renderer.nebulaIntensity = $0 }
        
        addControl(label: "Distância Câmera (Zoom)", min: 5.0, max: 100.0, value: 30.0) { self.renderer.camDistance = $0 }
        
        addControl(label: "Rotação Manual", min: 0.0, max: 6.28, value: 0.0) {
            self.renderer.manualRotation = $0
            if self.renderer.autoRotationEnabled {
                self.renderer.autoRotationEnabled = false
            }
        }
        
        let autoRotCheckbox = NSButton(checkboxWithTitle: "Rotação Automática", target: self, action: #selector(toggleAutoRotation(_:)))
        autoRotCheckbox.state = .on
        stackView.addArrangedSubview(autoRotCheckbox)
    }
    
    private func addControl(label: String, min: Double, max: Double, value: Float, action: @escaping (Float) -> Void) {
        let titleField = NSTextField(labelWithString: label)
        titleField.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        titleField.textColor = .white
        titleField.backgroundColor = .clear
        titleField.isBezeled = false
        titleField.isEditable = false
        
        let slider = NSSlider(value: Double(value), minValue: min, maxValue: max, target: self, action: #selector(sliderMoved(_:)))
        slider.controlSize = .small
        slider.isContinuous = true
        
        let controlWrapper = ControlWrapper(action: action)
        
        objc_setAssociatedObject(slider, &sliderActionKey, controlWrapper, .OBJC_ASSOCIATION_RETAIN)
        
        stackView.addArrangedSubview(titleField)
        stackView.addArrangedSubview(slider)
    }

    @objc func toggleAutoRotation(_ sender: NSButton) {
        renderer.autoRotationEnabled = (sender.state == .on)
    }
    
    @objc private func sliderMoved(_ sender: NSSlider) {
        if let wrapper = objc_getAssociatedObject(sender, &sliderActionKey) as? ControlWrapper {
            wrapper.action(sender.floatValue)
        }
    }
}

class ControlWrapper: NSObject {
    let action: (Float) -> Void
    init(action: @escaping (Float) -> Void) { self.action = action }
}

class FlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
