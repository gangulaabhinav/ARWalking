package com.google.android.apps.location.rtt.nanrttlib;

import android.net.wifi.aware.PeerHandle;
import android.net.wifi.rtt.RangingResult;

import java.util.List;

public interface NanContinuousRangerCallback {
    List<PeerHandle> getPeerHandles();

    void onRangingFailure(int var1);

    void onRangingResults(List<RangingResult> var1);
}
