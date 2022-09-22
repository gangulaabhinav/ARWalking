package com.google.android.apps.location.rtt.nanrttlib;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.wifi.aware.PeerHandle;
import android.net.wifi.rtt.RangingRequest;
import android.net.wifi.rtt.RangingResult;
import android.net.wifi.rtt.RangingResultCallback;
import android.net.wifi.rtt.WifiRttManager;
import android.util.Log;
import java.util.List;
import java.util.concurrent.Executor;

public class NanSingleRanger {
    /* access modifiers changed from: private */
    public static final String TAG = NanSingleRanger.class.getSimpleName();
    private final Executor executor;
    private final WifiRttManager rttManager;

    public NanSingleRanger(Context context, Executor executor2) {
        this.executor = executor2;
        this.rttManager = (WifiRttManager) context.getSystemService(WifiRttManager.class);
    }

    @SuppressLint("MissingPermission")
    public void rangePeer(final PeerHandle peerHandle, final RangingResultCallback callback) {
        this.rttManager.startRanging(new RangingRequest.Builder().addWifiAwarePeer(peerHandle).build(), this.executor, new RangingResultCallback() {
            public void onRangingFailure(int reason) {
                Log.e(NanSingleRanger.TAG, new StringBuilder(44).append("Ranging failed with error code : ").append(reason).toString());
                callback.onRangingFailure(reason);
            }

            public void onRangingResults(List<RangingResult> list) {
                if (!list.isEmpty()) {
                    RangingResult result = list.get(0);
                    if (result.getStatus() == RangingResult.STATUS_SUCCESS) {
                        String access$000 = NanSingleRanger.TAG;
                        String valueOf = String.valueOf(peerHandle);
                        Log.d(access$000, new StringBuilder(String.valueOf(valueOf).length() + 22).append("Ranging successful to ").append(valueOf).toString());
                        callback.onRangingResults(list);
                    } else if (result.getStatus() == RangingResult.STATUS_FAIL) {
                        callback.onRangingFailure(RangingResultCallback.STATUS_CODE_FAIL);
                        String access$0002 = NanSingleRanger.TAG;
                        String valueOf2 = String.valueOf(peerHandle);
                        Log.e(access$0002, new StringBuilder(String.valueOf(valueOf2).length() + 18).append("Ranging failed to ").append(valueOf2).toString());
                    }
                }
            }
        });
    }
}
