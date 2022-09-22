package com.google.android.apps.location.rtt.nanrttlib;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.aware.AttachCallback;
import android.net.wifi.aware.DiscoverySessionCallback;
import android.net.wifi.aware.PeerHandle;
import android.net.wifi.aware.PublishConfig;
import android.net.wifi.aware.PublishDiscoverySession;
import android.net.wifi.aware.SubscribeConfig;
import android.net.wifi.aware.SubscribeDiscoverySession;
import android.net.wifi.aware.WifiAwareManager;
import android.net.wifi.aware.WifiAwareSession;
import android.os.Handler;
import android.util.Log;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;

public class NanClient {
    public static final int PUBLISH_MODE = 0;
    public static final int SUBSCRIBE_MODE = 1;
    /* access modifiers changed from: private */
    public static final String TAG = NanClient.class.getSimpleName();
    private static final Pattern VALID_SERVICE_PATTERN = Pattern.compile("^[A-Za-z0-9.-]*$");
    /* access modifiers changed from: private */
    public final HashMap<String, PublishDiscoverySession> activePublishSessions = new HashMap<>();
    /* access modifiers changed from: private */
    public final HashMap<String, SubscribeDiscoverySession> activeSubscribeSessions = new HashMap<>();
    private final Context context;
    private boolean detachedAwareSession;
    private final Handler handler;
    private final NanClientCallback nanClientCallback;
    /* access modifiers changed from: private */
    public final HashMap<String, PublishConfig> publishConfigurations = new HashMap<>();
    /* access modifiers changed from: private */
    public final HashMap<String, SubscribeConfig> subscribeConfigurations = new HashMap<>();
    /* access modifiers changed from: private */
    public final WifiAwareManager wifiAwareManager;
    /* access modifiers changed from: private */
    public WifiAwareSession wifiAwareSession;

    public @interface OperatingMode {
    }

    public NanClient(Context context2, Handler handler2, NanClientCallback callback) {
        this.context = context2;
        this.handler = handler2;
        this.nanClientCallback = callback;
        this.wifiAwareManager = (WifiAwareManager) context2.getSystemService(Context.WIFI_AWARE_SERVICE);
        registerBroadcastReceiver(callback);
    }

    public void publishService(String service, NanPublisherCallback callback, PublishConfig config) {
        if (isValidServiceName(service)) {
            if (config != null) {
                this.publishConfigurations.put(service, config);
            } else {
                this.publishConfigurations.put(service, new PublishConfig.Builder().setServiceName(service).setRangingEnabled(false).build());
            }
            attachSession(0, service, callback);
            return;
        }
        callback.onInvalidService();
    }

    public void subscribeService(String service, NanSubscriberCallback callback, SubscribeConfig config) {
        if (isValidServiceName(service)) {
            if (config != null) {
                this.subscribeConfigurations.put(service, config);
            } else {
                this.subscribeConfigurations.put(service, new SubscribeConfig.Builder().setServiceName(service).build());
            }
            attachSession(1, service, callback);
            return;
        }
        callback.onInvalidService();
    }

    private void attachSession(final int mode, final String service, final NanClientCallback callback) {
        if (!this.wifiAwareManager.isAvailable()) {
            callback.onNanUnavailable();
        } else if (this.wifiAwareSession == null || this.detachedAwareSession) {
            this.wifiAwareManager.attach(new AttachCallback() {
                public void onAttached(WifiAwareSession session) {
                    super.onAttached(session);
                    Log.d(NanClient.TAG, "WiFi aware session attached");
                    WifiAwareSession unused = NanClient.this.wifiAwareSession = session;
                    switch (mode) {
                        case 0:
                            NanClient.this.buildPublishSession(service, (NanPublisherCallback) callback);
                            return;
                        case 1:
                            NanClient.this.buildSubscribeSession(service, (NanSubscriberCallback) callback);
                            return;
                        default:
                            return;
                    }
                }

                public void onAttachFailed() {
                    super.onAttachFailed();
                    Log.e(NanClient.TAG, "Attach failed");
                    callback.onAttachedFailed();
                }
            }, this.handler);
            this.detachedAwareSession = false;
        } else {
            switch (mode) {
                case 0:
                    buildPublishSession(service, (NanPublisherCallback) callback);
                    return;
                case 1:
                    buildSubscribeSession(service, (NanSubscriberCallback) callback);
                    return;
                default:
                    return;
            }
        }
    }

    /* access modifiers changed from: private */
    public void buildPublishSession(final String service, final NanPublisherCallback callback) {
        this.wifiAwareSession.publish(this.publishConfigurations.get(service), new DiscoverySessionCallback() {
            PublishDiscoverySession publishDiscoverySession;

            public void onPublishStarted(PublishDiscoverySession session) {
                super.onPublishStarted(session);
                this.publishDiscoverySession = session;
                NanClient.this.addPublishedService(session, service);
                callback.onPublishStarted(service);
            }

            public void onMessageReceived(PeerHandle peerhandle, byte[] message) {
                super.onMessageReceived(peerhandle, message);
                callback.onMessagedReceived(0, service, peerhandle, message);
                Log.d(NanClient.TAG, "Received message");
            }

            public void onMessageSendSucceeded(int messageId) {
                Log.d(NanClient.TAG, "onMessageSendSucceeded");
                callback.onMessageSendSucceeded(0, service, messageId);
            }

            public void onMessageSendFailed(int messageId) {
                Log.e(NanClient.TAG, "onMessageSendFailed");
                callback.onMessageSendFailed(0, service, messageId);
            }

            public void onSessionTerminated() {
                synchronized (NanClient.this) {
                    NanClient.this.activePublishSessions.remove(service);
                    NanClient.this.publishConfigurations.remove(service);
                }
                callback.onSessionTerminated(0, service);
                Log.d(NanClient.TAG, "Publish session terminated");
            }
        }, this.handler);
    }

    /* access modifiers changed from: private */
    public void buildSubscribeSession(final String service, final NanSubscriberCallback callback) {
        this.wifiAwareSession.subscribe(this.subscribeConfigurations.get(service), new DiscoverySessionCallback() {
            SubscribeDiscoverySession subscribeDiscoverySession;

            public void onSubscribeStarted(SubscribeDiscoverySession session) {
                this.subscribeDiscoverySession = session;
                NanClient.this.addSubscribedService(service, session);
                callback.onSubscribeStarted(service);
            }

            public void onServiceDiscovered(PeerHandle peerHandle, byte[] serviceSpecificInfo, List<byte[]> matchFilter) {
                String access$000 = NanClient.TAG;
                String str = service;
                Log.d(access$000, new StringBuilder(String.valueOf(str).length() + 28).append(str).append(":Discovered peer ").append(peerHandle.hashCode()).toString());
                callback.onServiceDiscovered(service, peerHandle, serviceSpecificInfo, matchFilter);
            }

            public void onSessionTerminated() {
                String access$000 = NanClient.TAG;
                String valueOf = String.valueOf(service);
                Log.d(access$000, valueOf.length() != 0 ? "Subscribe session terminated for".concat(valueOf) : new String("Subscribe session terminated for"));
                synchronized (NanClient.this) {
                    NanClient.this.activeSubscribeSessions.remove(service);
                    NanClient.this.subscribeConfigurations.remove(service);
                }
                callback.onSessionTerminated(1, service);
            }

            public void onMessageSendSucceeded(int messageId) {
                String access$000 = NanClient.TAG;
                String valueOf = String.valueOf(service);
                Log.d(access$000, valueOf.length() != 0 ? "onMessageSendSucceeded for ".concat(valueOf) : new String("onMessageSendSucceeded for "));
                callback.onMessageSendSucceeded(1, service, messageId);
            }

            public void onMessageSendFailed(int messageId) {
                String access$000 = NanClient.TAG;
                String valueOf = String.valueOf(service);
                Log.e(access$000, valueOf.length() != 0 ? "onMessageSendFailed for ".concat(valueOf) : new String("onMessageSendFailed for "));
                callback.onMessageSendFailed(1, service, messageId);
            }

            public void onMessageReceived(PeerHandle peerHandle, byte[] message) {
                Log.d(NanClient.TAG, new StringBuilder(39).append("onMessageReceived from peer ").append(peerHandle.hashCode()).toString());
                callback.onMessagedReceived(1, service, peerHandle, message);
            }
        }, this.handler);
    }

    public void sendMessage(int mode, String service, PeerHandle peerHandle, int messageId, byte[] message) {
        switch (mode) {
            case 0:
                synchronized (this) {
                    if (this.activePublishSessions.containsKey(service)) {
                        this.activePublishSessions.get(service).sendMessage(peerHandle, messageId, message);
                    }
                }
                return;
            case 1:
                synchronized (this) {
                    if (this.activeSubscribeSessions.containsKey(service)) {
                        this.activeSubscribeSessions.get(service).sendMessage(peerHandle, messageId, message);
                    }
                }
                return;
            default:
                return;
        }
    }

    public void enableRangingForPublishedService(String service, NanPublisherCallback callback) {
        updatePublishConfig(service, new PublishConfig.Builder().setServiceName(service).setRangingEnabled(true).build());
        callback.onRangingEnabled(service);
    }

    public void disableRangingForPublishedService(String service, NanPublisherCallback callback) {
        updatePublishConfig(service, new PublishConfig.Builder().setServiceName(service).setRangingEnabled(false).build());
        callback.onRangingDisabled(service);
    }

    /* access modifiers changed from: private */
    public void addPublishedService(PublishDiscoverySession publishDiscoverySession, String service) {
        synchronized (this) {
            this.activePublishSessions.putIfAbsent(service, publishDiscoverySession);
        }
    }

    public ArrayList<String> getPublishedServices() {
        ArrayList<String> arrayList;
        synchronized (this) {
            arrayList = new ArrayList<>(this.activePublishSessions.keySet());
        }
        return arrayList;
    }

    public ArrayList<String> getSubscribedServices() {
        ArrayList<String> arrayList;
        synchronized (this) {
            arrayList = new ArrayList<>(this.activeSubscribeSessions.keySet());
        }
        return arrayList;
    }

    public void updatePublishConfig(String service, PublishConfig config) {
        synchronized (this) {
            if (this.activePublishSessions.containsKey(service)) {
                this.activePublishSessions.get(service).updatePublish(config);
            }
        }
    }

    public void updateSubscribeConfig(String service, SubscribeConfig config) {
        synchronized (this) {
            if (this.activeSubscribeSessions.containsKey(service)) {
                this.activeSubscribeSessions.get(service).updateSubscribe(config);
            }
        }
    }

    public void addSubscribedService(String service, SubscribeDiscoverySession subscribeDiscoverySession) {
        synchronized (this) {
            if (!this.activeSubscribeSessions.containsKey(service)) {
                this.activeSubscribeSessions.put(service, subscribeDiscoverySession);
            }
        }
    }

    public void stopSession(int mode, String service, NanClientCallback callback) {
        WifiAwareSession wifiAwareSession2;
        synchronized (this) {
            switch (mode) {
                case 0:
                    if (this.activePublishSessions.containsKey(service)) {
                        this.activePublishSessions.get(service).close();
                        this.activePublishSessions.remove(service);
                        callback.onSessionTerminated(mode, service);
                        break;
                    }
                    break;
                case 1:
                    if (this.activeSubscribeSessions.containsKey(service)) {
                        this.activeSubscribeSessions.get(service).close();
                        this.activeSubscribeSessions.remove(service);
                        callback.onSessionTerminated(mode, service);
                        break;
                    }
                    break;
            }
            if (this.activePublishSessions.isEmpty() && this.activeSubscribeSessions.isEmpty() && (wifiAwareSession2 = this.wifiAwareSession) != null) {
                wifiAwareSession2.close();
                this.detachedAwareSession = true;
            }
        }
    }

    public void closeAllDiscoverySessions(int mode) {
        switch (mode) {
            case 0:
                synchronized (this) {
                    for (String service : this.activePublishSessions.keySet()) {
                        this.activePublishSessions.get(service).close();
                        this.nanClientCallback.onSessionTerminated(0, service);
                    }
                    this.activePublishSessions.clear();
                    if (this.activeSubscribeSessions.isEmpty()) {
                        closeWifiAwareSession();
                    }
                }
                return;
            case 1:
                synchronized (this) {
                    for (String service2 : this.activeSubscribeSessions.keySet()) {
                        this.activeSubscribeSessions.get(service2).close();
                        this.nanClientCallback.onSessionTerminated(1, service2);
                    }
                    this.activeSubscribeSessions.clear();
                    if (this.activePublishSessions.isEmpty()) {
                        closeWifiAwareSession();
                    }
                }
                return;
            default:
                return;
        }
    }

    public void closeAllSessions() {
        closeAllDiscoverySessions(0);
        closeAllDiscoverySessions(1);
    }

    public static boolean isValidServiceName(String service) {
        return VALID_SERVICE_PATTERN.matcher(service).matches();
    }

    /* access modifiers changed from: package-private */
    public boolean awareSessionDetached() {
        return this.detachedAwareSession;
    }

    private void registerBroadcastReceiver(final NanClientCallback callback) {
        IntentFilter filter = new IntentFilter("android.net.wifi.aware.action.WIFI_AWARE_STATE_CHANGED");
        this.context.getApplicationContext().registerReceiver(new BroadcastReceiver() {
            public void onReceive(Context context, Intent intent) {
                if (NanClient.this.wifiAwareManager.isAvailable()) {
                    callback.onNanAvailable();
                    return;
                }
                NanClient.this.closeAllSessions();
                callback.onNanUnavailable();
            }
        }, filter);
    }

    private void closeWifiAwareSession() {
        WifiAwareSession wifiAwareSession2 = this.wifiAwareSession;
        if (wifiAwareSession2 != null) {
            wifiAwareSession2.close();
            this.detachedAwareSession = true;
        }
    }

    /* access modifiers changed from: package-private */
    public PublishConfig getPublishConfig(String service) {
        return this.publishConfigurations.get(service);
    }

    /* access modifiers changed from: package-private */
    public SubscribeConfig getSubscribeConfig(String service) {
        if (this.subscribeConfigurations.containsKey(service)) {
            return this.subscribeConfigurations.get(service);
        }
        return null;
    }
}
