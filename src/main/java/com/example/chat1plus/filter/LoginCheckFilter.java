package com.example.chat1plus.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/chat/*")
public class LoginCheckFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) resp;

        // 统一编码设置
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");

        String path = request.getPathInfo();

        // 放行登录接口
        if (path != null && (path.equals("/login") || path.equals("/"))) {
            chain.doFilter(req, resp);
            return;
        }

        // 检查 Session
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            // 前端是 fetch 请求，返回 JSON 错误信息
            response.getWriter().write("{\"success\":false, \"message\":\"未登录，请刷新页面\"}");
            return;
        }

        chain.doFilter(req, resp);
    }
}