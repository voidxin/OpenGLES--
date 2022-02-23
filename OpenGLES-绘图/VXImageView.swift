//
//  VXImageView.swift
//  OpenGLES-绘图
//
//  Created by zhangxin on 2022/2/23.
//
//Vertex Shader(顶点着色器)和Fragment Shader(片元着色器) 是可编程管线，可编程管线就是说这个操作可以动态编程而不必写死在代码中
import UIKit
import OpenGLES
import CoreGraphics

class VXImageView: UIView {

    private var mEaglLayer: CAEAGLLayer?
    private var mContext: EAGLContext?
    //一些id标记
    private var mColorRenderBuffer = GLuint()
    private var mColorFrameBuffer = GLuint()
    private var mprograme = GLuint()
    
    override class var layerClass: AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }

    /**绘图流程
     1.创建图层
     2.创建上下文
     3.清空缓存区
     4.设置RenderBuffer
     5.设置FrameBuffer
     6.开始绘制
     */
    override func layoutSubviews() {
        setupLayer()
        setupContext()
        deleteRenderAndFrameBuffer()
        setupRenderBuffer()
        setupFrameBuffer()
        renderLayer()
    }
    
    private func setupLayer() {
        mEaglLayer = self.layer as? CAEAGLLayer
        self.contentScaleFactor = UIScreen.main.scale
        //kEAGLDrawablePropertyRetainedBacking:绘图表面显示后，是否保留其内容
        //kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
        //kEAGLColorFormatRGB565：16位RGB的颜色，
        //kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
        mEaglLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false,
                                                                  kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]
    }
    
    private func setupContext() {
        //新建OpenGLES上下文
        let context = EAGLContext(api: EAGLRenderingAPI.openGLES3)
        //设置当前上下文
        EAGLContext.setCurrent(context)
        mContext = context
    }
    
    //清空缓存区
    private func deleteRenderAndFrameBuffer() {
        /*
         buffer分为frame buffer 和 render buffer2个大类。
         其中frame buffer 相当于render buffer的管理者。
         frame buffer object即称FBO。
         render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
         
         帧缓冲区（Frame Buffers） 帧缓冲区：这个是存储OpenGL 最终渲染输出结果的地方，它是一个包含多个图像的集合，例如颜色图像、深度图像、模板图像等。
         渲染缓冲区（Render Buffers） 渲染缓冲区：渲染缓冲区就是一个图像，它是 Frame Buffer 的一个子集。
         */
        
        glDeleteBuffers(1, &mColorRenderBuffer)
        mColorRenderBuffer = 0
        glDeleteBuffers(1, &mColorFrameBuffer)
        mColorFrameBuffer = 0
    }
    
    private func setupRenderBuffer() {
        //定义一个缓存区id
        var buffer = GLuint()
        //申请缓存区id
        glGenRenderbuffers(1, &buffer)
        mColorRenderBuffer = buffer
        
        //将id绑定到GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), mColorRenderBuffer)
        //绑定renderBuffer并为其分配存储空间
        //https://developer.apple.com/documentation/opengles/eaglcontext/1622262-renderbufferstorage
        mContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: mEaglLayer)
    }
    
    private func setupFrameBuffer() {
        var buffer = GLuint()
        glGenFramebuffers(1, &buffer)
        mColorFrameBuffer = buffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), mColorFrameBuffer)
       //生成帧缓存区之后，需要将renderbuffer跟framebuffer进行绑定,framebuffer用于管理renderbuffer
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), mColorRenderBuffer)
        
    }
    
    private func renderLayer() {
        glClearColor(0.9, 0.8, 0.5, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let scale = UIScreen.main.scale
        let frame = self.frame
        //设置视口
        glViewport(0, 0, GLsizei(frame.size.width * scale), GLsizei(frame.size.height * scale))

        //读取顶点、片元着色程序
        let verFile = Bundle.main.path(forResource: "shaderv", ofType: "vsh")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "fsh")
        
        //将着色程序绑定到program
        attachToProgram(with: verFile, fragFIle: fragFile)
        
        //链接
        glLinkProgram(mprograme)
        //获取链接状态
        var linkStatus : GLint = 0
        glGetProgramiv(mprograme, GLenum(GL_LINK_STATUS), &linkStatus)
   
        if linkStatus == GL_FALSE {
            var message = [GLchar]()
            glGetProgramInfoLog(mprograme, GLsizei(MemoryLayout<GLchar>.size * 512), nil, &message)
            let errorInfo = String(cString: message, encoding: .utf8)
            print(errorInfo)
            return
        }
        print("🍺🍻 link success")
        
        glUseProgram(mprograme)
        
        //坐标数据
        //顶点坐标转成纹理坐标
        //矩形的六个顶点
        let attrArr: [GLfloat] = [
//            1, -1, -1.0,     1.0, 0.0,
//            -1, 1, -1.0,     0.0, 1.0,
//            -1, -1, -1.0,    0.0, 0.0,
//
//            1, 1, -1.0,      1.0, 1.0,
//            -1, 1, -1.0,     0.0, 1.0,
//            1, -1, -1.0,     1.0, 0.0,
            1, -1, 0.0,     1.0, 0.0,  //右下
            1, 1, 0.0,     1.0, 1.0,  //右上
            -1, 1, 0.0,    0.0, 1.0, //左上
            
            1, -1, 0.0,      1.0, 0.0, //右下
            -1, 1, 0.0,     0.0, 1.0, //左上
            -1, -1, 0.0,     0.0, 0.0,  //左下
        ]
        
        //顶点数据处理
        var attrBuffer = GLuint()
        glGenBuffers(1, &attrBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        //由内存copy到显存
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * 30, attrArr, GLenum(GL_DYNAMIC_DRAW))
        
        //将顶点数据通过mPrograme传递到顶点着色程序的position
        
        //用来获取vertex attribute的入口.第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
        let position = glGetAttribLocation(mprograme, "position")
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(position))
        //设置读取方式
        //arg1：index,顶点数据的索引
        //arg2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //arg3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //arg4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //arg5：stride,连续顶点属性之间的偏移量，默认为0；
        //arg6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), nil)
        //处理纹理数据
        let textCoor = glGetAttribLocation(mprograme, "textCoordinate")
        glEnableVertexAttribArray(GLuint(textCoor))
    //此处bufferoffset取值应注意：https://stackoverflow.com/questions/56535272/whats-wrong-when-i-custom-an-imageview-by-opengles
        glVertexAttribPointer(GLuint(textCoor), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), BUFFER_OFFSET(MemoryLayout<GLfloat>.size * 3))
        
        loadTexture(with: "Demo.jpg")
        
        //设置纹理采样器 0张纹理
        glUniform1i(glGetUniformLocation(mprograme, "colorMap"), 0)
        //绘图 arg2:从数组缓存中的哪一位开始绘制，一般都定义为0
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        mContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    private func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
        return UnsafeRawPointer(bitPattern: i)
    }
    
    //从图片加载纹理
    private func loadTexture(with name: String) {
        
        guard let spriteImage = UIImage(named: name)?.cgImage else { return }
        let width = spriteImage.width
        let height = spriteImage.height
        //获取图片字节数: 宽*高*4（RGBA）
        let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
        
        //创建上下文
        //https://stackoverflow.com/questions/24109149/cgbitmapcontextcreate-error-with-swift
        /*
         arg1：data,指向要渲染的绘制图像的内存地址
         arg2：width,bitmap的宽度，单位为像素
         arg3：height,bitmap的高度，单位为像素
         arg4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
         arg5：bytesPerRow,bitmap的没一行的内存所占的比特数
         arg6: 颜色空间
         arg7：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
         */
        //bitmapInfo: https://blog.csdn.net/ccflying88/article/details/50753795
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        //图片翻转
        spriteContext?.translateBy(x: 0, y: CGFloat(height))
        spriteContext?.scaleBy(x: 1.0, y: -1.0)
        //在CGContextRef上绘制图片
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        spriteContext?.clear(rect)
        spriteContext?.draw(spriteImage, in: rect)
        
        //绑定纹理到默认id, 只有一个纹理取0
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        //设置纹理属性 过滤方式 环绕方式
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        //载入纹理数据
        /*
         arg1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
         arg2：加载的层次，一般设置为0
         arg3：纹理的颜色值GL_RGBA
         arg4：宽
         arg5：高
         arg6：border，边界宽度
         arg7：format
         arg8：type
         arg9：纹理数据
         */
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        free(spriteData)
        
    }
    
    private func attachToProgram(with verFile: String?, fragFIle: String?) {
        guard let verFile = verFile, let fragFIle = fragFIle else { return }
        var verShader = GLuint()
        var fragShader = GLuint()
        let program = glCreateProgram()
        compileshader(with: &verShader, type: GLenum(GL_VERTEX_SHADER), file: verFile)
        compileshader(with: &fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragFIle)
        
        glAttachShader(program, verShader)
        glAttachShader(program, fragShader)
        
        //绑定后不需要了要释放掉
        glDeleteShader(verShader)
        glDeleteShader(fragShader)
        
        mprograme = program
    }
    
    private func compileshader(with  shader: inout GLuint,
                               type: GLenum,
                               file: String) {
        
        let content = try? String(contentsOfFile: file, encoding: String.Encoding.utf8)
        let contentCString = content?.cString(using: .utf8)
        var source = UnsafePointer<GLchar>(contentCString)
        
        shader = glCreateShader(type)
        
        //将着色器源码附加到着色器对象上。
        //arg1：shader,要编译的着色器对象
        //arg2：numOfStrings,传递的源码字符串数量 1个
        //arg3：strings,着色器程序的源码（真正的着色器程序源码）
        //arg4：lenOfStrings,长度，具有每个字符串长度的数组，或nil，这意味着字符串是nil终止的
        glShaderSource(shader, 1,&source, nil)
        //把着色器源代码编译成目标代码
        glCompileShader(shader)
        
        var sucess = GLint()
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &sucess)
        if sucess == GL_FALSE {
            var message = [GLchar]()
            glGetShaderInfoLog(shader, GLsizei(MemoryLayout<GLchar>.size * 512), nil, &message)
            let errorInfo = String(cString: message, encoding: .utf8)
            print("shaderErrorInfo:" + (errorInfo ?? ""))
        }
    }

}
