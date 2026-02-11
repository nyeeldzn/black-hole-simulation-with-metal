import MetalKit

struct Uniforms {
    // Bloco 1
    var time: Float
    var angle: Float
    var nearStarsDensity: Float
    var distantStarsDensity: Float
    
    // Bloco 2
    var nebulaIntensity: Float
    var rs: Float
    var dt: Float
    var accelerationFactor: Float
    
    // Bloco 3
    var diskInnerLimit: Float
    var diskOuterLimit: Float
    var dopplerIntensity: Float
    var flowFrequency: Float
    
    var cameraDistance: Float
    var cameraRotation: Float
    var isAutoRotation: Float
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineStatus: MTLComputePipelineState!
    
    var time: Float = 0.0
    var angle: Float = 0.0
    var nearStarsDensity: Float = 0.98
    var distantStarsDensity: Float = 0.95
    var nebulaIntensity: Float = 1.0
    var rsValue: Float = 1.0
    var deltaTime: Float = 0.1
    var gravityFactor: Float = -1.5
    var diskInner: Float = 2.6
    var diskOuter: Float = 8.5
    var dopplerFactor: Float = 0.75
    var flowFreq: Float = 10.0
    
    var camDistance: Float = 30.0
    var manualRotation: Float = 0.0
    var autoRotationEnabled: Bool = true

    init?(metalView: MTKView) {
        self.device = metalView.device!
        self.commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        let library = device.makeDefaultLibrary()
        guard let function = library?.makeFunction(name: "blackHoleCompute") else { return nil }
        
        do {
            pipelineStatus = try device.makeComputePipelineState(function: function)
        } catch {
            fatalError("Erro ao criar o pipeline: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        time += 1.0 / 60.0
        angle += 0.002
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(pipelineStatus)
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        var uniforms = Uniforms(
            time: time,
            angle: angle,
            nearStarsDensity: nearStarsDensity,
            distantStarsDensity: distantStarsDensity,
            nebulaIntensity: nebulaIntensity,
            rs: rsValue,
            dt: deltaTime,
            accelerationFactor: gravityFactor,
            diskInnerLimit: diskInner,
            diskOuterLimit: diskOuter,
            dopplerIntensity: dopplerFactor,
            flowFrequency: flowFreq,
            cameraDistance: camDistance,
            cameraRotation: manualRotation,
            isAutoRotation: autoRotationEnabled ? 1.0 : 0.0
        )
        
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        
        let w = pipelineStatus.threadExecutionWidth
        let h = pipelineStatus.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)

        let threadsPerGrid = MTLSize(width: Int(view.drawableSize.width),
                                     height: Int(view.drawableSize.height),
                                     depth: 1)
        
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
