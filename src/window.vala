using Gtk;
using Singularity;
using Singularity.Widgets;

namespace Singularity.Apps {

    [GtkTemplate(ui = "/dev/sinty/demo/ui/main.ui")]
    public class DemoWindow : Singularity.Widgets.Window {

        // The window skeleton is declared in ui/main.vetro and placed into the
        // window's sidebar/content areas via set_sidebar()/set_content() below.
        [GtkChild] private unowned Singularity.Widgets.AppSidebar nav_sidebar;
        [GtkChild] private unowned Box content_root;
        [GtkChild] private unowned Stack content_stack;
        [GtkChild] private unowned ListBox nav_list;

        // Static page layouts declared in ui/pages.vetro; behaviour (dynamic
        // population, signals) is wired in the matching build_* method.
        private Gtk.Builder _pages;

        // Groups: name -> (icon, builder delegate)
        private struct Group {
            public string name;
            public string icon;
        }

        public DemoWindow(Gtk.Application app) {
            Object(application: app);
            set_title(_("libsingularity Demo"));
            set_default_size(1000, 680);

            // Place the template skeleton: nav into the sidebar slot (gets the
            // .window-sidebar gutter from the Window's sidebar area), the rest
            // into the content area.
            set_sidebar(nav_sidebar);
            set_sidebar_visible(true);
            set_content(content_root);

            // Register window-control bubbles (the bar is created lazily on the
            // first add_bubble_* call and carries the window controls), plus a
            // couple of demo actions to showcase the HoverControls bubble bar.
            add_bubble_icon("help-browser-symbolic", _("Documentation"), () => {
                try {
                    AppInfo.launch_default_for_uri("https://github.com/singularityos-lab/libsingularity", null);
                } catch (Error e) {
                    warning("Could not open URL: %s", e.message);
                }
            });
            add_bubble_icon("insert-link-symbolic", _("View Source"), () => {
                try {
                    AppInfo.launch_default_for_uri("https://github.com/singularityos-lab/singularity-demo", null);
                } catch (Error e) {
                    warning("Could not open URL: %s", e.message);
                }
            });

            _pages = new Gtk.Builder.from_resource("/dev/sinty/demo/ui/pages.ui");

            // Register all widget groups
            add_group("Welcome",           "go-home-symbolic",                   build_welcome_page);
            add_group("Controls",          "input-mouse-symbolic",               build_controls);
            add_group("Preferences Rows",  "preferences-system-symbolic",        build_preference_rows);
            add_group(_("PreferencesGroup"),  "view-list-symbolic",                 build_preferences_group);
            add_group("PreferencesPage",   "document-properties-symbolic",       build_preferences_page);
            add_group("PreferencesWindow", "window-new-symbolic",                build_preferences_window_demo);
            add_group("Navigation",        "go-next-symbolic",                   build_navigation);
            add_group("TabContainer",      "folder-symbolic",                    build_tab_container);
            add_group("StatusPage",        "dialog-information-symbolic",        build_status_page);
            add_group("Dialogs",           "dialog-question-symbolic",           build_dialogs);
            add_group("Visual / Charts",   "x-office-spreadsheet-symbolic",      build_visual);
            add_group("Chips",             "starred-symbolic",                   build_chips);
            add_group("HoverControls",     "media-playback-start-symbolic",      build_hover_controls);
            add_group("Context Menu",      "open-menu-symbolic",                 build_context_menu);
            add_group("Calendar Views",    "x-office-calendar-symbolic",         build_calendar);
            add_group("Toolbar",           "insert-object-symbolic",             build_toolbar_demo);
            add_group("Window",            "window-new-symbolic",                build_window_info);
            add_group("Keyring Test",      "dialog-password-symbolic",           build_keyring_test);
            add_group("OverlaySearch",     "system-search-symbolic",             build_overlay_search);
            add_group("Carousel",          "view-paged-symbolic",                build_carousel);
            add_group("CircularProgress",  "emblem-synchronizing-symbolic",      build_circular_progress);
            add_group("ConfirmDialog",     "dialog-warning-symbolic",            build_confirm_dialog);
            add_group("ConfirmRow",        "emblem-default-symbolic",            build_confirm_row);
            add_group("BrowserPill",       "web-browser-symbolic",               build_browser_pill);
            add_group("SourceView",        "text-x-script-symbolic",             build_source_view);
            add_group("TabBar",            "tab-new-symbolic",                   build_tab_bar);
            add_group("Color Schemes",     "preferences-color-symbolic",         build_color_schemes);

            // Select first row (Welcome)
            nav_list.select_row(nav_list.get_row_at_index(0));
            nav_list.row_selected.connect((row) => {
                if (row == null) return;
                string name = row.get_data<string>("page_name");
                content_stack.visible_child_name = name;
            });
        }

        // Sidebar helpers

        private delegate Widget PageBuilder();

        private void add_group(string label, string icon_name, owned PageBuilder builder) {
            string page_key = label.replace(" ", "_").replace("/", "_").down();

            // Nav row
            var row_box = new Box(Orientation.HORIZONTAL, 12);
            row_box.margin_start = 12;
            row_box.margin_end = 12;
            row_box.margin_top = 8;
            row_box.margin_bottom = 8;
            var icon = new Image.from_icon_name(icon_name);
            icon.pixel_size = 20;
            var lbl = new Label(label);
            lbl.halign = Align.START;
            lbl.hexpand = true;
            row_box.append(icon);
            row_box.append(lbl);

            var row = new ListBoxRow();
            row.set_child(row_box);
            row.set_data<string>("page_name", page_key);
            nav_list.append(row);

            content_stack.add_named(builder(), page_key);
        }

        // Page builders

        // Controls: layout in ui/pages.vetro; only the segmented control's
        // options are added here (imperative API with no markup equivalent).
        private Widget build_controls() {
            var seg = (SegmentedControl) _pages.get_object("controls_segment");
            seg.add_option("list", "List");
            seg.add_option("grid", "Grid");
            seg.add_option("columns", "Columns");
            return (Widget) _pages.get_object("controls_page");
        }

        // Preference Rows: group declared in ui/pages.vetro; rows added here
        // (SelectionRow/SearchableExpanderRow are not markup-friendly).
        private Widget build_preference_rows() {
            var g = (PreferencesGroup) _pages.get_object("preference_rows_group");
            g.add_row(new ActionRow(_("ActionRow"), _("A simple non-interactive row"), "folder-symbolic"));
            g.add_row(new SwitchRow(_("SwitchRow"), _("Toggle something on or off"), true));
            g.add_row(new SpinRow("SpinRow", "Pick a number", 1, 100, 1, 42));
            g.add_row(new EntryRow("EntryRow"));
            g.add_row(new PasswordRow("PasswordRow"));
            g.add_row(new EmailRow("EmailRow"));
            var expander = new ExpanderRow(_("ExpanderRow"), _("Click to expand"));
            expander.add_row(new ActionRow(_("Child row 1"), null));
            expander.add_row(new ActionRow(_("Child row 2"), null));
            g.add_row(expander);
            g.add_row(new SelectionRow(_("SelectionRow"), {_("Option A"), _("Option B"), _("Option C")}, _("Option A")));
            var ser = new SearchableExpanderRow(_("SearchableExpanderRow"), _("Search inside"));
            var ser_lbl1 = new Label(_("Result 1"));
            ser_lbl1.margin_top = 6;
            ser_lbl1.margin_bottom = 6;
            ser.list_box.append(ser_lbl1);
            var ser_lbl2 = new Label(_("Result 2"));
            ser_lbl2.margin_top = 6;
            ser_lbl2.margin_bottom = 6;
            ser.list_box.append(ser_lbl2);
            g.add_row(ser);

            return (Widget) _pages.get_object("preference_rows_page");
        }

        // PreferencesGroup: fully declared in ui/pages.vetro.
        private Widget build_preferences_group() {
            return (Widget) _pages.get_object("prefgroup_page");
        }

        // PreferencesPage: page scaffold in ui/pages.vetro; groups appended here
        // (g2 contains a SelectionRow which is not markup-friendly).
        private Widget build_preferences_page() {
            var page = (PreferencesPage) _pages.get_object("preferences_page_inner");

            var g1 = new PreferencesGroup(_("Section One"));
            g1.add_row(new SwitchRow(_("Enable feature"), null, true));
            g1.add_row(new SpinRow("Timeout", "Seconds before timeout", 1, 60, 1, 10));
            page.append_group(g1);

            var g2 = new PreferencesGroup(_("Section Two"));
            g2.add_row(new SelectionRow(_("Mode"), {_("Fast"), _("Balanced"), _("Power Save")}, _("Balanced")));
            g2.add_row(new EntryRow("Custom value"));
            page.append_group(g2);

            return (Widget) _pages.get_object("preferences_page_page");
        }

        // PreferencesWindow: static layout in ui/pages.vetro; button handler here.
        private Widget build_preferences_window_demo() {
            var btn = (Button) _pages.get_object("preferences_window_open_btn");
            btn.clicked.connect(() => {
                var g = new PreferencesGroup(_("Demo group"));
                g.add_row(new SwitchRow(_("Option A"), null, true));
                g.add_row(new EntryRow("Some setting"));
                var pg = new PreferencesPage();
                pg.append_group(g);
                var pw = new PreferencesWindow(application, pg);
                pw.present();
            });
            return (Widget) _pages.get_object("preferences_window_page");
        }

        // Navigation: fully declared in ui/pages.vetro.
        private Widget build_navigation() {
            return (Widget) _pages.get_object("navigation_page");
        }

        // TabContainer: scaffold in ui/pages.vetro; tabs added here (add_tab).
        private Widget build_tab_container() {
            var tc = (TabContainer) _pages.get_object("tab_container_tc");
            for (int i = 1; i <= 3; i++) {
                var page = new Box(Orientation.VERTICAL, 0);
                page.halign = Align.CENTER;
                page.valign = Align.CENTER;
                var lbl = new Label(_("Content of Tab %d").printf(i));
                lbl.add_css_class("title-2");
                page.append(lbl);
                tc.add_tab(page, "Tab %d".printf(i));
            }
            return (Widget) _pages.get_object("tab_container_page");
        }

        // StatusPage: fully declared in ui/pages.vetro.
        private Widget build_status_page() {
            return (Widget) _pages.get_object("statuspage_page");
        }

        // WelcomePage: kept in Vala. WelcomePage.add_action takes a callback
        // per action, so there is no clean markup equivalent.
        private Widget build_welcome_page() {
            var wp = new WelcomePage();
            wp.app_icon_name = "dev.sinty.demo";
            wp.title = _("Singularity Demo");
            wp.subtitle = _("Browse the sidebar to explore all available widgets.\nClick the actions below to see WelcomePage in action.");
            wp.hexpand = true;
            wp.vexpand = true;
            wp.add_action("x-office-document", "Open Documentation", "View the full libsingularity API reference", () => {
                try {
                    AppInfo.launch_default_for_uri("https://github.com/singularityos-lab/libsingularity", null);
                } catch (Error e) {
                    warning("Could not open URL: %s", e.message);
                }
            });
            wp.add_action("text-html", "View Source", "Browse the demo app source code on GitHub", () => {
                try {
                    AppInfo.launch_default_for_uri("https://github.com/singularityos-lab/singularity-demo", null);
                } catch (Error e) {
                    warning("Could not open URL: %s", e.message);
                }
            });
            return wp;
        }

        // Dialogs: static layout in ui/pages.vetro; button handler here.
        private Widget build_dialogs() {
            var btn = (Button) _pages.get_object("dialogs_open_btn");
            btn.clicked.connect(() => {
                var dlg = new AppDialog(application, true);
                dlg.set_title(_("Sample Dialog"));
                dlg.transient_for = this;
                var lbl = new Label(_("This is an AppDialog.\nIt has a custom title bar and close button."));
                lbl.wrap = true;
                lbl.margin_top = 24;
                lbl.margin_bottom = 24;
                lbl.margin_start = 24;
                lbl.margin_end = 24;
                dlg.content_box.append(lbl);
                dlg.present();
            });
            return (Widget) _pages.get_object("dialogs_page");
        }

        // Visual / Charts: title scaffold in ui/pages.vetro; charts, colour
        // controls and chip row built here (random data + live repaint).
        private Widget build_visual() {
            var box = (Box) _pages.get_object("visual_box");

            var spark = new SparkLine(30);
            spark.set_size_request(300, 60);
            for (int i = 0; i < 30; i++) spark.push((double)(GLib.Random.int_range(10, 90)) / 100.0);

            var bar = new MiniBar();
            bar.set_size_request(300, 40);
            bar.set_value(0.65);

            var ctrl_group = new PreferencesGroup(_("Colour source"));
            var custom_row = new SwitchRow(_("Use custom colour"), _("Off = system accent"), false);
            ctrl_group.add_row(custom_row);

            var picker_row = new ActionRow(_("Custom colour"), _("Pick a hue, charts repaint live"), null);
            var picker     = new ColorPickerButton();
            picker.valign  = Align.CENTER;
            picker_row.add_suffix(picker);
            picker_row.visible = false;
            ctrl_group.add_row(picker_row);

            custom_row.switch_btn.notify["active"].connect(() => {
                bool on = custom_row.switch_btn.active;
                picker_row.visible = on;
                if (on) {
                    var rgba = picker.color;
                    string hex = "#%02x%02x%02x".printf(
                        (int)(rgba.red   * 255),
                        (int)(rgba.green * 255),
                        (int)(rgba.blue  * 255));
                    spark.set_color(hex);
                    bar.set_color(hex);
                } else {
                    spark.set_color(null);
                    bar.set_color(null);
                }
            });

            picker.color_changed.connect((rgba) => {
                if (!custom_row.switch_btn.active) return;
                string hex = "#%02x%02x%02x".printf(
                    (int)(rgba.red   * 255),
                    (int)(rgba.green * 255),
                    (int)(rgba.blue  * 255));
                spark.set_color(hex);
                bar.set_color(hex);
            });

            box.append(ctrl_group);

            var sl_lbl = new Label(_("SparkLine:"));
            sl_lbl.halign = Align.START;
            box.append(sl_lbl);
            box.append(spark);

            var mb_lbl = new Label(_("MiniBar:"));
            mb_lbl.halign = Align.START;
            mb_lbl.margin_top = 16;
            box.append(mb_lbl);
            box.append(bar);

            var ch_lbl = new Label(_("Chip:"));
            ch_lbl.halign = Align.START;
            ch_lbl.margin_top = 16;
            box.append(ch_lbl);
            var chip_row = new Box(Orientation.HORIZONTAL, 8);
            chip_row.append(new Chip("Running", "media-playback-start-symbolic"));
            chip_row.append(new Chip("Idle", null));
            chip_row.append(new Chip("Error", "dialog-error-symbolic"));
            box.append(chip_row);

            return (Widget) _pages.get_object("visual_page");
        }

        // Chips: layout in ui/pages.vetro; ChipBar populated here (add_chip).
        private Widget build_chips() {
            var cb = (ChipBar) _pages.get_object("chips_chipbar");
            cb.add_chip("alpha", "Alpha");
            cb.add_chip("beta", "Beta");
            cb.add_chip("gamma", "Gamma");
            return (Widget) _pages.get_object("chips_page");
        }

        // HoverControls: scaffold in ui/pages.vetro; control built here
        // (set_content + add_control have no markup equivalent).
        private Widget build_hover_controls() {
            var box = (Box) _pages.get_object("hover_controls_box");

            var hc = new HoverControls();
            hc.set_size_request(400, 200);

            // Content
            var inner = new Box(Orientation.VERTICAL, 0);
            inner.hexpand = true;
            inner.vexpand = true;
            inner.halign = Align.CENTER;
            inner.valign = Align.CENTER;
            var _w21 = new Label(_("Hover over me")) ;
            _w21.add_css_class("title-2");
            inner.append(_w21);
            hc.set_content(inner);

            var btn1 = new Button.from_icon_name("document-edit-symbolic");
            btn1.tooltip_text = _("Edit");
            hc.add_control(btn1);

            var btn2 = new Button.from_icon_name("user-trash-symbolic");
            btn2.tooltip_text = _("Delete");
            hc.add_control(btn2);

            box.append(hc);

            return (Widget) _pages.get_object("hover_controls_page");
        }

        // Context Menu: static layout in ui/pages.vetro; menu created on click.
        // Stored as a field to keep it alive past popup().
        private ContextMenu? _demo_ctx_menu = null;

        private Widget build_context_menu() {
            var btn = (Button) _pages.get_object("context_menu_btn");
            btn.clicked.connect(() => {
                _demo_ctx_menu = new ContextMenu(btn);
                _demo_ctx_menu.add_item("New File",   "document-new-symbolic",     () => {});
                _demo_ctx_menu.add_item("Open",       "folder-open-symbolic",      () => {});
                _demo_ctx_menu.add_separator();
                _demo_ctx_menu.add_item("Delete",     "user-trash-symbolic",       () => {});
                _demo_ctx_menu.closed.connect(() => { _demo_ctx_menu.unparent(); _demo_ctx_menu = null; });
                _demo_ctx_menu.popup();
            });
            return (Widget) _pages.get_object("context_menu_page");
        }

        // Calendar Views: scaffold in ui/pages.vetro; CalendarNavPicker inserted here.
        private Widget build_calendar() {
            var box = (Box) _pages.get_object("calendar_box");
            var label = (Widget) _pages.get_object("calendar_nav_label");
            var nav = new CalendarNavPicker();
            box.insert_child_after(nav, label);
            return (Widget) _pages.get_object("calendar_page");
        }

        // ToolBar: static layout in ui/pages.vetro; title set here (set_title()
        // is the only API, ToolBar has no title construct property).
        private Widget build_toolbar_demo() {
            var tb = (ToolBar) _pages.get_object("toolbar_demo_bar");
            tb.set_title(_("My Page"));
            return (Widget) _pages.get_object("toolbar_page");
        }

        // Keyring test: talks to the Secret Service on the bus via libsecret.
        private Secret.Schema? _kr_schema = null;
        private TextView?      _kr_log    = null;

        private Widget build_keyring_test() {
            var box = (Box) _pages.get_object("keyring_box");

            _kr_schema = new Secret.Schema("dev.sinty.demo.test",
                Secret.SchemaFlags.NONE,
                "service",  Secret.SchemaAttributeType.STRING,
                "username", Secret.SchemaAttributeType.STRING);

            var form = new PreferencesGroup(_("Test entry"));
            var svc_row  = new EntryRow("Service");
            var user_row = new EntryRow("Username");
            var pass_row = new PasswordRow("Secret");
            form.add_row(svc_row);
            form.add_row(user_row);
            form.add_row(pass_row);
            svc_row.text  = "sinty.demo";
            user_row.text = Environment.get_user_name();
            box.append(form);

            var btnbar = new Box(Orientation.HORIZONTAL, 8);
            btnbar.margin_top = 4;
            var store_btn  = new Button.with_label(_("Store"));
            store_btn.add_css_class("suggested-action");
            var lookup_btn = new Button.with_label(_("Lookup"));
            var clear_btn  = new Button.with_label(_("Delete"));
            var list_btn   = new Button.with_label(_("List Collections"));
            btnbar.append(store_btn);
            btnbar.append(lookup_btn);
            btnbar.append(clear_btn);
            btnbar.append(list_btn);
            box.append(btnbar);

            _kr_log = new TextView();
            _kr_log.editable  = false;
            _kr_log.monospace = true;
            _kr_log.wrap_mode = WrapMode.WORD_CHAR;
            var log_scroll = new ScrolledWindow();
            log_scroll.set_child(_kr_log);
            log_scroll.height_request = 220;
            log_scroll.add_css_class("card");
            box.append(log_scroll);

            store_btn.clicked.connect(() => {
                try {
                    Secret.password_store_sync(_kr_schema,
                        Secret.COLLECTION_DEFAULT,
                        "Demo entry (%s / %s)".printf(svc_row.text, user_row.text),
                        pass_row.text, null,
                        "service",  svc_row.text,
                        "username", user_row.text);
                    kr_log("STORE ok: %s / %s".printf(svc_row.text, user_row.text));
                } catch (Error e) {
                    kr_log("STORE failed: " + e.message);
                }
            });

            lookup_btn.clicked.connect(() => {
                try {
                    string? pwd = Secret.password_lookup_sync(_kr_schema, null,
                        "service",  svc_row.text,
                        "username", user_row.text);
                    if (pwd == null)
                        kr_log("LOOKUP: no entry for %s / %s".printf(svc_row.text, user_row.text));
                    else
                        kr_log("LOOKUP ok: %s / %s -> \"%s\"".printf(svc_row.text, user_row.text, pwd));
                } catch (Error e) {
                    kr_log("LOOKUP failed: " + e.message);
                }
            });

            clear_btn.clicked.connect(() => {
                try {
                    bool removed = Secret.password_clear_sync(_kr_schema, null,
                        "service",  svc_row.text,
                        "username", user_row.text);
                    kr_log("DELETE: %s".printf(removed ? "removed" : "no entry"));
                } catch (Error e) {
                    kr_log("DELETE failed: " + e.message);
                }
            });

            list_btn.clicked.connect(() => {
                try {
                    var svc_obj = Secret.Service.get_sync(Secret.ServiceFlags.LOAD_COLLECTIONS);
                    var colls   = svc_obj.get_collections();
                    var sb = new StringBuilder();
                    sb.append("Collections (");
                    sb.append(colls.length().to_string());
                    sb.append("):\n");
                    foreach (var c in colls) {
                        sb.append("  - ");
                        sb.append(c.label);
                        sb.append(c.locked ? "  [locked]\n" : "  [unlocked]\n");
                    }
                    kr_log(sb.str);
                } catch (Error e) {
                    kr_log("LIST failed: " + e.message);
                }
            });

            return (Widget) _pages.get_object("keyring_test_page");
        }

        private void kr_log(string line) {
            if (_kr_log == null) return;
            var buf = _kr_log.buffer;
            Gtk.TextIter end;
            buf.get_end_iter(out end);
            buf.insert(ref end, line + "\n", -1);
            buf.get_end_iter(out end);
            _kr_log.scroll_to_iter(end, 0, true, 0, 0);
        }

        // OverlaySearch: floating spotlight / palette card, added as a
        // Gtk.Overlay child so it floats above the page content.
        private OverlaySearch? _demo_overlay = null;
        // OverlaySearch: page content in ui/pages.vetro; the floating card is
        // added as a Gtk.Overlay child here so it floats above the content.
        private Widget build_overlay_search() {
            var content = (Widget) _pages.get_object("overlay_search_content");
            var btn = (Button) _pages.get_object("overlay_search_btn");

            _demo_overlay = new OverlaySearch();
            _demo_overlay.placeholder = "Type a command…";
            var items = new OverlaySearchItem[] {
                new OverlaySearchItem("new",   "document-new-symbolic",     "New File",  "Create a blank document"),
                new OverlaySearchItem("open",  "document-open-symbolic",    "Open…",     "Open from disk", "Ctrl+O"),
                new OverlaySearchItem("save",  "document-save-symbolic",    "Save",      "Save current file", "Ctrl+S"),
                new OverlaySearchItem("quit",  "application-exit-symbolic", "Quit",      "Close the app",   "Ctrl+Q"),
            };
            _demo_overlay.set_items(items);
            _demo_overlay.close_requested.connect(() => _demo_overlay.close());
            _demo_overlay.item_activated.connect((_id)  => _demo_overlay.close());

            btn.clicked.connect(() => _demo_overlay.open());

            var page_overlay = new Gtk.Overlay();
            page_overlay.set_child(content);
            page_overlay.add_overlay(_demo_overlay);
            return page_overlay;
        }

        // Carousel: scaffold in ui/pages.vetro; slides + nav built here.
        private Widget build_carousel() {
            var box = (Box) _pages.get_object("carousel_box");
            var car = new Carousel();
            car.set_size_request(-1, 240);
            string[] hues = { "#E36464", "#64C4E3", "#A2E364", "#E3C264" };
            for (int i = 0; i < hues.length; i++) {
                var page = new Gtk.Box(Orientation.VERTICAL, 0);
                page.hexpand = true; page.vexpand = true;
                page.halign = Align.FILL; page.valign = Align.FILL;
                var l = new Label(_("Page %d").printf(i + 1));
                l.add_css_class("title-1");
                page.append(l);
                try {
                    var css = new CssProvider();
                    css.load_from_string(".carousel-demo-%d { background-color: %s; border-radius: 12px; padding: 24px; color: white; }"
                        .printf(i, hues[i]));
                    page.add_css_class("carousel-demo-%d".printf(i));
                    page.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch {}
                car.append_page(page);
            }
            box.append(car);

            var ctrl_row = new Box(Orientation.HORIZONTAL, 8);
            ctrl_row.margin_top = 8;
            var prev = new Button.from_icon_name("go-previous-symbolic");
            var next = new Button.from_icon_name("go-next-symbolic");
            prev.clicked.connect(() => {
                uint p = (car.position == 0) ? car.n_pages - 1 : car.position - 1;
                car.scroll_to_index(p, true);
            });
            next.clicked.connect(() => {
                uint p = (car.position + 1) % car.n_pages;
                car.scroll_to_index(p, true);
            });
            ctrl_row.append(prev); ctrl_row.append(next);
            box.append(ctrl_row);
            return (Widget) _pages.get_object("carousel_page");
        }

        // CircularProgress: scaffold in ui/pages.vetro; rings added here.
        private Widget build_circular_progress() {
            var row = (Box) _pages.get_object("circular_progress_row");
            double[] vals = { 0.25, 0.5, 0.75, 1.0 };
            foreach (var v in vals) {
                var cp = new CircularProgress(72);
                cp.fraction = v;
                cp.label    = "%d%%".printf((int)(v * 100));
                row.append(cp);
            }
            return (Widget) _pages.get_object("circular_progress_page");
        }

        // ConfirmDialog: static layout in ui/pages.vetro; dialog created on click.
        private Widget build_confirm_dialog() {
            var btn = (Button) _pages.get_object("confirm_dialog_open_btn");
            btn.clicked.connect(() => {
                var d = new ConfirmDialog(application,
                    "Delete this file?",
                    "dialog-warning-symbolic",
                    "This action cannot be undone.",
                    "Delete",
                    ConfirmDialog.ActionStyle.DESTRUCTIVE);
                d.set_secondary("Cancel", ConfirmDialog.ActionStyle.DEFAULT);
                d.response.connect((r) => {
                    string s = (r == ConfirmDialog.Response.PRIMARY) ? "PRIMARY"
                             : (r == ConfirmDialog.Response.SECONDARY) ? "SECONDARY" : "CANCEL";
                    message("ConfirmDialog response: %s", s);
                });
                d.present();
            });
            return (Widget) _pages.get_object("confirm_dialog_page");
        }

        // ConfirmRow: group scaffold in ui/pages.vetro; row added here.
        private Widget build_confirm_row() {
            var g = (PreferencesGroup) _pages.get_object("confirm_row_group");
            var cr = new ConfirmRow("Reset settings", "Click then confirm to wipe everything", "edit-clear-symbolic");
            g.add_row(cr);
            return (Widget) _pages.get_object("confirm_row_page");
        }

        // BrowserPill: scaffold in ui/pages.vetro; pill built here (update_from_uri).
        private Widget build_browser_pill() {
            var box = (Box) _pages.get_object("browser_pill_box");
            var pill = new BrowserPill();
            pill.update_from_uri("https://example.com/some/path");
            pill.halign = Align.START;
            box.append(pill);
            return (Widget) _pages.get_object("browser_pill_page");
        }

        // SourceView: scaffold in ui/pages.vetro; editor built here.
        private Widget build_source_view() {
            var box = (Box) _pages.get_object("source_view_box");
            var sv = new SourceView();
            sv.buffer.set_text("// Singularity SourceView\n// Monospace, accent caret, accent selection.\n\nfn main() {\n    println(\"hello\");\n}", -1);
            sv.set_size_request(-1, 240);
            sv.top_margin = 12;
            var scroll = new ScrolledWindow();
            scroll.set_child(sv);
            scroll.hexpand = true; scroll.vexpand = true;
            scroll.add_css_class("card");
            scroll.set_size_request(-1, 260);
            box.append(scroll);
            return (Widget) _pages.get_object("source_view_page");
        }

        // TabBar: scaffold in ui/pages.vetro; strip + notebook built here.
        private Widget build_tab_bar() {
            var box = (Box) _pages.get_object("tab_bar_box");
            var nb = new Notebook();
            string[] names = { "Home", "Inbox", "Send" };
            foreach (var n in names) {
                var page = new Label(_("Content of ") + n);
                page.margin_top = 12;
                nb.append_page(page, new Label(n));
            }
            var tb = new TabBar(nb);
            box.append(tb);
            box.append(nb);
            return (Widget) _pages.get_object("tab_bar_page");
        }

        // ColorSchemes: group scaffold in ui/pages.vetro; ColorSchemeRow added here.
        private Widget build_color_schemes() {
            var themes = new Gee.ArrayList<ColorTheme>();
            themes.add(new ColorTheme("dracula", "Dracula",  "#282a36", "#f8f8f2",
                {"#000000","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#bbbbbb"}));
            themes.add(new ColorTheme("nord", "Nord",       "#2e3440", "#d8dee9",
                {"#3b4252","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0"}));
            themes.add(new ColorTheme("onedark", "One Dark","#282c34", "#abb2bf",
                {"#000000","#e06c75","#98c379","#e5c07b","#61afef","#c678dd","#56b6c2","#abb2bf"}));

            var g = (PreferencesGroup) _pages.get_object("color_schemes_group");
            g.add_row(new ColorSchemeRow("Scheme", themes, "nord"));
            return (Widget) _pages.get_object("color_schemes_page");
        }

        // Window info: fully declared in ui/pages.vetro.
        private Widget build_window_info() {
            return (Widget) _pages.get_object("window_info_page");
        }
    }
}
