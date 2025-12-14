package com.example.chat1plus.model;

public class ChatMessage {
    private String sender;
    private String receiver; // "all" 或 具体用户名
    private String content;
    private long timestamp;
    private String type;     // "system", "public", "private"

    public ChatMessage(String sender, String receiver, String content, long timestamp, String type) {
        this.sender = sender;
        this.receiver = receiver;
        this.content = content;
        this.timestamp = timestamp;
        this.type = type;
    }

    public String getSender() { return sender; }
    public String getReceiver() { return receiver; }
    public String getContent() { return content; }
    public long getTimestamp() { return timestamp; }
    public String getType() { return type; }
}