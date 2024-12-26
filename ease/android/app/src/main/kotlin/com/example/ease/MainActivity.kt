class MainActivity: FlutterActivity() {
    private val CHANNEL = "pdf_renderer"
    private var currentRenderer: PdfRenderer? = null
    private var currentFileDescriptor: ParcelFileDescriptor? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeRenderer" -> {
                    safeCloseRenderer()
                    result.success(null)
                }

                "closeRenderer" -> {
                    safeCloseRenderer()
                    result.success(null)
                }

                "openDocument" -> {
                    try {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_PATH", "Path cannot be null", null)
                            return@setMethodCallHandler
                        }
                        
                        safeCloseRenderer()
                        
                        val file = File(path)
                        currentFileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_WRITE)
                        currentRenderer = PdfRenderer(currentFileDescriptor!!)
                        
                        result.success(mapOf(
                            "pageCount" to currentRenderer?.pageCount,
                            "path" to path
                        ))
                    } catch (e: Exception) {
                        safeCloseRenderer()
                        result.error("OPEN_ERROR", "Failed to open document", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun safeCloseRenderer() {
        try {
            currentRenderer?.close()
            currentFileDescriptor?.close()
        } catch (e: Exception) {
            // Ignore close errors
        } finally {
            currentRenderer = null
            currentFileDescriptor = null
        }
    }
    
    override fun onDestroy() {
        safeCloseRenderer()
        super.onDestroy()
    }
}