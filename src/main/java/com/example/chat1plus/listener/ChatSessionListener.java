package com.example.chat1plus.listener;

import com.example.chat1plus.model.ChatMessage;
import jakarta.servlet.ServletContext;
import jakarta.servlet.annotation.WebListener;
import jakarta.servlet.http.HttpSessionAttributeListener;
import jakarta.servlet.http.HttpSessionBindingEvent;
import jakarta.servlet.http.HttpSessionEvent;
import jakarta.servlet.http.HttpSessionListener;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@WebListener
public class ChatSessionListener implements HttpSessionListener, HttpSessionAttributeListener {

    // 初始化 Application 域中的数据
    private void initData(ServletContext context) {
        if (context.getAttribute("onlineUsers") == null) {
            context.setAttribute("onlineUsers", new CopyOnWriteArrayList<String>());
        }
        if (context.getAttribute("messages") == null) {
            context.setAttribute("messages", new CopyOnWriteArrayList<ChatMessage>());
        }
    }

    // 监听 Session 属性添加 (登录: session.setAttribute("username", ...))
    @Override
    public void attributeAdded(HttpSessionBindingEvent event) {
        if ("username".equals(event.getName())) {
            String username = (String) event.getValue();
            ServletContext context = event.getSession().getServletContext();
            initData(context);

            List<String> users = (List<String>) context.getAttribute("onlineUsers");
            if (!users.contains(username)) {
                users.add(username);
                addSystemMessage(context, username + " 上线了");
            }
        }
    }

    // 监听 Session 销毁 (超时或退出: session.invalidate())
    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        String username = (String) se.getSession().getAttribute("username");
        if (username != null) {
            ServletContext context = se.getSession().getServletContext();
            initData(context); // 防止极端情况下 context 属性为空

            List<String> users = (List<String>) context.getAttribute("onlineUsers");
            users.remove(username);
            addSystemMessage(context, username + " 下线了 (或连接超时)");
        }
    }

    private void addSystemMessage(ServletContext context, String text) {
        List<ChatMessage> messages = (List<ChatMessage>) context.getAttribute("messages");
        messages.add(new ChatMessage("System", "all", text, System.currentTimeMillis(), "system"));
        if (messages.size() > 1000) messages.remove(0);
    }

    // 空实现
    @Override public void sessionCreated(HttpSessionEvent se) {}
    @Override public void attributeRemoved(HttpSessionBindingEvent event) {}
    @Override public void attributeReplaced(HttpSessionBindingEvent event) {}
}