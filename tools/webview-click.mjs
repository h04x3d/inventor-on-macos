// Click an element inside an (invisible) WebView2 page via Chrome DevTools.
// Usage: node webview-click.mjs <page-url-substring> <element-text-regex> [port]
// Prints the page text first; exits 1 if the page or element isn't there (yet).
const [, , pagePart, textRe, port = '9222'] = process.argv;
let pages;
try { pages = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch { process.exit(1); }
const page = pages.find(p => p.type === 'page' && p.url.includes(pagePart));
if (!page) process.exit(1);
const ws = new WebSocket(page.webSocketDebuggerUrl);
let id = 0; const pending = {};
const call = (method, params = {}) => new Promise(r => { pending[++id] = r; ws.send(JSON.stringify({ id, method, params })); });
ws.onmessage = e => { const m = JSON.parse(e.data); if (pending[m.id]) { pending[m.id](m.result); delete pending[m.id]; } };
ws.onopen = async () => {
  const expr = `(() => {
    const re = new RegExp(${JSON.stringify(textRe)});
    const hit = [...document.querySelectorAll('*')].filter(x => x.children.length < 4 && re.test(x.innerText || '')).pop();
    if (!hit) return 'NOT FOUND';
    let t = hit; while (t && !t.getAttribute('ng-click') && !/^(A|BUTTON)$/.test(t.tagName)) t = t.parentElement;
    (t || hit).click(); return 'clicked';
  })()`;
  const r = await call('Runtime.evaluate', { expression: expr, returnByValue: true });
  console.log(r?.result?.value); ws.close(); process.exit(r?.result?.value === 'clicked' ? 0 : 1);
};
