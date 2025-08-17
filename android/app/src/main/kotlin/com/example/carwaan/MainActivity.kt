package com.example.carwaan

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Set the renderer ready before calling super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Enable predictive back gesture on Android 13+ (API 33+)
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }

        // Ensure hardware acceleration is enabled
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )

        super.onCreate(savedInstanceState)
    }

    override fun onResume() {
        super.onResume()
        // Removing access to private FlutterRenderer properties
        // that are causing compilation errors
    }
}
