package com.google.android.apps.location.rtt.nanrttlib;

import java.nio.charset.StandardCharsets;
import java.time.Duration;

public class Message {
    public static final int CHAT_MESSAGE = 3;
    private static final String DELIMITER = "|";
    public static final int NAME_REQUEST_ACK_MESSAGE = 11;
    public static final int NAME_REQUEST_MESSAGE = 1;
    public static final int PING_ACK_MESSAGE = 22;
    public static final Duration PING_DELAY = Duration.ofSeconds(10);
    public static final int PING_MESSAGE = 2;
    private static final String SPLIT_REGEX = "[|]";
    public static final Duration TIMEOUT = Duration.ofSeconds(30);
    public final String deviceName;
    public final String message;
    public final int requestType;

    private @interface RequestType {
    }

    public Message(String deviceName2, int requestType2, String message2) {
        this.deviceName = deviceName2;
        this.requestType = requestType2;
        this.message = message2;
    }

    public byte[] toBytes() {
        return String.join(DELIMITER, new CharSequence[]{this.deviceName, String.valueOf(this.requestType), this.message}).getBytes(StandardCharsets.UTF_8);
    }

    public static Message fromBytes(byte[] message2) {
        String[] delimitedMessage = new String(message2, StandardCharsets.UTF_8).split(SPLIT_REGEX, -1);
        return new Message(delimitedMessage[0], Integer.parseInt(delimitedMessage[1]), delimitedMessage[2]);
    }
}
