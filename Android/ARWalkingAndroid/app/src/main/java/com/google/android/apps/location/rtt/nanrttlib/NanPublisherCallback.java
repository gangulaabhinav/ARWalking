package com.google.android.apps.location.rtt.nanrttlib;

public interface NanPublisherCallback extends NanClientCallback {
    void onPublishStarted(String str);

    void onRangingDisabled(String str);

    void onRangingEnabled(String str);
}
