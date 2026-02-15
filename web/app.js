const API = '';
let currentDate = '';
let currentNewsId = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadNews();
});

async function loadNews(date) {
    const params = date ? `?date=${date}` : '';
    try {
        const resp = await fetch(`${API}/api/news${params}`);
        if (!resp.ok) throw new Error('加载失败');
        const data = await resp.json();

        currentDate = data.date;
        document.getElementById('currentDate').textContent = formatDate(data.date);

        renderNewsList('domesticNews', data.domestic);
        renderNewsList('globalNews', data.global);

        document.getElementById('prevBtn').disabled = !data.has_prev;
        document.getElementById('nextBtn').disabled = !data.has_next;

        // Show "today" button if not viewing today
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('todayBtn').style.display =
            data.date === today ? 'none' : 'inline-block';
    } catch (err) {
        console.error('加载新闻失败:', err);
        document.getElementById('domesticNews').innerHTML =
            '<div class="empty-state">加载失败，请刷新重试</div>';
        document.getElementById('globalNews').innerHTML =
            '<div class="empty-state">加载失败，请刷新重试</div>';
    }
}

function renderNewsList(containerId, news) {
    const container = document.getElementById(containerId);
    if (!news || news.length === 0) {
        container.innerHTML = '<div class="empty-state">暂无新闻数据</div>';
        return;
    }

    container.innerHTML = news.map(item => `
        <div class="news-item">
            <div class="news-title-row">
                <span class="news-rank rank-${item.rank}">${item.rank}</span>
                <span class="news-title">
                    <a href="${escapeHtml(item.source_url)}" target="_blank" rel="noopener">${escapeHtml(item.title)}</a>
                </span>
            </div>
            ${item.summary ? `<div class="news-summary">${escapeHtml(item.summary)}</div>` : ''}
            <div class="news-meta">
                <span class="source-tag">${escapeHtml(item.source_name)}</span>
                <button class="comment-trigger" onclick="openComments(${item.id}, '${escapeHtml(item.title).replace(/'/g, "\\'")}')">
                    💬 评论${item.comment_count > 0 ? ` (${item.comment_count})` : ''}
                </button>
            </div>
        </div>
    `).join('');
}

async function navigate(dir) {
    try {
        const resp = await fetch(`${API}/api/news/navigate?date=${currentDate}&dir=${dir}`);
        if (!resp.ok) return;
        const data = await resp.json();
        loadNews(data.date);
    } catch (err) {
        console.error('导航失败:', err);
    }
}

function goToday() {
    loadNews();
}

// Comments
async function openComments(newsId, title) {
    currentNewsId = newsId;
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('commentModal').classList.add('active');
    document.getElementById('commentAuthor').value = '';
    document.getElementById('commentContent').value = '';
    await loadComments(newsId);
}

async function loadComments(newsId) {
    const list = document.getElementById('commentList');
    list.innerHTML = '<div class="loading">加载评论中...</div>';

    try {
        const resp = await fetch(`${API}/api/news/${newsId}/comments`);
        if (!resp.ok) throw new Error('加载失败');
        const comments = await resp.json();

        if (!comments || comments.length === 0) {
            list.innerHTML = '<div class="no-comments">暂无评论，来说两句吧</div>';
            return;
        }

        list.innerHTML = comments.map(c => `
            <div class="comment-item">
                <div class="comment-author">
                    ${escapeHtml(c.author)}
                    <span class="comment-time">${formatTime(c.created_at)}</span>
                </div>
                <div class="comment-text">${escapeHtml(c.content)}</div>
            </div>
        `).join('');
    } catch (err) {
        list.innerHTML = '<div class="no-comments">加载评论失败</div>';
    }
}

async function submitComment() {
    const author = document.getElementById('commentAuthor').value.trim();
    const content = document.getElementById('commentContent').value.trim();

    if (!content) {
        alert('请输入评论内容');
        return;
    }

    try {
        const resp = await fetch(`${API}/api/news/${currentNewsId}/comments`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ author, content }),
        });

        if (!resp.ok) {
            const text = await resp.text();
            throw new Error(text);
        }

        document.getElementById('commentContent').value = '';
        await loadComments(currentNewsId);
        // Refresh news to update comment count
        loadNews(currentDate);
    } catch (err) {
        alert('发表评论失败: ' + err.message);
    }
}

function closeModal() {
    document.getElementById('commentModal').classList.remove('active');
    currentNewsId = null;
}

function closeModalOutside(event) {
    if (event.target === document.getElementById('commentModal')) {
        closeModal();
    }
}

// Keyboard shortcut
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
    if (e.key === 'ArrowLeft' && !document.getElementById('prevBtn').disabled) navigate('prev');
    if (e.key === 'ArrowRight' && !document.getElementById('nextBtn').disabled) navigate('next');
});

// News fetching
async function fetchLatestNews() {
    const btn = document.querySelector('.fetch-btn');
    const originalText = btn.textContent;
    btn.textContent = '抓取中...';
    btn.disabled = true;

    try {
        const today = new Date().toISOString().split('T')[0];
        const resp = await fetch(`${API}/api/news/fetch?date=${today}`, { method: 'POST' });
        if (!resp.ok) {
            const text = await resp.text();
            throw new Error(text);
        }
        await loadNews(today);
        btn.textContent = '抓取完成!';
        setTimeout(() => { btn.textContent = originalText; btn.disabled = false; }, 2000);
    } catch (err) {
        alert('抓取失败: ' + err.message);
        btn.textContent = originalText;
        btn.disabled = false;
    }
}

// Utilities
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateStr) {
    const d = new Date(dateStr + 'T00:00:00');
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 周${days[d.getDay()]}`;
}

function formatTime(timeStr) {
    if (!timeStr) return '';
    const d = new Date(timeStr);
    if (isNaN(d.getTime())) return timeStr;
    const now = new Date();
    const diff = now - d;
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return `${Math.floor(diff / 60000)} 分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)} 小时前`;
    return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}
