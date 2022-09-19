package com.microsoft.arwalking.android

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.publish).setOnClickListener {
            val intent = Intent(this, RttLocationService::class.java)
            intent.action = RttLocationService.ACTION_START_PUBLISH

            startForegroundService(intent)
        }

        findViewById<Button>(R.id.subscribe).setOnClickListener {
            val intent = Intent(this, RttLocationService::class.java)
            intent.action = RttLocationService.ACTION_START_SUBSCRIBE

            startForegroundService(intent)
        }

        findViewById<Button>(R.id.stop).setOnClickListener {
            val intent = Intent(this, RttLocationService::class.java)
            intent.action = RttLocationService.ACTION_STOP

            startForegroundService(intent)
        }
    }

}