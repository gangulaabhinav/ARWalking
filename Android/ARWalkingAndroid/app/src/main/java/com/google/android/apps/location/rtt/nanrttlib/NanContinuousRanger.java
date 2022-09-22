package com.google.android.apps.location.rtt.nanrttlib;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.wifi.aware.PeerHandle;
import android.net.wifi.rtt.RangingRequest;
import android.net.wifi.rtt.RangingResult;
import android.net.wifi.rtt.RangingResultCallback;
import android.net.wifi.rtt.WifiRttManager;
import android.os.Handler;
import android.os.PowerManager;
import android.util.Log;
import java.util.List;
import java.util.concurrent.Executor;

public class NanContinuousRanger {
    /* access modifiers changed from: private */
    public static final String TAG = NanContinuousRanger.class.getSimpleName();
    private final Executor executor;
    /* access modifiers changed from: private */
    public final Handler handler;
    private final Handler rangeRequestHandler;
    private boolean ranging;
    /* access modifiers changed from: private */
    public int rangingPeriod;
    private final WifiRttManager rttManager;
    private final PowerManager.WakeLock wakeLock;

    public NanContinuousRanger(Context context, int rangingPeriod2, Handler handler2) {
        this.handler = handler2;
        Handler handler3 = new Handler();
        this.rangeRequestHandler = handler3;
        this.executor = handler3::post;
        this.rangingPeriod = rangingPeriod2;
        this.rttManager = (WifiRttManager) context.getSystemService(WifiRttManager.class);
        this.wakeLock = ((PowerManager) context.getSystemService(PowerManager.class)).newWakeLock(1, "NanSubscriberRanging::Wakelock");
    }

    public void rangePeer(NanContinuousRangerCallback callback) {
        this.wakeLock.acquire();
        loopRanging(callback);
    }

    private RangingRequest createRequest(List<PeerHandle> peerHandles) {
        RangingRequest.Builder requestBuilder = new RangingRequest.Builder();

        for (PeerHandle peerHandle: peerHandles) {
            requestBuilder.addWifiAwarePeer(peerHandle);
        }

        return requestBuilder.build();
    }

    /* access modifiers changed from: private */
    @SuppressLint("MissingPermission")
    public void loopRanging(final NanContinuousRangerCallback callback) {
        this.ranging = true;

        List<PeerHandle> peerHandles = callback.getPeerHandles();

        if (peerHandles.size() <= 0) {
            NanContinuousRanger.this.handler.postDelayed(() -> NanContinuousRanger.this.loopRanging(callback), (long) NanContinuousRanger.this.rangingPeriod);
            return;
        }

        RangingRequest request = createRequest(peerHandles);

        this.rttManager.startRanging(request, this.executor, new RangingResultCallback() {
            public void onRangingFailure(int code) {
                callback.onRangingFailure(code);
                if (NanContinuousRanger.this.isRanging()) {
                    Log.e(NanContinuousRanger.TAG, new StringBuilder(44).append("Ranging failed with return code: ").append(code).toString());
                    NanContinuousRanger.this.handler.postDelayed(() -> NanContinuousRanger.this.loopRanging(callback), (long) NanContinuousRanger.this.rangingPeriod);
                }
            }

            public void onRangingResults(List<RangingResult> results) {
                if (!results.isEmpty()) {
                    callback.onRangingResults(results);
                    Log.d(NanContinuousRanger.TAG, new StringBuilder(34).append("Ranging result status: ").append(results.get(0).getStatus()).toString());
                } else {
                    Log.e(NanContinuousRanger.TAG, "Results is empty");
                }
                if (NanContinuousRanger.this.isRanging()) {
                    NanContinuousRanger.this.handler.postDelayed(() -> NanContinuousRanger.this.loopRanging(callback), (long) NanContinuousRanger.this.rangingPeriod);
                }
            }
        });
    }

    public void setRangingPeriod(int rangingPeriodMillis) {
        this.rangingPeriod = rangingPeriodMillis;
    }

    public boolean isRanging() {
        return this.ranging;
    }

    public void stopRanging() {
        Handler handler2 = this.handler;
        if (handler2 != null) {
            handler2.removeCallbacksAndMessages((Object) null);
            this.rangeRequestHandler.removeCallbacksAndMessages((Object) null);
            this.ranging = false;
        }
        if (this.wakeLock.isHeld()) {
            this.wakeLock.release();
        }
    }
}
