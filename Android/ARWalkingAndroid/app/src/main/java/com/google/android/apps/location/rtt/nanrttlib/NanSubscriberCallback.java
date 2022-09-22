package com.google.android.apps.location.rtt.nanrttlib;

import android.net.wifi.aware.PeerHandle;
import java.util.List;

public interface NanSubscriberCallback extends NanClientCallback {
    void onServiceDiscovered(String str, PeerHandle peerHandle, byte[] bArr, List<byte[]> list);

    void onSubscribeStarted(String str);
}
