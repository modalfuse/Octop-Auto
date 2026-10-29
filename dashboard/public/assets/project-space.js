/*! Octop patch: 项目空间 — injected sidebar group above 对话 */
(function () {
  var STORAGE_KEY = "octop:project-space";
  var COLLAPSE_KEY = "octop:project-space-collapsed";
  var ACTIVE_KEY = "octop:project-space-active";
  var ROOT_ID = "octop-project-space";
  var MARK = "data-octop-project-space";
  var lastSig = "";
  var applying = false;

  function loadProjects() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      var list = raw ? JSON.parse(raw) : [];
      return Array.isArray(list) ? list : [];
    } catch (e) {
      return [];
    }
  }

  function saveProjects(list) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
  }

  function uid() {
    return "p_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function findNavHost() {
    var group = document.querySelector(".Sidebar-module__navGroup__SzMsO");
    if (!group) return null;
    return group.parentElement;
  }

  function isCollapsedRail() {
    var sidebar = document.querySelector(".index-module__sidebar__CKXDV");
    if (!sidebar) return false;
    var w = sidebar.getBoundingClientRect().width;
    return w > 0 && w < 120;
  }

  function ensureRoot(host) {
    var existing = document.getElementById(ROOT_ID);
    if (existing) {
      if (existing.parentElement !== host || host.firstChild !== existing) {
        host.insertBefore(existing, host.firstChild);
      }
      return existing;
    }
    var root = document.createElement("div");
    root.id = ROOT_ID;
    root.setAttribute(MARK, "1");
    host.insertBefore(root, host.firstChild);
    return root;
  }

  function closeDialog() {
    var bg = document.querySelector(".ops-dialog-backdrop");
    if (bg) bg.remove();
  }

  function openNewProjectDialog(onDone) {
    closeDialog();
    var backdrop = document.createElement("div");
    backdrop.className = "ops-dialog-backdrop";
    backdrop.innerHTML =
      '<div id="octop-project-space-dialog" role="dialog" aria-modal="true">' +
      "<h3>新建项目</h3>" +
      '<input id="ops-name-input" type="text" placeholder="项目名称" maxlength="64" />' +
      '<div class="ops-actions">' +
      '<button type="button" class="ops-cancel">取消</button>' +
      '<button type="button" class="ops-ok">创建</button>' +
      "</div></div>";
    document.body.appendChild(backdrop);
    var input = backdrop.querySelector("#ops-name-input");
    var cancel = backdrop.querySelector(".ops-cancel");
    var ok = backdrop.querySelector(".ops-ok");
    function submit() {
      var name = (input.value || "").trim();
      if (!name) {
        input.focus();
        return;
      }
      closeDialog();
      onDone(name);
    }
    cancel.addEventListener("click", closeDialog);
    backdrop.addEventListener("click", function (e) {
      if (e.target === backdrop) closeDialog();
    });
    ok.addEventListener("click", submit);
    input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") submit();
      if (e.key === "Escape") closeDialog();
    });
    setTimeout(function () {
      input.focus();
    }, 0);
  }

  function folderSvg() {
    return (
      '<svg class="ops-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>' +
      "</svg>"
    );
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
  function escapeAttr(s) {
    return escapeHtml(s).replace(/'/g, "&#39;");
  }

  function signature() {
    return JSON.stringify({
      c: localStorage.getItem(COLLAPSE_KEY) === "1",
      a: localStorage.getItem(ACTIVE_KEY) || "",
      p: loadProjects(),
      hide: isCollapsedRail(),
    });
  }

  function render(root) {
    var sig = signature();
    if (isCollapsedRail()) {
      root.style.display = "none";
      lastSig = sig;
      return;
    }
    root.style.display = "";
    if (sig === lastSig && root.getAttribute("data-rendered") === "1") return;
    lastSig = sig;
    applying = true;
    var collapsed = localStorage.getItem(COLLAPSE_KEY) === "1";
    var activeId = localStorage.getItem(ACTIVE_KEY) || "";
    var projects = loadProjects();
    root.className = collapsed ? "is-collapsed" : "";
    var listHtml = "";
    if (projects.length === 0) {
      listHtml = '<div class="ops-empty">暂无项目，点击上方新建</div>';
    } else {
      listHtml =
        '<ul class="ops-list">' +
        projects
          .map(function (p) {
            var active = p.id === activeId ? " is-active" : "";
            return (
              '<li class="ops-item' +
              active +
              '" data-id="' +
              p.id +
              '">' +
              '<button type="button" class="ops-item-main" data-action="open" title="' +
              escapeAttr(p.name) +
              '">' +
              folderSvg() +
              '<span class="ops-item-name">' +
              escapeHtml(p.name) +
              "</span></button>" +
              '<button type="button" class="ops-item-del" data-action="del" title="删除" aria-label="删除">×</button>' +
              "</li>"
            );
          })
          .join("") +
        "</ul>";
    }
    root.innerHTML =
      '<button type="button" class="ops-header" data-action="toggle" aria-expanded="' +
      (!collapsed ? "true" : "false") +
      '"><span>项目空间</span>' +
      '<svg class="ops-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="6 9 12 15 18 9"></polyline></svg>' +
      "</button>" +
      '<div class="ops-body">' +
      '<button type="button" class="ops-new" data-action="new">' +
      '<span class="ops-new-icon">+</span><span>新建项目</span>' +
      "</button>" +
      listHtml +
      "</div>";
    root.setAttribute("data-rendered", "1");
    // release on next tick so observer ignores our own write
    setTimeout(function () {
      applying = false;
    }, 0);
  }

  function bind(root) {
    if (root.getAttribute("data-bound") === "1") return;
    root.setAttribute("data-bound", "1");
    root.addEventListener("click", function (e) {
      var btn = e.target.closest("[data-action]");
      if (!btn || !root.contains(btn)) return;
      var action = btn.getAttribute("data-action");
      if (action === "toggle") {
        var next = localStorage.getItem(COLLAPSE_KEY) === "1" ? "0" : "1";
        localStorage.setItem(COLLAPSE_KEY, next);
        lastSig = "";
        render(root);
        return;
      }
      if (action === "new") {
        openNewProjectDialog(function (name) {
          var list = loadProjects();
          var item = { id: uid(), name: name, createdAt: Date.now() };
          list.unshift(item);
          saveProjects(list);
          localStorage.setItem(ACTIVE_KEY, item.id);
          lastSig = "";
          render(root);
        });
        return;
      }
      var row = btn.closest(".ops-item");
      if (!row) return;
      var id = row.getAttribute("data-id");
      if (action === "del") {
        var list2 = loadProjects().filter(function (p) {
          return p.id !== id;
        });
        saveProjects(list2);
        if (localStorage.getItem(ACTIVE_KEY) === id) {
          localStorage.removeItem(ACTIVE_KEY);
        }
        lastSig = "";
        render(root);
        return;
      }
      if (action === "open") {
        localStorage.setItem(ACTIVE_KEY, id);
        lastSig = "";
        render(root);
        try {
          if (!location.pathname.startsWith("/chat")) {
            history.pushState({}, "", "/chat");
            window.dispatchEvent(new PopStateEvent("popstate"));
          }
        } catch (err) {}
      }
    });
  }

  var scheduled = false;
  function mount() {
    scheduled = false;
    if (applying) return;
    var host = findNavHost();
    if (!host) return;
    var root = ensureRoot(host);
    bind(root);
    render(root);
  }

  function schedule() {
    if (applying || scheduled) return;
    scheduled = true;
    requestAnimationFrame(mount);
  }

  function start() {
    schedule();
    var obs = new MutationObserver(function (mutations) {
      if (applying) return;
      for (var i = 0; i < mutations.length; i++) {
        var m = mutations[i];
        // ignore mutations inside our own widget
        if (
          (m.target && m.target.closest && m.target.closest("#" + ROOT_ID)) ||
          (m.target && m.target.id === ROOT_ID)
        ) {
          continue;
        }
        schedule();
        return;
      }
    });
    obs.observe(document.documentElement, { childList: true, subtree: true });
    window.addEventListener("resize", schedule);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
