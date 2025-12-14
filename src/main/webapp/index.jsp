<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String username = (String) session.getAttribute("username");
    boolean isLoggedIn = (username != null);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Web聊天室</title>
    <style>
        body { margin: 0; padding: 20px; background: #f0f2f5; font-family: sans-serif; height: 100vh; box-sizing: border-box; }

        /* 布局容器 */
        .wrapper { max-width: 900px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); height: 85vh; display: flex; overflow: hidden; }

        /* 侧边栏 (用户列表) */
        .sidebar { width: 220px; border-right: 1px solid #eee; display: flex; flex-direction: column; background: #fafafa; }
        .sidebar-header { padding: 15px; border-bottom: 1px solid #eee; font-weight: bold; }
        .user-list { flex: 1; overflow-y: auto; }
        .user-item { padding: 12px 15px; cursor: pointer; display: flex; align-items: center; justify-content: space-between; transition: 0.2s; }
        .user-item:hover { background: #e6f7ff; }
        .user-item.active { background: #1890ff; color: white; }
        .status-dot { width: 8px; height: 8px; background: #52c41a; border-radius: 50%; }
        /* 未读消息红点 */
        .unread-badge { background: #ff4d4f; color: white; border-radius: 10px; padding: 0 6px; font-size: 10px; display: none; }

        /* 主内容区域 (包含大厅和私聊两个视图) */
        .main-content { flex: 1; display: flex; flex-direction: column; position: relative; }

        /* 视图通用样式 */
        .view-panel { display: flex; flex-direction: column; height: 100%; width: 100%; position: absolute; top:0; left:0; background: white; }
        .view-header { padding: 15px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; background: #fff; z-index: 10; }
        .chat-title { font-size: 18px; font-weight: bold; }
        .messages-area { flex: 1; padding: 20px; overflow-y: auto; background: #fff; }
        .input-area { padding: 15px; border-top: 1px solid #eee; display: flex; gap: 10px; background: #f9f9f9; }

        /* 消息气泡 */
        .message { margin: 10px 0; display: flex; flex-direction: column; max-width: 70%; }
        .message.own { align-self: flex-end; align-items: flex-end; }
        .message.other { align-self: flex-start; align-items: flex-start; }
        .msg-info { font-size: 12px; color: #999; margin-bottom: 4px; }
        .msg-bubble { padding: 8px 12px; border-radius: 8px; word-wrap: break-word; line-height: 1.4; }
        .own .msg-bubble { background: #1890ff; color: white; border-bottom-right-radius: 2px; }
        .other .msg-bubble { background: #f0f0f0; color: #333; border-bottom-left-radius: 2px; }
        .system-msg { text-align: center; color: #999; font-size: 12px; margin: 15px 0; width: 100%; }

        /* 按钮与输入框 */
        input { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; outline: none; }
        button { padding: 8px 20px; border: none; border-radius: 4px; cursor: pointer; transition: 0.2s; }
        .btn-primary { background: #1890ff; color: white; }
        .btn-primary:hover { background: #40a9ff; }
        .btn-danger { background: #ff4d4f; color: white; }
        .btn-back { background: #f0f0f0; color: #666; margin-right: 10px; }

        /* 登录页 */
        #loginPage { position: fixed; top:0; left:0; width:100%; height:100%; background: #f0f2f5; z-index: 100; display: flex; justify-content: center; align-items: center; }
        .login-box { background: white; padding: 40px; border-radius: 8px; width: 300px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }

        .hidden { display: none !important; }
    </style>
</head>
<body>

<!-- 登录页面 -->
<div id="loginPage" class="<%= isLoggedIn ? "hidden" : "" %>">
    <div class="login-box">
        <h2>Web 聊天室</h2>
        <input type="text" id="usernameInput" placeholder="请输入你的昵称" style="width: 100%; box-sizing: border-box; margin: 20px 0;">
        <button class="btn-primary" style="width: 100%;" onclick="login()">进入聊天</button>
    </div>
</div>

<!-- 聊天主界面 -->
<div id="chatInterface" class="wrapper <%= isLoggedIn ? "" : "hidden" %>">

    <!-- 左侧用户列表 -->
    <div class="sidebar">
        <div class="sidebar-header">
            在线用户 (<span id="onlineCount">0</span>)
            <div style="font-size: 12px; color: #999; margin-top: 5px; font-weight: normal;">点击用户发起私聊</div>
        </div>
        <div id="usersList" class="user-list"></div>
        <div style="padding: 10px;">
            <button class="btn-danger" style="width: 100%;" onclick="logout()">退出登录</button>
        </div>
    </div>

    <div class="main-content">
        <!-- 视图1: 公共大厅 -->
        <div id="hallView" class="view-panel">
            <div class="view-header">
                <span class="chat-title">公共大厅</span>
            </div>
            <div id="publicMsgs" class="messages-area"></div>
            <div class="input-area">
                <input type="text" id="publicInput" placeholder="大家好...">
                <button class="btn-primary" onclick="sendPublic()">发送</button>
            </div>
        </div>

        <!-- 视图2: 私聊窗口 (默认隐藏) -->
        <div id="privateView" class="view-panel hidden">
            <div class="view-header">
                <div>
                    <button class="btn-back" onclick="backToHall()">← 返回</button>
                    <span class="chat-title" id="privateTargetName"></span>
                </div>
            </div>
            <div id="privateMsgs" class="messages-area"></div>
            <div class="input-area">
                <input type="text" id="privateInput" placeholder="私信内容...">
                <button class="btn-primary" onclick="sendPrivate()">发送</button>
            </div>
        </div>
    </div>
</div>

<script>
    // 全局状态
    let currentUser = "<%= isLoggedIn ? username : "" %>";
    let currentView = 'hall'; // 'hall' or 'private'
    let privateTarget = null; // 当前正在私聊的对象用户名
    let lastTime = 0;
    let timer = null;

    // 存储私聊消息缓存，格式: { 'Bob': [msg1, msg2], 'Alice': [msg...] }
    // 这样切换回来时不需要重新请求
    let privateChats = {};

    // 初始化
    window.onload = function() {
        if (currentUser) {
            startTimer();
            // 绑定回车发送
            bindEnterKey('publicInput', sendPublic);
            bindEnterKey('privateInput', sendPrivate);
            bindEnterKey('usernameInput', login);
        }
    };

    function bindEnterKey(id, func) {
        document.getElementById(id).addEventListener('keypress', function(e) {
            if (e.key === 'Enter') func();
        });
    }

    function startTimer() {
        if (timer) clearInterval(timer);
        loadData(); // 立即加载一次
        timer = setInterval(loadData, 1500);
    }

    // --- 登录逻辑 ---
    function login() {
        const name = document.getElementById('usernameInput').value.trim();
        if(!name) return;

        fetch('chat/login', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: `username=\${encodeURIComponent(name)}`
        }).then(r => r.json()).then(res => {
            if(res.success) {
                currentUser = name;
                document.getElementById('loginPage').classList.add('hidden');
                document.getElementById('chatInterface').classList.remove('hidden');
                startTimer();
                bindEnterKey('publicInput', sendPublic);
                bindEnterKey('privateInput', sendPrivate);
            } else {
                alert(res.message);
            }
        });
    }

    // --- 切换视图逻辑 ---
    function openPrivateChat(targetUser) {
        if (targetUser === currentUser) return; // 不能跟自己聊

        privateTarget = targetUser;
        currentView = 'private';

        // UI 切换
        document.getElementById('hallView').classList.add('hidden');
        document.getElementById('privateView').classList.remove('hidden');
        document.getElementById('privateTargetName').innerText = `与 ${targetUser} 私聊中`;

        // 渲染该用户的历史消息
        renderPrivateMessages(targetUser);

        // 清除该用户的未读红点（如果有）
        const badge = document.getElementById(`badge-\${targetUser}`);
        if(badge) badge.style.display = 'none';

        // 自动聚焦输入框
        document.getElementById('privateInput').focus();
    }

    function backToHall() {
        currentView = 'hall';
        privateTarget = null;

        document.getElementById('privateView').classList.add('hidden');
        document.getElementById('hallView').classList.remove('hidden');
    }

    // --- 发送逻辑 ---

    // 发送公聊
    function sendPublic() {
        const input = document.getElementById('publicInput');
        const content = input.value.trim();
        if(!content) return;

        sendMessage(content, null, () => {
            input.value = '';
            loadData();
        });
    }

    // 发送私聊
    function sendPrivate() {
        const input = document.getElementById('privateInput');
        const content = input.value.trim();
        if(!content || !privateTarget) return;

        // 显式传递 receiver 参数
        sendMessage(content, privateTarget, () => {
            input.value = '';
            loadData();
        });
    }

    function sendMessage(content, receiver, callback) {
        let body = `content=\${encodeURIComponent(content)}`;
        if (receiver) {
            body += `&receiver=\${encodeURIComponent(receiver)}`;
        }

        fetch('chat/send', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body
        }).then(r => r.json()).then(res => {
            if(res.success) {
                if(callback) callback();
            } else {
                if(res.message && res.message.includes("未登录")) location.reload();
            }
        });
    }

    // --- 数据加载与渲染逻辑 ---
    function loadData() {
        fetch(`chat/messages?lastTime=\${lastTime}`)
            .then(r => r.json())
            .then(res => {
                if(!res.success) {
                    if(res.message && res.message.includes("未登录")) location.reload();
                    return;
                }

                // 1. 处理用户列表
                if(res.users) updateUsersList(res.users);

                // 2. 处理新消息 (分发到不同的桶里)
                if(res.messages && res.messages.length > 0) {
                    res.messages.forEach(msg => {
                        processMessage(msg);
                    });
                    lastTime = res.lastTime;
                }
            });
    }

    function updateUsersList(users) {
        const list = document.getElementById('usersList');
        // 为了保持红点状态，不直接innerHTML清空，而是比对（这里简化处理：重绘但保留红点逻辑需要复杂状态，暂且重绘）
        // 简单实现：每次重绘，但是如果某个用户有未读消息缓存，则显示红点

        let html = '';
        users.forEach(u => {
            let badgeStyle = 'display:none';
            // 如果这个用户有消息且不是当前聊天对象，显示红点 (此处需要额外的逻辑来判断未读，这里先简化)
            // 实际工程中应该在 processMessage 里标记 unread

            // 下面为了保持 onclick，使用 JS 创建元素更安全，但 innerHTML 更简洁。
            // 这里为了演示方便使用 innerHTML，实际项目建议 document.createElement
            let activeClass = (u === privateTarget) ? 'active' : '';

            // 检查是否有未读 (利用全局对象标记)
            let isUnread = window[`unread_\${u}`] === true;
            if (isUnread && u !== privateTarget) badgeStyle = 'display:inline-block';

            html += `
                <div class="user-item \${activeClass}" onclick="openPrivateChat('\${u}')">
                    <div style="display:flex; align-items:center; gap:8px;">
                        <div class="status-dot"></div>
                        <span>\${u} \${u === currentUser ? '(我)' : ''}</span>
                    </div>
                    <span id="badge-\${u}" class="unread-badge" style="\${badgeStyle}">新消息</span>
                </div>
            `;
        });
        document.getElementById('usersList').innerHTML = html;
        document.getElementById('onlineCount').innerText = users.length;
    }

    function processMessage(msg) {
        // 1. 系统消息 -> 公聊
        if (msg.type === 'system') {
            appendMessage('publicMsgs', msg);
            return;
        }

        // 2. 公聊消息 -> 公聊
        if (msg.type === 'public' || msg.receiver === 'all') {
            appendMessage('publicMsgs', msg);
            return;
        }

        // 3. 私聊消息 -> 分类存储
        if (msg.type === 'private') {
            // 确定对方是谁
            let otherParty = (msg.sender === currentUser) ? msg.receiver : msg.sender;

            // 存入缓存
            if (!privateChats[otherParty]) privateChats[otherParty] = [];
            privateChats[otherParty].push(msg);

            // 如果当前正好在和这个人聊，直接渲染
            if (currentView === 'private' && privateTarget === otherParty) {
                appendMessage('privateMsgs', msg);
            }
            // 如果不在和这个人聊，并且消息不是我发的（是我收到的），标记未读
            else if (msg.sender !== currentUser) {
                window[`unread_\${otherParty}`] = true;
                // 尝试显示红点
                const badge = document.getElementById(`badge-\${otherParty}`);
                if(badge) badge.style.display = 'inline-block';
            }
        }
    }

    function appendMessage(containerId, msg) {
        const container = document.getElementById(containerId);
        const div = document.createElement('div');

        if (msg.type === 'system') {
            div.className = 'system-msg';
            div.innerText = msg.content;
        } else {
            const isMe = msg.sender === currentUser;
            div.className = `message \${isMe ? 'own' : 'other'}`;
            div.innerHTML = `
                <div class="msg-info">\${msg.sender}</div>
                <div class="msg-bubble">\${msg.content}</div>
            `;
        }

        container.appendChild(div);
        container.scrollTop = container.scrollHeight;
    }

    // 切换私聊对象时，渲染历史消息
    function renderPrivateMessages(target) {
        const container = document.getElementById('privateMsgs');
        container.innerHTML = ''; // 清空当前视图

        if (privateChats[target]) {
            privateChats[target].forEach(msg => {
                const div = document.createElement('div');
                const isMe = msg.sender === currentUser;
                div.className = `message \${isMe ? 'own' : 'other'}`;
                div.innerHTML = `
                    <div class="msg-info">\${msg.sender}</div>
                    <div class="msg-bubble">\${msg.content}</div>
                `;
                container.appendChild(div);
            });
            container.scrollTop = container.scrollHeight;
        }

        // 清除未读标记
        window[`unread_\${target}`] = false;
    }

    function logout() {
        if(confirm("确定要退出吗？")) {
            fetch('chat/logout', {method:'POST'}).then(() => location.reload());
        }
    }
</script>

</body>
</html>