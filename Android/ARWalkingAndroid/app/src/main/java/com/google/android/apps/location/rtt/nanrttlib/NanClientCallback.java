package com.google.android.apps.location.rtt.nanrttlib;

import android.net.wifi.aware.PeerHandle;

public interface NanClientCallback {
    void onAttachedFailed();

    void onInvalidService();

    void onMessageSendFailed(int i, String str, int i2);

    void onMessageSendSucceeded(int i, String str, int i2);

    void onMessagedReceived(int i, String str, PeerHandle peerHandle, byte[] bArr);

    void onNanAvailable();

    void onNanUnavailable();

    void onSessionTerminated(int i, String str);
}
