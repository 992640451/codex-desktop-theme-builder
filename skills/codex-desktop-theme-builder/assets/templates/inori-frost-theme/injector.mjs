#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const VERSION = "1.8.0";
const scriptDir = dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const result = new Map();
  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    if (!key.startsWith("--")) continue;
    const value = argv[index + 1];
    if (value && !value.startsWith("--")) {
      result.set(key, value);
      index += 1;
    } else {
      result.set(key, true);
    }
  }
  return result;
}

const args = parseArgs(process.argv.slice(2));
const port = Number(args.get("--port") ?? 9333);
const cssPath = resolve(String(args.get("--css") ?? resolve(scriptDir, "theme.css")));
const imagePath = resolve(String(args.get("--image") ?? resolve(scriptDir, "assets", "inori-original-crystal-hero.png")));
const once = args.has("--once");
const endpoint = `http://127.0.0.1:${port}`;

if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error(`Invalid CDP port: ${port}`);
if (typeof fetch !== "function" || typeof WebSocket !== "function") {
  throw new Error("Node.js 22 or newer is required (fetch + WebSocket support)." );
}

const [css, imageBytes] = await Promise.all([readFile(cssPath, "utf8"), readFile(imagePath)]);
const heroDataUri = `data:image/png;base64,${imageBytes.toString("base64")}`;
const hydratedCss = css.replaceAll("var(--inori-hero-image)", `url("${heroDataUri}")`);

function pageBootstrap(themeCss, version) {
  const STYLE_ID = "inori-frost-theme-style";
  const HERO_ID = "inori-frost-hero";
  const BADGE_ID = "inori-frost-badge";
  const TASK_STATUS_ID = "inori-frost-task-status";
  const SIGNAL_MAP_ID = "inori-frost-signal-map";

  function skipAvatarOverlay() {
    const route = new URLSearchParams(location.search).get("initialRoute");
    if (route !== "/avatar-overlay") return null;

    window.__INORI_FROST_OBSERVER__?.disconnect();
    delete window.__INORI_FROST_OBSERVER__;
    document.getElementById(STYLE_ID)?.remove();
    document.getElementById(HERO_ID)?.remove();
    document.getElementById(BADGE_ID)?.remove();
    document.getElementById(TASK_STATUS_ID)?.remove();
    document.getElementById(SIGNAL_MAP_ID)?.remove();
    document.querySelectorAll("[data-codex-composer-root]").forEach((composer) => {
      composer.removeAttribute("data-inori-task-state");
      composer.querySelectorAll("[data-inori-primary-action]").forEach((button) => {
        button.removeAttribute("data-inori-primary-action");
      });
    });

    const root = document.documentElement;
    root?.classList.remove("inori-frost-theme", "inori-frost-home", "inori-frost-task-running", "inori-frost-task-complete");
    root?.removeAttribute("data-inori-task-state");
    root?.style.removeProperty("--inori-hero-image");

    const state = {
      version,
      appliedAt: new Date().toISOString(),
      skipped: true,
      reason: "avatar-overlay",
    };
    window.__INORI_FROST_THEME__ = state;
    return { applied: false, ...state, url: location.href };
  }

  const skipped = skipAvatarOverlay();
  if (skipped) return skipped;

  function isRunningAction(button) {
    if (!button || button.disabled) return false;
    const label = (button.getAttribute("aria-label") ?? "").trim().toLowerCase();
    const path = button.querySelector("svg path")?.getAttribute("d") ?? "";
    return /(停止|中止|终止|stop|cancel|interrupt)/i.test(label)
      || path.startsWith("M4.5 5.75C4.5");
  }

  function syncTaskStatus(root, isHome) {
    const composers = [...document.querySelectorAll("[data-codex-composer-root]")];
    const composer = composers[0] ?? null;
    const conversationId = composer
      ?.querySelector("[data-above-composer-conversation-id]")
      ?.getAttribute("data-above-composer-conversation-id") ?? null;

    if (!composer || isHome || !conversationId) {
      document.getElementById(TASK_STATUS_ID)?.remove();
      composers.forEach((item) => {
        item.removeAttribute("data-inori-task-state");
        item.querySelectorAll("[data-inori-primary-action]").forEach((button) => {
          button.removeAttribute("data-inori-primary-action");
        });
      });
      root.classList.remove("inori-frost-task-running", "inori-frost-task-complete");
      root.removeAttribute("data-inori-task-state");
      return "idle";
    }

    const buttons = [...composer.querySelectorAll("button")];
    const primaryAction = buttons.at(-1) ?? null;
    const taskState = isRunningAction(primaryAction) ? "running" : "complete";
    composers.forEach((item) => {
      item.querySelectorAll("[data-inori-primary-action]").forEach((button) => {
        button.removeAttribute("data-inori-primary-action");
      });
    });
    primaryAction?.setAttribute("data-inori-primary-action", taskState);
    composers.forEach((item) => {
      if (item === composer) item.dataset.inoriTaskState = taskState;
      else item.removeAttribute("data-inori-task-state");
    });
    root.dataset.inoriTaskState = taskState;
    root.classList.toggle("inori-frost-task-running", taskState === "running");
    root.classList.toggle("inori-frost-task-complete", taskState === "complete");

    const chrome = composer.querySelector(".composer-surface-chrome") ?? composer;
    let status = document.getElementById(TASK_STATUS_ID);
    if (!status || status.dataset.conversationId !== conversationId || status.parentElement !== chrome) {
      status?.remove();
      status = document.createElement("div");
      status.id = TASK_STATUS_ID;
      status.setAttribute("aria-hidden", "true");
      status.dataset.conversationId = conversationId;
      chrome.appendChild(status);
    }
    if (status.dataset.state !== taskState || !status.querySelector("[data-inori-status-label]")) {
      status.dataset.state = taskState;
      const code = document.createElement("span");
      code.textContent = taskState === "running" ? "LIVE" : "SEALED";
      const label = document.createElement("strong");
      label.dataset.inoriStatusLabel = "";
      label.textContent = taskState === "running" ? "正在执行" : "回复已完成";
      status.replaceChildren(code, label);
    }
    return taskState;
  }

  function buildSignalStarfield() {
    let seed = 0x16f0a2d;
    const random = () => {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return seed / 0x100000000;
    };
    const stars = [];

    for (let index = 0; index < 112; index += 1) {
      let x = 20 + random() * 1160;
      let y = 24 + random() * 772;
      if (index >= 68) {
        x = 28 + random() * 1144;
        y = Math.max(34, Math.min(786, 680 - x * 0.46 + (random() - 0.5) * 210));
      }
      const radius = index % 13 === 0 ? 1.2 + random() * 0.55 : 0.48 + random() * 0.58;
      const tone = index % 11 === 0 ? " inori-star-violet" : index % 3 === 0 ? " inori-star-cyan" : " inori-star-ice";
      const bright = index % 17 === 0 ? " inori-star-bright" : "";
      const alpha = (0.48 + random() * 0.45).toFixed(2);
      stars.push(`<circle class="inori-star${tone}${bright}" cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${radius.toFixed(2)}" style="--inori-star-alpha:${alpha}"/>`);
    }

    const flares = [
      [92, 116, "cyan"], [214, 698, "ice"], [338, 198, "ice"], [482, 624, "violet"],
      [602, 92, "ice"], [746, 724, "cyan"], [858, 178, "violet"], [972, 596, "ice"],
      [1106, 104, "cyan"], [1142, 444, "ice"],
    ].map(([x, y, tone], index) => `
      <g class="inori-star-flare inori-star-flare-${tone}" transform="translate(${x} ${y})" style="--inori-flare-delay:-${(index * 1.37).toFixed(2)}s">
        <circle class="inori-star inori-star-${tone} inori-star-bright" r="1.45" style="--inori-star-alpha:.96"/>
        <path class="inori-star-flare-rays" d="M0-7V7M-7 0H7M-3.5-3.5 3.5 3.5M-3.5 3.5 3.5-3.5"/>
      </g>`);

    return `<g class="inori-map-stars">${stars.join("")}${flares.join("")}</g>`;
  }

  function syncSignalMap(main, isHome) {
    const existing = document.getElementById(SIGNAL_MAP_ID);
    if (!main || isHome) {
      existing?.remove();
      return null;
    }
    if (existing?.parentElement === main) return existing;
    existing?.remove();

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.id = SIGNAL_MAP_ID;
    svg.setAttribute("viewBox", "0 0 1200 820");
    svg.setAttribute("preserveAspectRatio", "xMidYMid slice");
    svg.setAttribute("aria-hidden", "true");
    svg.innerHTML = `
      <defs>
        <linearGradient id="inori-edge-mask-gradient" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="1200" y2="0">
          <stop offset="0" stop-color="white"/><stop offset=".22" stop-color="white"/>
          <stop offset=".31" stop-color="black"/><stop offset=".7" stop-color="black"/>
          <stop offset=".79" stop-color="white"/><stop offset="1" stop-color="white"/>
        </linearGradient>
        <linearGradient id="inori-core-mask-gradient" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="1200" y2="0">
          <stop offset="0" stop-color="black"/><stop offset=".25" stop-color="black"/>
          <stop offset=".34" stop-color="white"/><stop offset=".68" stop-color="white"/>
          <stop offset=".77" stop-color="black"/><stop offset="1" stop-color="black"/>
        </linearGradient>
        <mask id="inori-edge-activity-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1200" height="820">
          <rect width="1200" height="820" fill="url(#inori-edge-mask-gradient)"/>
        </mask>
        <mask id="inori-core-activity-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1200" height="820">
          <rect width="1200" height="820" fill="url(#inori-core-mask-gradient)"/>
        </mask>
      </defs>
      ${buildSignalStarfield()}
      <g class="inori-map-contours">
        <path d="M-80 148C100 48 228 210 382 118S698 50 826 132s208 94 454-18"/>
        <path d="M-70 184C108 86 232 244 398 154s286-58 430 24 242 68 440-24"/>
        <path d="M-110 504c146-92 270-34 374 62s250 126 394 24 286-86 452 6"/>
        <path d="M-80 548c138-82 250-18 350 78s250 118 394 22 294-78 476 18"/>
        <path d="M176-40c-48 142 62 238 24 350S80 536 170 650s98 170 62 242"/>
        <path d="M942-54c70 130-18 234 52 334s122 190 44 304-64 174 30 286"/>
      </g>
      <g class="inori-map-route inori-route-a">
        <path class="inori-route-base" d="M-60 662C142 596 168 354 366 426s278 188 474 20 274-236 438-132"/>
        <path class="inori-route-pulse inori-route-pulse-edge" mask="url(#inori-edge-activity-mask)" pathLength="100" d="M-60 662C142 596 168 354 366 426s278 188 474 20 274-236 438-132"/>
        <path class="inori-route-pulse inori-route-pulse-core" mask="url(#inori-core-activity-mask)" pathLength="100" d="M-60 662C142 596 168 354 366 426s278 188 474 20 274-236 438-132"/>
      </g>
      <g class="inori-map-route inori-route-b">
        <path class="inori-route-base" d="M50 204c166 112 248-88 402 28s246 186 356 24S1038 82 1248 174"/>
        <path class="inori-route-pulse inori-route-pulse-edge" mask="url(#inori-edge-activity-mask)" pathLength="100" d="M50 204c166 112 248-88 402 28s246 186 356 24S1038 82 1248 174"/>
      </g>
      <g class="inori-map-route inori-route-c">
        <path class="inori-route-base" d="M238 866c42-176 238-126 334-270s214-236 394-82 232 184 340 70"/>
        <path class="inori-route-pulse inori-route-pulse-edge" mask="url(#inori-edge-activity-mask)" pathLength="100" d="M238 866c42-176 238-126 334-270s214-236 394-82 232 184 340 70"/>
      </g>
      <g class="inori-map-node inori-node-a" transform="translate(132 594)">
        <circle class="inori-node-ring" r="9"/><circle class="inori-node-core" r="2.3"/><text x="14" y="3">FROST-01</text>
      </g>
      <g class="inori-map-node inori-node-b" transform="translate(366 426)">
        <circle class="inori-node-ring" r="10"/><circle class="inori-node-core" r="2.5"/><text x="15" y="3">RELAY-03</text>
      </g>
      <g class="inori-map-node inori-node-c" transform="translate(626 548)">
        <circle class="inori-node-ring" r="8"/><circle class="inori-node-core" r="2.2"/><text x="13" y="3">AURORA</text>
      </g>
      <g class="inori-map-node inori-node-d" transform="translate(840 446)">
        <circle class="inori-node-ring" r="10"/><circle class="inori-node-core" r="2.5"/><text x="15" y="3">LINK-07</text>
      </g>
      <g class="inori-map-node inori-node-e" transform="translate(452 232)">
        <circle class="inori-node-ring" r="8"/><circle class="inori-node-core" r="2.2"/><text x="13" y="3">VEIL</text>
      </g>
      <g class="inori-map-node inori-node-f" transform="translate(808 256)">
        <circle class="inori-node-ring" r="9"/><circle class="inori-node-core" r="2.3"/><text x="14" y="3">CRYSTAL</text>
      </g>
      <g class="inori-map-node inori-terminal" transform="translate(1084 330)">
        <circle class="inori-node-ring" r="13"/><circle class="inori-node-core" r="3"/>
        <path class="inori-node-seal" d="M0-9V9M-7.8-4.5 7.8 4.5M-7.8 4.5 7.8-4.5M0-9l-2.6 3M0-9l2.6 3M0 9l-2.6-3M0 9l2.6-3"/>
        <text x="18" y="3">SEAL-09</text>
      </g>`;
    main.prepend(svg);
    return svg;
  }

  function apply() {
    const root = document.documentElement;
    if (!root) return { applied: false, reason: "document-not-ready" };

    root.classList.add("inori-frost-theme");
    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      style.dataset.inoriFrostVersion = version;
      (document.head ?? root).appendChild(style);
    }
    if (style.textContent !== themeCss) style.textContent = themeCss;

    const main = document.querySelector("main.main-surface");
    const cards = document.querySelectorAll("main.main-surface button.min-h-26");
    const isHome = Boolean(main && cards.length >= 4 && document.querySelector("[data-codex-composer-root]"));
    root.classList.toggle("inori-frost-home", isHome);
    const taskState = syncTaskStatus(root, isHome);
    syncSignalMap(main, isHome);

    if (main) {
      let hero = document.getElementById(HERO_ID);
      if (!hero) {
        hero = document.createElement("div");
        hero.id = HERO_ID;
        hero.setAttribute("aria-hidden", "true");
        main.prepend(hero);
      }

      let badge = document.getElementById(BADGE_ID);
      if (!badge) {
        badge = document.createElement("div");
        badge.id = BADGE_ID;
        badge.setAttribute("aria-hidden", "true");
        badge.innerHTML = "凛晶 · 冰晶主题 <span>INORI FROST CODE</span>";
        main.appendChild(badge);
      }
    }

    window.__INORI_FROST_THEME__ = { version, appliedAt: new Date().toISOString(), isHome, taskState };
    return { applied: true, version, isHome, taskState, cardCount: cards.length, url: location.href };
  }

  const result = apply();
  if (!window.__INORI_FROST_OBSERVER__) {
    let timer = 0;
    const observer = new MutationObserver(() => {
      clearTimeout(timer);
      timer = window.setTimeout(apply, 80);
    });
    observer.observe(document.getElementById("root") ?? document.body ?? document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["aria-label", "disabled", "d"],
    });
    window.__INORI_FROST_OBSERVER__ = observer;
  }
  return result;
}

const source = `(${pageBootstrap.toString()})(${JSON.stringify(hydratedCss)},${JSON.stringify(VERSION)})`;
const sessions = new Map();

class CdpSession {
  constructor(target) {
    this.target = target;
    this.socket = null;
    this.sequence = 0;
    this.pending = new Map();
    this.closed = false;
    this.timer = null;
  }

  async connect() {
    this.socket = new WebSocket(this.target.webSocketDebuggerUrl);
    await new Promise((resolveOpen, rejectOpen) => {
      const timeout = setTimeout(() => rejectOpen(new Error("WebSocket open timed out")), 8000);
      this.socket.addEventListener("open", () => { clearTimeout(timeout); resolveOpen(); }, { once: true });
      this.socket.addEventListener("error", () => { clearTimeout(timeout); rejectOpen(new Error("WebSocket open failed")); }, { once: true });
    });

    this.socket.addEventListener("message", (event) => this.onMessage(event));
    this.socket.addEventListener("close", () => this.close());
    this.socket.addEventListener("error", () => this.close());
    await Promise.all([this.send("Runtime.enable"), this.send("Page.enable")]);
    await this.send("Page.addScriptToEvaluateOnNewDocument", { source });
    await this.inject();
  }

  onMessage(event) {
    let message;
    try { message = JSON.parse(event.data); } catch { return; }
    if (message.id && this.pending.has(message.id)) {
      const pending = this.pending.get(message.id);
      this.pending.delete(message.id);
      clearTimeout(pending.timer);
      message.error ? pending.reject(new Error(message.error.message ?? JSON.stringify(message.error))) : pending.resolve(message.result);
      return;
    }
    if (message.method === "Page.loadEventFired" || message.method === "Runtime.executionContextCreated") this.schedule();
  }

  send(method, params = {}) {
    if (!this.socket || this.socket.readyState !== WebSocket.OPEN) return Promise.reject(new Error("CDP socket is not open"));
    const id = ++this.sequence;
    return new Promise((resolveRequest, rejectRequest) => {
      const timer = setTimeout(() => { this.pending.delete(id); rejectRequest(new Error(`CDP request timed out: ${method}`)); }, 10000);
      this.pending.set(id, { resolve: resolveRequest, reject: rejectRequest, timer });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  schedule() {
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.inject().catch((error) => console.error(`[inori-frost] reinjection failed: ${error.message}`)), 180);
  }

  async inject() {
    if (this.closed) return null;
    const response = await this.send("Runtime.evaluate", { expression: source, awaitPromise: true, returnByValue: true, userGesture: false });
    if (response?.exceptionDetails) throw new Error(response.exceptionDetails.text ?? "Theme injection failed");
    const result = response?.result?.value ?? null;
    console.log(`[inori-frost] applied ${this.target.url} ${JSON.stringify(result)}`);
    return result;
  }

  close() {
    if (this.closed) return;
    this.closed = true;
    clearTimeout(this.timer);
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(new Error("CDP session closed"));
    }
    this.pending.clear();
    sessions.delete(this.target.id);
    try { this.socket?.close(); } catch { /* already closed */ }
  }
}

async function listTargets() {
  const response = await fetch(`${endpoint}/json/list`, { signal: AbortSignal.timeout(6000) });
  if (!response.ok) throw new Error(`CDP returned HTTP ${response.status}`);
  return (await response.json()).filter((target) => (
    target.type === "page"
    && typeof target.url === "string"
    && target.url.startsWith("app://-/index.html")
    && typeof target.webSocketDebuggerUrl === "string"
  ));
}

async function poll() {
  const targets = await listTargets();
  const activeIds = new Set(targets.map((target) => target.id));
  for (const [id, session] of sessions) if (!activeIds.has(id)) session.close();
  const jobs = [];
  for (const target of targets) {
    if (sessions.has(target.id)) continue;
    const session = new CdpSession(target);
    sessions.set(target.id, session);
    jobs.push(session.connect().catch((error) => { console.error(`[inori-frost] attach failed for ${target.url}: ${error.message}`); session.close(); }));
  }
  await Promise.all(jobs);
  return targets.length;
}

let stopping = false;
function shutdown() {
  if (stopping) return;
  stopping = true;
  for (const session of sessions.values()) session.close();
  process.exit(0);
}
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

console.log(`[inori-frost] injector ${VERSION} waiting on ${endpoint}`);
if (once) {
  const count = await poll();
  if (count === 0) throw new Error("No Codex page targets were found.");
  await new Promise((resolveWait) => setTimeout(resolveWait, 400));
  shutdown();
} else {
  while (!stopping) {
    try { await poll(); } catch (error) { console.error(`[inori-frost] CDP poll failed: ${error.message}`); }
    await new Promise((resolveWait) => setTimeout(resolveWait, 1200));
  }
}
