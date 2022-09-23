package com.google.android.apps.location.rtt.nanrttlib;

import android.net.wifi.aware.PeerHandle;
import java.time.Instant;

public class NanDeviceModel {
    public final String deviceName;
    private Instant lastCheckIn = null;
    public final PeerHandle peerHandle;
    public final String service;

    public Double x = 0.0;
    public Double y = 0.0;
    public Integer distance = -1;

    public NanDeviceModel(String deviceName2, PeerHandle peerHandle2, String service2) {
        this.deviceName = deviceName2;
        this.peerHandle = peerHandle2;
        this.service = service2;
    }

    public void setLastCheckIn(Instant instant) {
        this.lastCheckIn = instant;
    }

    public Instant getLastCheckIn() {
        Instant instant = this.lastCheckIn;
        instant.getClass();
        return instant;
    }
}
