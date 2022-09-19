package com.microsoft.arwalking.android

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat

class SettingsFragment : PreferenceFragmentCompat() {

    private val mRequestPermissionsLauncher = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()) { isGranted: Map<String, Boolean> ->
    }

    fun hasLocationPermissions(): Boolean {
        return context?.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && context?.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    fun hasBackgroundLocationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
                || context?.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.root_preferences, rootKey)

        findPreference<Preference>("permissions")?.apply {
            setOnPreferenceClickListener {
                if (!hasLocationPermissions()) {
                    mRequestPermissionsLauncher.launch(arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                    ))
                }
                else if (!hasBackgroundLocationPermission()) {
                    mRequestPermissionsLauncher.launch(arrayOf(
                            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                    ))
                }
                else {
                    AlertDialog.Builder(context).apply {
                        setMessage(
                                "All required permissions are already granted. Nothing to do."
                        )
                        setPositiveButton("Okay") { _, _ ->
                            // Do nothing
                        }
                        show()
                    }
                }
                true
            }
        }
    }
}