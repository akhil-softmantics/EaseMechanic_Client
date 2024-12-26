// MainActivity.kt
package com.example.ease
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pdf_renderer"
    private var currentRenderer: PdfRenderer? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeRenderer" -> {
                    try {
                        // Clean up any existing renderer
                        currentRenderer?.close()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", "Failed to initialize renderer", e.message)
                    }
                }
                "openDocument" -> {
                    try {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_PATH", "Path cannot be null", null)
                            return@setMethodCallHandler
                        }
                        
                        // Close existing renderer if any
                        currentRenderer?.close()
                        
                        // Open the PDF file
                        val file = File(path)
                        val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                        currentRenderer = PdfRenderer(fileDescriptor)
                        
                        result.success(mapOf(
                            "pageCount" to currentRenderer?.pageCount,
                            "path" to path
                        ))
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", "Failed to open document", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        currentRenderer?.close()
        super.onDestroy()
    }
}