# 🚀 Java Web 轻量级在线聊天室 (Servlet + JSP)

这是一个基于 Java EE (Jakarta EE) 标准开发的 Web 聊天室应用。项目不依赖任何重型框架（如 Spring），采用原生的 **Servlet + JSP** 技术栈，配合 **AJAX 轮询** 实现消息的实时更新。

项目重点演示了 Web 监听器（Listener）、过滤器（Filter）以及 Application 域数据共享的实际应用场景。

## ✨ 核心功能

1.  **用户登录/登出**
    - 输入昵称即可登录（防止重名）。
    - 支持手动注销。
2.  **实时在线状态监测**
    - 使用 `HttpSessionListener` 监听器实时监控 Session 的创建与销毁。
    - **自动超时**：用户若 10 分钟无操作，Session 自动失效并触发下线广播。
    - 实时更新在线用户列表。
3.  **系统广播**
    - 当用户上线或下线时，系统自动在聊天栏发送广播消息（如：`张三 上线了`）。
4.  **公共聊天大厅**
    - 所有在线用户均可见的群聊功能。
5.  **私聊功能 (Private Chat)**
    - 点击左侧用户列表，可进入独立的私聊视图。
    - 私聊消息仅发送者和接收者可见。
    - 支持未读消息红点提醒。
6.  **安全拦截**
    - 使用 `Filter` 过滤器拦截未登录请求，防止直接通过 URL 访问内部接口。
7.  **无刷新体验 (SPA模式)**
    - 前端使用原生 JavaScript (AJAX/Fetch) 每 1.5 秒轮询一次数据。
    - 采用单页应用（SPA）设计思路，大厅与私聊视图切换无需刷新页面。

## 🛠️ 技术栈

- **后端**：Java (JDK 17+), Jakarta Servlet, Jakarta JSP
- **前端**：JSP, HTML5, CSS3, Vanilla JavaScript (原生JS)
- **服务器**：Apache Tomcat 10+ (必需，因为使用了 `jakarta.*` 包)
- **构建工具**：Maven
- **数据存储**：`ServletContext` (内存存储，重启服务器数据重置)

## 📂 项目结构

```text
chat1/
├── pom.xml                       # Maven 依赖配置
└── src/
    └── main/
        ├── java/
        │   └── com/
        │       └── example/
        │           └── chat1/
        │               ├── ChatServlet.java           # 核心控制器：处理登录、消息收发
        │               ├── filter/
        │               │   └── LoginCheckFilter.java  # 过滤器：权限验证
        │               ├── listener/
        │               │   └── ChatSessionListener.java # 监听器：Session生命周期监控
        │               └── model/
        │                   └── ChatMessage.java       # 模型：消息实体类
        └── webapp/
            ├── index.jsp             # 主页面 (包含登录、大厅、私聊视图)
            └── WEB-INF/
                └── web.xml           # 部署描述符 (可选)
