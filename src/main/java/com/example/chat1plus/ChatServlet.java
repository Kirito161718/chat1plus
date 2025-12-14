package com.example.chat1plus;

import com.example.chat1plus.model.ChatMessage;
import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

@WebServlet("/chat/*")
public class ChatServlet extends HttpServlet {

    // ... (getGlobalMessages, getGlobalUsers 方法保持不变，这里省略以节省篇幅，请保留原有的) ...
    // ... (务必保留原来的 getGlobalMessages 和 getGlobalUsers 方法) ...

    // 为了完整性，我把辅助方法再写一遍，防止你漏掉
    private List<ChatMessage> getGlobalMessages() {
        ServletContext context = getServletContext();
        if (context.getAttribute("messages") == null) {
            context.setAttribute("messages", new CopyOnWriteArrayList<ChatMessage>());
        }
        return (List<ChatMessage>) context.getAttribute("messages");
    }

    private List<String> getGlobalUsers() {
        ServletContext context = getServletContext();
        if (context.getAttribute("onlineUsers") == null) {
            context.setAttribute("onlineUsers", new CopyOnWriteArrayList<String>());
        }
        return (List<String>) context.getAttribute("onlineUsers");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String path = request.getPathInfo();
        PrintWriter out = response.getWriter();

        if ("/login".equals(path)) handleLogin(request, out);
        else if ("/send".equals(path)) handleSendMessage(request, out); // 修改了这个
        else if ("/logout".equals(path)) handleLogout(request, out);
        else sendError(out, "Invalid path");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if ("/messages".equals(request.getPathInfo())) {
            handleGetMessages(request, response.getWriter());
        }
    }

    // handleLogin 保持不变
    private void handleLogin(HttpServletRequest request, PrintWriter out) {
        String username = request.getParameter("username");
        if (username == null || username.trim().isEmpty()) {
            sendError(out, "用户名不能为空");
            return;
        }
        username = username.trim();

        if (getGlobalUsers().contains(username)) {
            sendError(out, "用户名已存在");
            return;
        }

        HttpSession session = request.getSession();
        session.setMaxInactiveInterval(600); // 10分钟超时
        session.setAttribute("username", username);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("username", username);
        out.print(toJson(res));
    }

    // ★★★ 修改后的发送逻辑：支持显式指定接收者 ★★★
    private void handleSendMessage(HttpServletRequest request, PrintWriter out) {
        HttpSession session = request.getSession(false);
        String sender = (String) session.getAttribute("username");
        String content = request.getParameter("content");
        // 获取前端传来的接收者参数，如果没有则为null
        String explicitReceiver = request.getParameter("receiver");

        if (content != null && !content.trim().isEmpty()) {
            content = content.trim();
            String receiver = "all";
            String type = "public";

            if (explicitReceiver != null && !explicitReceiver.isEmpty() && !"all".equals(explicitReceiver)) {
                // 情况1: 前端明确指定了私聊对象 (在私聊页面发送)
                receiver = explicitReceiver;
                type = "private";
            } else if (content.startsWith("@") && content.contains(" ")) {
                // 情况2: 用户在大厅手动输入 "@User 消息" (保留旧功能)
                int spaceIndex = content.indexOf(" ");
                receiver = content.substring(1, spaceIndex);
                content = content.substring(spaceIndex + 1);
                type = "private";
            }

            ChatMessage msg = new ChatMessage(sender, receiver, content, System.currentTimeMillis(), type);
            List<ChatMessage> msgs = getGlobalMessages();
            msgs.add(msg);
            if (msgs.size() > 1000) msgs.remove(0);
        }
        out.print("{\"success\":true}");
    }

    // handleGetMessages 保持不变
    private void handleGetMessages(HttpServletRequest request, PrintWriter out) {
        HttpSession session = request.getSession(false);
        String currentUser = (String) session.getAttribute("username");

        long lastTime = 0;
        try { lastTime = Long.parseLong(request.getParameter("lastTime")); } catch (Exception e) {}

        List<ChatMessage> allMessages = getGlobalMessages();
        List<Map<String, Object>> resultList = new ArrayList<>();

        for (ChatMessage msg : allMessages) {
            if (msg.getTimestamp() <= lastTime) continue;

            boolean isSystem = "system".equals(msg.getType());
            boolean isPublic = "public".equals(msg.getType()) || "all".equals(msg.getReceiver());
            // 只要你是发送者 或者 你是接收者，你就能拿到这条私聊消息
            // 前端负责决定把它显示在大厅还是私聊窗口
            boolean isMine = "private".equals(msg.getType()) &&
                    (currentUser.equals(msg.getSender()) || currentUser.equals(msg.getReceiver()));

            if (isSystem || isPublic || isMine) {
                Map<String, Object> m = new HashMap<>();
                m.put("sender", msg.getSender());
                m.put("content", msg.getContent());
                m.put("timestamp", msg.getTimestamp());
                m.put("type", msg.getType());
                m.put("receiver", msg.getReceiver());
                resultList.add(m);
            }
        }

        long newLastTime = lastTime;
        if (!allMessages.isEmpty()) newLastTime = allMessages.get(allMessages.size() - 1).getTimestamp();

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("messages", resultList);
        res.put("lastTime", newLastTime);
        res.put("users", getGlobalUsers());
        out.print(toJson(res));
    }

    // handleLogout, sendError, toJson, listToJson, escapeJson 等辅助方法保持不变
    // 请确保包含它们...
    private void handleLogout(HttpServletRequest request, PrintWriter out) {
        HttpSession session = request.getSession(false);
        if (session != null) session.invalidate();
        out.print("{\"success\":true}");
    }

    private void sendError(PrintWriter out, String msg) {
        out.print("{\"success\":false, \"message\":\"" + escapeJson(msg) + "\"}");
    }

    private String toJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean f = true;
        for (Map.Entry<String, Object> e : map.entrySet()) {
            if (!f) sb.append(","); f = false;
            sb.append("\"").append(e.getKey()).append("\":");
            if (e.getValue() instanceof String) sb.append("\"").append(escapeJson((String)e.getValue())).append("\"");
            else if (e.getValue() instanceof List) sb.append(listToJson((List)e.getValue()));
            else sb.append(e.getValue());
        }
        sb.append("}");
        return sb.toString();
    }

    private String listToJson(List list) {
        StringBuilder sb = new StringBuilder("[");
        boolean f = true;
        for (Object o : list) {
            if (!f) sb.append(","); f = false;
            if (o instanceof Map) sb.append(toJson((Map)o));
            else if (o instanceof String) sb.append("\"").append(escapeJson((String)o)).append("\"");
            else sb.append(o);
        }
        sb.append("]");
        return sb.toString();
    }

    private String escapeJson(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}