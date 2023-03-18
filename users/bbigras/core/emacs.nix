{ pkgs, config, ... }:

let
  pcfg = config.programs.emacs.init.usePackage;
in
{
  home.packages = with pkgs; [
    samba # for tramp
  ];
  programs.emacs = {
    enable = true;

    # TODO: use pkgs.emacsPgtkNativeComp with wayland
    package = pkgs.lib.mkDefault pkgs.emacsUnstable;

    init = {
      enable = true;

      packageQuickstart = false;
      recommendedGcSettings = true;
      usePackageVerbose = false;

      earlyInit = ''
        ;; Disable some GUI distractions. We set these manually to avoid starting
        ;; the corresponding minor modes.
        (push '(menu-bar-lines . 0) default-frame-alist)
        (push '(tool-bar-lines . nil) default-frame-alist)
        (push '(vertical-scroll-bars . nil) default-frame-alist)

        ;; Set up fonts early.
        (set-face-attribute 'default
                            nil
                            :height 105
                            :family "Source Code Pro")
        (set-face-attribute 'fixed-pitch nil :font "Source Code Pro" :height 100)
        (set-face-attribute 'variable-pitch nil :font "Cantarell" :height 150 :weight 'regular)

        ;; Configure color theme and modeline in early init to avoid flashing
        ;; during start.
        (require 'nimbus-theme)
        (load-theme 'nimbus t)

        (require 'doom-modeline)
        (setq doom-modeline-buffer-file-name-style 'truncate-except-project)
        (doom-modeline-mode)
      '';

      prelude = ''
        ;; Disable startup message.
        (setq inhibit-startup-screen t
              inhibit-startup-echo-area-message (user-login-name))

        (setq initial-major-mode 'fundamental-mode
              initial-scratch-message nil)

        ;; Don't blink the cursor.
        (setq blink-cursor-mode nil)

        ;; Set frame title.
        (setq frame-title-format
              '("" invocation-name ": "(:eval
                                        (if (buffer-file-name)
                                            (abbreviate-file-name (buffer-file-name))
                                          "%b"))))

        ;; Make sure the mouse cursor is visible at all times.
        (set-face-background 'mouse "#ffffff")

        ;; Accept 'y' and 'n' rather than 'yes' and 'no'.
        (defalias 'yes-or-no-p 'y-or-n-p)

        ;; Don't want to move based on visual line.
        (setq line-move-visual nil)

        ;; Stop creating backup and autosave files.
        (setq make-backup-files nil
              auto-save-default nil)

        ;; Default is 4k, which is too low for LSP.
        (setq read-process-output-max (* 1024 1024))

        ;; Always show line and column number in the mode line.
        (line-number-mode)
        (column-number-mode)

        ;; Enable some features that are disabled by default.
        (put 'narrow-to-region 'disabled nil)

        ;; Typically, I only want spaces when pressing the TAB key. I also
        ;; want 4 of them.
        (setq-default indent-tabs-mode nil
                      tab-width 4
                      c-basic-offset 4)

        ;; Trailing white space are banned!
        (setq-default show-trailing-whitespace t)

        ;; Use one space to end sentences.
        (setq sentence-end-double-space nil)

        ;; I typically want to use UTF-8.
        (prefer-coding-system 'utf-8)

        ;; Nicer handling of regions.
        (transient-mark-mode 1)

        ;; Make moving cursor past bottom only scroll a single line rather
        ;; than half a page.
        (setq scroll-step 1
              scroll-conservatively 5)

        ;; Enable highlighting of current line.
        (global-hl-line-mode 1)

        ;; Improved handling of clipboard in GNU/Linux and otherwise.
        (setq select-enable-clipboard t
              select-enable-primary t
              save-interprogram-paste-before-kill t)

        ;; Pasting with middle click should insert at point, not where the
        ;; click happened.
        (setq mouse-yank-at-point t)

        ;; Enable a few useful commands that are initially disabled.
        (put 'upcase-region 'disabled nil)
        (put 'downcase-region 'disabled nil)

        ;;(setq custom-file (locate-user-emacs-file "custom.el"))
        ;;(load custom-file)

        ;; When finding file in non-existing directory, offer to create the
        ;; parent directory.
        (defun with-buffer-name-prompt-and-make-subdirs ()
          (let ((parent-directory (file-name-directory buffer-file-name)))
            (when (and (not (file-exists-p parent-directory))
                       (y-or-n-p (format "Directory `%s' does not exist! Create it? " parent-directory)))
              (make-directory parent-directory t))))

        (add-to-list 'find-file-not-found-functions #'with-buffer-name-prompt-and-make-subdirs)

        ;; Don't want to complete .hi files.
        (add-to-list 'completion-ignored-extensions ".hi")

        (defun rah-disable-trailing-whitespace-mode ()
          (setq show-trailing-whitespace nil))

        ;; Shouldn't highlight trailing spaces in terminal mode.
        (add-hook 'term-mode #'rah-disable-trailing-whitespace-mode)
        (add-hook 'term-mode-hook #'rah-disable-trailing-whitespace-mode)

        ;; Ignore trailing white space in compilation mode.
        (add-hook 'compilation-mode-hook #'rah-disable-trailing-whitespace-mode)

        (defun rah-prog-mode-setup ()
          ;; Use a bit wider fill column width in programming modes
          ;; since we often work with indentation to start with.
          (setq fill-column 80))

        (add-hook 'prog-mode-hook #'rah-prog-mode-setup)

        ;(defun rah-sort-lines-ignore-case ()
        ;  (interactive)
        ;  (let ((sort-fold-case t))
        ;    (call-interactively 'sort-lines)))

        ;; MY STUFF
        (setq auth-sources '((:source "~/.authinfo.gpg")))
        ;;(setq max-lisp-eval-depth 10000)
        ;;(setq max-specpdl-size 13000)
        (delete-selection-mode 1)
        (setq compilation-scroll-output t)
        ;;(setq compilation-scroll-output 'first-error)

        (setq org-directory "~/dev/org-mode")
        (setq custom-file (expand-file-name (concat "custom-" (system-name) ".el") "~/dev/emacs"))
        (load custom-file)

        (setq backup-directory-alist '(("." . "~/.config/emacs/backups")))
        (with-eval-after-load 'tramp
        (add-to-list 'tramp-backup-directory-alist
                     (cons tramp-file-name-regexp nil)))

        (setq delete-old-versions -1)
        (setq version-control t)
        (setq vc-make-backup-files t)
        (setq auto-save-file-name-transforms '((".*" "~/.config/emacs/auto-save-list/" t)))

        (setq savehist-file "~/.config/emacs/savehist")
        (savehist-mode 1)
        (setq history-length t)
        (setq history-delete-duplicates t)
        (setq savehist-save-minibuffer-history 1)
        (setq savehist-additional-variables
              '(kill-ring
                search-ring
                regexp-search-ring))

        (setq native-comp-async-report-warnings-errors nil)
      '';

      usePackage = {
        abbrev = {
          enable = true;
          command = [ "abbrev-mode" ];
        };

        ace-link = {
          enable = true;
          after = [ "org" ];
          config = ''
            (ace-link-setup-default)
            (define-key org-mode-map (kbd "M-o") 'ace-link-org)
          '';
        };

        adaptive-wrap = {
          enable = true;
          command = [ "adaptive-wrap-prefix-mode" ];
        };

        bufler.enable = true;

        # Save and restore frames and windows with their buffers in Emacs
        burly.enable = true;

        mark-thing-at = {
          enable = true;
          #         config = ''
          # (mark-thing-at-make-keybindings "\C-xm")
          #         '';
        };

        ansi-color = {
          enable = true;
          command = [ "ansi-color-apply-on-region" ];
        };

        autorevert = {
          enable = true;
          command = [ "auto-revert-mode" ];
        };

        # back-button = {
        #   enable = true;
        #   defer = 1;
        #   command = [ "back-button-mode" ];
        #   config = ''
        #     (back-button-mode 1)

        #     ;; Make mark ring larger.
        #     (setq global-mark-ring-max 50)
        #   '';
        # };

        nimbus-theme = {
          enable = true;
          extraConfig = ":disabled";
        };

        dogears = {
          enable = true;
          bind = {
            "M-g d" = "dogears-go";
            "M-g M-b" = "dogears-back";
            "M-g M-f" = "dogears-forward";
            "M-g M-d" = "dogears-list";
            "M-g M-D" = "dogears-sidebar";
          };
          config = ''
            (dogears-mode)
          '';
        };

        browse-at-remote = {
          enable = true;
          bind = {
            "C-c g g" = "browse-at-remote";
          };
        };

        # From https://github.com/mlb-/emacs.d/blob/a818e80f7790dffa4f6a775987c88691c4113d11/init.el#L472-L482
        compile = {
          enable = true;
          defer = true;
          after = [ "ansi-color" ];
          hook = [
            ''
              (compilation-filter . (lambda ()
                                      (when (eq major-mode 'compilation-mode)
                                        (ansi-color-apply-on-region compilation-filter-start (point-max)))))
            ''
          ];
        };

        gnuplot.enable = true;

        copy-as-format = {
          enable = true;
          command = [
            "copy-as-format"
            "copy-as-format-asciidoc"
            "copy-as-format-bitbucket"
            "copy-as-format-disqus"
            "copy-as-format-github"
            "copy-as-format-gitlab"
            "copy-as-format-hipchat"
            "copy-as-format-html"
            "copy-as-format-jira"
            "copy-as-format-markdown"
            "copy-as-format-mediawiki"
            "copy-as-format-org-mode"
            "copy-as-format-pod"
            "copy-as-format-rst"
            "copy-as-format-slack"
          ];
        };


        # https://github.com/bbatsov/crux
        crux = {
          enable = true;
          bind = {
            "C-c d" = "crux-duplicate-current-line-or-region";
            "C-c M-d" = "crux-duplicate-and-comment-current-line-or-region";

            # "C-k" = "crux-smart-kill-line";
            "C-k" = "crux-kill-and-join-forward";

            "C-S-RET" = "crux-smart-open-line-above";
            "S-RET" = "crux-smart-open-line";
            "C-x 4 t" = "crux-transpose-windows";
            "C-c D" = "crux-delete-file-and-buffer";
            # "C-c r" = "crux-rename-file-and-buffer";
            "C-c TAB" = "crux-indent-rigidly-and-copy-to-clipboard";
            # "Super-j" = "crux-top-join-line";
            # "C-Backspace" = "crux-kill-line-backwards";
            "M-o" = "crux-other-window-or-switch-buffer";
          };
        };

        svelte-mode = {
          enable = true;
        };

        prettier-js = {
          enable = true;
          after = [ "web-mode" ];
          config = ''
            (add-hook 'web-mode-hook #'prettier-js-mode)
          '';
        };

        ws-butler = {
          enable = true;
          hook = [
            "(text-mode . ws-butler-mode)"
            "(prog-mode . ws-butler-mode)"
          ];
        };

        centaur-tabs = {
          enable = true;
          config = ''
            (centaur-tabs-mode t)
            (centaur-tabs-headline-match)
            (setq centaur-tabs-set-icons t)
            (setq centaur-tabs-gray-out-icons 'buffer)
            (setq centaur-tabs-set-bar 'left)
            (setq centaur-tabs-set-modified-marker t)
            (centaur-tabs-group-by-projectile-project)
          '';
          bind = {
            "C-<prior>" = "centaur-tabs-backward";
            "C-<next>" = "centaur-tabs-forward";
          };
        };

        calc = {
          enable = true;
          command = [ "calc" ];
          config = ''
            (setq calc-date-format '(YYYY "-" MM "-" DD " " Www " " hh ":" mm ":" ss))
          '';
        };

        deadgrep = {
          enable = true;
          bind = {
            "C-x f" = "deadgrep";
          };
        };

        envrc = {
          enable = true;
          defer = 1;
          command = [ "envrc-global-mode" ];
          config = ''
            (envrc-global-mode 1)
          '';
        };

        tramp.enable = false;

        dockerfile-mode.enable = true;

        alert = {
          enable = true;
          config = ''
            (setq alert-default-style 'notifications)
          '';
        };

        doom-modeline = {
          enable = true;
          extraConfig = ":disabled";
        };

        drag-stuff = {
          enable = true;
          bind = {
            "M-<up>" = "drag-stuff-up";
            "M-<down>" = "drag-stuff-down";
          };
        };

        ediff = {
          enable = true;
          defer = true;
          config = ''
            (setq ediff-window-setup-function 'ediff-setup-windows-plain)
          '';
        };

        diff-hl = {
          enable = true;
          config = "(global-diff-hl-mode)";
        };

        eldoc = {
          enable = true;
          command = [ "eldoc-mode" ];
        };

        eldoc-box = {
          enable = true;
        };

        # Enable Electric Indent mode to do automatic indentation on RET.
        electric = {
          enable = true;
          command = [ "electric-indent-local-mode" ];
          hook = [
            "(prog-mode . electric-indent-mode)"

            # Disable for some modes.
            "(nix-mode . (lambda () (electric-indent-local-mode -1)))"
          ];
        };

        fira-code-mode = {
          enable = true;
          hook = [ "prog-mode" ];
          config = ''
            (fira-code-mode-set-font)
          '';
        };

        gcmh = {
          enable = true;
          defer = 1;
          command = [ "gcmh-mode" ];
          config = ''
            (setq gcmh-idle-delay 'auto)
            (gcmh-mode)
          '';
        };

        hcl-mode.enable = true;

        #     org-journal = {
        #       enable = true;
        #       bind = {
        #         "C-c n j" = "org-journal-new-entry";
        #       };
        #       config = ''
        # (setq org-journal-date-prefix "#+TITLE: ")
        # (setq org-journal-file-format "%Y-%m-%d.org")
        # (setq org-journal-date-format "%A, %d %B %Y")
        #       '';
        #     };

        org-roam = {
          enable = true;
          hook = [ "(after-init . org-roam-db-autosync-mode)" ];
          config = ''
            (setq org-roam-directory "~/dev/org-mode/notes")
          '';
          bind = {
            "C-c n f" = "org-roam-node-find";
            "C-c n r" = "org-roam-node-random";
            "C-c n t" = "org-roam-dailies-find-today";
          };

          bindLocal = {
            org-mode-map = {
              "C-c n i" = "org-roam-node-insert";
              "C-c n o" = "org-id-get-create";
              "C-c n t" = "org-roam-tag-add";
              "C-c n a" = "org-roam-alias-add";
              "C-c n l" = "org-roam-buffer-toggle";
            };
          };
        };

        org-roam-dailies = {
          enable = true;
          after = [ "org-roam" ];
          config = ''
            (setq org-roam-dailies-directory "journal/")

            (setq org-roam-dailies-capture-templates
                  '(("d" "default" entry
                     "* %?"
                     :target (file+head "%<%Y-%m-%d>.org"
                                        "#+title: %<%Y-%m-%d>\n"))))
          '';
        };

        org-download = {
          enable = true;
          after = [ "org" ];
          bindLocal = {
            org-mode-map = {
              "s-Y" = "org-download-screenshot";
              "s-y" = "org-download-yank";
            };
          };
        };

        rainbow-mode = {
          enable = true;
          defer = 1;
          hook = [
            ''(org-mode
         emacs-lisp-mode
         web-mode
         typescript-mode
         js2-mode)''
          ];
        };

        rainbow-delimiters = {
          enable = true;
          hook = [ "(prog-mode . rainbow-delimiters-mode)" ];
        };

        org-tempo = {
          enable = true;
          package = "org";
        };

        hass = {
          enable = true;
          config = ''
            (require 'hass-dash)

            (setq hass-dash-layouts
                  '((default . ; Key for dashboard. Shows up with completing-read when calling `hass-dash-open'.
                             ((hass-dash-group          ; Create a widget group.
                               :title "Home Assistant"  ; Give the group a title at the top.
                               :format "%t\n\n%v"       ; %t is where the title goes and %v is the widget it owns.
                               (hass-dash-group         ; Create a subgroup of widgets.
                                :title "Kitchen"
                                :title-face outline-2   ; Give it a unique face to make it stand out.
                                (hass-dash-toggle :entity-id "light.jasco_products_43082_light_2")
            ))
                              (hass-dash-group :title "Salle de bain" :format "\n\n%t\n\n%v"
                                               (hass-dash-state :entity-id "sensor.lumi_lumi_weather_humidity" :format "%[%t: %v%]\n" :label "Humidité")
                                               (hass-dash-state :entity-id "sensor.lumi_lumi_weather_temperature" :format "%[%t: %v%]\n" :label "Température")
                                               (hass-dash-toggle :entity-id "light.fan_salle_de_bain_light" :label "Fan")
            )

                              (hass-dash-group :title "Salon" :format "\n\n%t\n\n%v"
                                               (hass-dash-state :entity-id "sensor.multisensor_6_humidity" :format "%[%t: %v%]\n" :label "Humidité")
                                               (hass-dash-state :entity-id "sensor.multisensor_6_air_temperature" :format "%[%t: %v%]\n" :label "Température")
                                               (hass-dash-state :entity-id "sensor.salon_temperature" :format "%[%t: %v%]\n" :label "Température2")
                                               (hass-dash-toggle :entity-id "group.lum_salon" :label "Lumières")

                                               (hass-dash-state :entity-id "sensor.thermal_comfort_perception")
                                               (hass-dash-state :entity-id "media_player.salon_haut_parleur")
                                               (hass-dash-state :entity-id "media_player.salon_android_tv")
                                               (hass-dash-state :entity-id "humidifier.salon")

                                               (hass-dash-state :entity-id "sensor.creton_soil_moisture")
                                               (hass-dash-state :entity-id "sensor.langue_de_belle_mere_soil_moisture")
                                               (hass-dash-state :entity-id "sensor.zz_soil_moisture")


            )


            ))

            ;        (simple . ; Declaring a top-level group is optional and implied.
            ;                ((hass-dash-toggle :entity-id "light.kitchen_lights")
            ;                 (hass-dash-toggle :entity-id "switch.entry_lights")))
            ))
          '';
        };

        plz = {
          enable = true;
          config = ''
            (setq plz-curl-program "${pkgs.curl}/bin/curl")
          '';
        };

        ement = {
          enable = true;
          package = _epkgs: pkgs.emacsPackages.ement;
          config = ''
            (require 'ement-room-list)
            (require 'ement-tabulated-room-list)
            (add-hook 'ement-room-mode-hook (lambda () (setq show-trailing-whitespace nil)))
          '';
        };

        graphql-mode.enable = true;
        graphviz-dot-mode.enable = true;

        hydra = {
          enable = true;
          # after = [ "org-tempo" ];
          after = [ "org" "org-tempo" ];
          config = ''
            (progn
                                 (defhydra hydra-org-template (:color blue :hint nil)
                                   "
             _c_enter  _q_uote     _e_macs-lisp    _L_aTeX:
             _l_atex   _E_xample   _p_erl          _i_ndex:
             _a_scii   _v_erse     _P_erl tangled  _I_NCLUDE:
             _s_rc     _n_ote      plant_u_ml      _H_TML:
             _h_tml    ^ ^         ^ ^             _A_SCII:
            "
                                   ("s" (hot-expand "<s"))
                                   ("E" (hot-expand "<e"))
                                   ("q" (hot-expand "<q"))
                                   ("v" (hot-expand "<v"))
                                   ("n" (hot-expand "<not"))
                                   ("c" (hot-expand "<c"))
                                   ("l" (hot-expand "<l"))
                                   ("h" (hot-expand "<h"))
                                   ("a" (hot-expand "<a"))
                                   ("L" (hot-expand "<L"))
                                   ("i" (hot-expand "<i"))
                                   ("e" (hot-expand "<s" "emacs-lisp"))
                                   ("p" (hot-expand "<s" "perl"))
                                   ("u" (hot-expand "<s" "plantuml :file CHANGE.png"))
                                   ("P" (hot-expand "<s" "perl" ":results output :exports both :shebang \"#!/usr/bin/env perl\"\n"))
                                   ("I" (hot-expand "<I"))
                                   ("H" (hot-expand "<H"))
                                   ("A" (hot-expand "<A"))
                                   ("<" self-insert-command "ins")
                                   ("o" nil "quit"))

                                 ;; Reset the org-template expnsion system, this is need after upgrading to org 9 for some reason
                                 (setq org-structure-template-alist (eval (car (get 'org-structure-template-alist 'standard-value))))
                                 (defun hot-expand (str &optional mod header)
                                   "Expand org template.

            STR is a structure template string recognised by org like <s. MOD is a
            string with additional parameters to add the begin line of the
            structure element. HEADER string includes more parameters that are
            prepended to the element after the #+HEADER: tag."
                                   (let (text)
                                     (when (region-active-p)
                                       (setq text (buffer-substring (region-beginning) (region-end)))
                                       (delete-region (region-beginning) (region-end))
                                       (deactivate-mark))
                                     (when header (insert "#+HEADER: " header) (forward-line))
                                     (insert str)
                                     (org-tempo-complete-tag)
                                     (when mod (insert mod) (forward-line))
                                     (when text (insert text))))

                                 (define-key org-mode-map "<"
                                   (lambda () (interactive)
                                     (if (or (region-active-p) (looking-back "^"))
                                         (hydra-org-template/body)
                                       (self-insert-command 1))))
                                 )
          '';
        };

        js = {
          enable = true;
          mode = [
            ''("\\.js\\'" . js-mode)''
            ''("\\.json\\'" . js-mode)''
          ];
          config = ''
            (setq js-indent-level 2)
          '';
        };

        notifications = {
          enable = true;
          command = [ "notifications-notify" ];
        };

        # Remember where we where in a previously visited file. Built-in.
        saveplace = {
          enable = true;
          defer = 1;
          config = ''
            (setq-default save-place t)
            (setq save-place-file (locate-user-emacs-file "places"))
          '';
        };

        # More helpful buffer names. Built-in.
        uniquify = {
          enable = true;
          defer = 5;
          config = ''
            (setq uniquify-buffer-name-style 'post-forward)
          '';
        };

        # Hook up hippie expand.
        hippie-exp = {
          enable = true;
          bind = {
            "M-?" = "hippie-expand";
          };
        };

        which-key = {
          enable = true;
          command = [ "which-key-mode" "which-key-add-major-mode-key-based-replacements" ];
          defer = 3;
          config = "(which-key-mode)";
        };

        # Enable winner mode. This global minor mode allows you to
        # undo/redo changes to the window configuration. Uses the
        # commands C-c <left> and C-c <right>.
        winner = {
          enable = true;
          defer = 2;
          config = "(winner-mode 1)";
        };

        writeroom-mode = {
          enable = true;
          command = [ "writeroom-mode" ];
          bind = {
            "M-[" = "writeroom-decrease-width";
            "M-]" = "writeroom-increase-width";
          };
          hook = [ "(writeroom-mode . visual-line-mode)" ];
          config = ''
            (setq writeroom-bottom-divider-width 0)
          '';
        };

        buffer-move = {
          enable = true;
          bind = {
            "C-S-<up>" = "buf-move-up";
            "C-S-<down>" = "buf-move-down";
            "C-S-<left>" = "buf-move-left";
            "C-S-<right>" = "buf-move-right";
          };
        };

        all-the-icons.enable = true;

        all-the-icons-dired = {
          enable = true;
          after = [ "dired" "all-the-icons" ];
          hook = [ "(dired-mode . all-the-icons-dired-mode)" ];
        };

        consult = {
          enable = true;
          hook = [
            "(completion-list-mode . consult-preview-at-point-mode)"
          ];
          bind = {
            "C-c M-x" = "consult-mode-command";
            "C-c h" = "consult-history";
            "C-c k" = "consult-kmacro";
            "C-c m" = "consult-man";
            "C-c i" = "consult-info";
            # ([remap Info-search] = "consult-info";
            # C-x bindings (ctl-x-map)
            "C-x M-:" = "consult-complex-command"; # orig. repeat-complex-command
            "C-x b" = "consult-buffer"; # orig. switch-to-buffer
            "C-x 4 b" = "consult-buffer-other-window"; # orig. switch-to-buffer-other-window
            "C-x 5 b" = "consult-buffer-other-frame"; # orig. switch-to-buffer-other-frame
            "C-x r b" = "consult-bookmark"; # orig. bookmark-jump
            "C-x p b" = "consult-project-buffer"; # orig. project-switch-to-buffer
            # Custom M-# bindings for fast register access
            "M-#" = "consult-register-load";
            "M-'" = "consult-register-store"; # orig. abbrev-prefix-mark (unrelated)
            "C-M-#" = "consult-register";
            # Other custom bindings
            "M-y" = "consult-yank-pop"; # orig. yank-pop
            # M-g bindings (goto-map)
            "M-g e" = "consult-compile-error";
            "M-g f" = "consult-flymake"; # Alternative: consult-flycheck
            "M-g g" = "consult-goto-line"; # orig. goto-line
            "M-g M-g" = "consult-goto-line"; # orig. goto-line
            "M-g o" = "consult-outline"; # Alternative: consult-org-heading
            "M-g m" = "consult-mark";
            "M-g k" = "consult-global-mark";
            "M-g i" = "consult-imenu";
            "M-g I" = "consult-imenu-multi";
            # M-s bindings (search-map)
            "M-s d" = "consult-find";
            "M-s D" = "consult-locate";
            "M-s g" = "consult-grep";
            "M-s G" = "consult-git-grep";
            "M-s r" = "consult-ripgrep";
            "M-s l" = "consult-line";
            "M-s L" = "consult-line-multi";
            "M-s k" = "consult-keep-lines";
            "M-s u" = "consult-focus-lines";
            # Isearch integration
            "M-s e" = "consult-isearch-history";
          };

          bindLocal = {
            isearch-mode-map = {
              "M-e" = "consult-isearch-history"; # orig. isearch-edit-string
              "M-s e" = "consult-isearch-history"; # orig. isearch-edit-string
              "M-s l" = "consult-line"; # needed by consult-line to detect isearch
              "M-s L" = "consult-line-multi"; # needed by consult-line to detect isearch
            };
            # Minibuffer history
            minibuffer-local-map = {
              "M-s" = "consult-history"; # orig. next-matching-history-element
              "M-r" = "consult-history"; # orig. previous-matching-history-element
            };
          };

          init = ''
            (require 'consult-xref)

            ;; Optionally configure the register formatting. This improves the register
            ;; preview for `consult-register', `consult-register-load',
            ;; `consult-register-store' and the Emacs built-ins.
            (setq register-preview-delay 0.5
                  register-preview-function #'consult-register-format)

            ;; Optionally tweak the register preview window.
            ;; This adds thin lines, sorting and hides the mode line of the window.
            (advice-add #'register-preview :override #'consult-register-window)

            ;; Use Consult to select xref locations with preview
            (setq xref-show-xrefs-function #'consult-xref
                  xref-show-definitions-function #'consult-xref)

            ;; Configure other variables and modes in the :config section,
            ;; after lazily loading the package.
            :config

            ;; Optionally configure preview. The default value
            ;; is 'any, such that any key triggers the preview.
            ;; (setq consult-preview-key 'any)
            ;; (setq consult-preview-key "M-.")
            ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
            ;; For some commands and buffer sources it is useful to configure the
            ;; :preview-key on a per-command basis using the `consult-customize' macro.
            (consult-customize
             consult-theme :preview-key '(:debounce 0.2 any)
             consult-ripgrep consult-git-grep consult-grep
             consult-bookmark consult-recent-file consult-xref
             consult--source-bookmark consult--source-file-register
             consult--source-recent-file consult--source-project-recent-file
             ;; :preview-key "M-."
             :preview-key '(:debounce 0.4 any))

            ;; Optionally configure the narrowing key.
            ;; Both < and C-+ work reasonably well.
            (setq consult-narrow-key "<") ;; "C-+"

            ;; Optionally make narrowing help available in the minibuffer.
            ;; You may want to use `embark-prefix-help-command' or which-key instead.
            ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

            ;; By default `consult-project-function' uses `project-root' from project.el.
            ;; Optionally configure a different project root function.
            ;;;; 1. project.el (the default)
            ;; (setq consult-project-function #'consult--default-project--function)
            ;;;; 2. vc.el (vc-root-dir)
            ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
            ;;;; 3. locate-dominating-file
            ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
            ;;;; 4. projectile.el (projectile-project-root)
            ;; (autoload 'projectile-project-root "projectile")
            ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
            ;;;; 5. No project support
            ;; (setq consult-project-function nil)
          '';
        };

        consult-imenu = {
          enable = true;
        };

        consult-dir = {
          enable = true;
          bind = {
            "C-x C-d" = "consult-dir";
          };
          config = ''
            (define-key minibuffer-local-completion-map (kbd "C-x C-d") #'consult-dir)
            (define-key minibuffer-local-completion-map (kbd "C-x C-j") #'consult-dir-jump-file)
          '';
        };

        "0x0" = {
          enable = true;
          after = [ "embark" ];
          config = ''
            (define-key embark-region-map (kbd "U") '0x0-dwim)
          '';
        };

        affe = {
          enable = true;
          after = [ "orderless" ];
          config = ''
            ;; Configure Orderless
            (setq affe-regexp-function #'orderless-pattern-compiler
                  affe-highlight-function #'orderless-highlight-matches)

            ;; Manual preview key for `affe-grep'
            (consult-customize affe-grep :preview-key (kbd "M-."))
          '';
        };

        corfu = {
          enable = true;
          config = ''
            (global-corfu-mode)
          '';
        };

        consult-flycheck = {
          enable = true;
          bindLocal = {
            flycheck-command-map = {
              "!" = "consult-flycheck";
            };
          };
        };

        marginalia = {
          enable = true;
          command = [ "marginalia-mode" ];
          after = [ "vertico" ];
          defer = 1;
          config = "(marginalia-mode)";
        };

        embark = {
          enable = true;
          bind = {
            "C-." = "embark-act";
            "M-." = "embark-dwim";
            "C-h B" = "embark-bindings";
          };
          init = ''
            ;; Optionally replace the key help with a completing-read interface
            (setq prefix-help-command #'embark-prefix-help-command)
          '';
          config = ''
            ;; Hide the mode line of the Embark live/completions buffers
            (add-to-list 'display-buffer-alist
                         '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                           nil
                           (window-parameters (mode-line-format . none))))

            (defun embark-magit-status (file)
              "Run `magit-status` on repo containing the embark target."
              (interactive "GFile: ")
              (magit-status (locate-dominating-file file ".git")))

            (defun embark-target-this-buffer-file ()
              (cons 'this-buffer-file (or (buffer-file-name) (buffer-name))))

            (add-to-list 'embark-target-finders #'embark-target-this-buffer-file 'append)

            (add-to-list 'embark-keymap-alist '(this-buffer-file . this-buffer-file-map))

            ;; ------------------------------------------------------------


            ; Colorize the current Vertico candidate differently when acting
            (defun embark-vertico-indicator ()
              (let ((fr face-remapping-alist))
                (lambda (&optional keymap _targets prefix)
                  (when (bound-and-true-p vertico--input)
                    (setq-local face-remapping-alist
                                (if keymap
                                    (cons '(vertico-current . embark-target) fr)
                                  fr))))))

            (add-to-list 'embark-indicators #'embark-vertico-indicator)

            ; Automatically resizing auto-updating Embark Collect buffers to fit their contents
            (add-hook 'embark-collect-post-revert-hook
                      (defun resize-embark-collect-window (&rest _)
                        (when (memq embark-collect--kind '(:live :completions))
                          (fit-window-to-buffer (get-buffer-window)
                                                (floor (frame-height) 2) 1))))

            ; Switch between candidates and actions like in Helm
            (defun with-minibuffer-keymap (keymap)
              (lambda (fn &rest args)
                (minibuffer-with-setup-hook
                    (lambda ()
                      (use-local-map
                       (make-composed-keymap keymap (current-local-map))))
                  (apply fn args))))

            (defvar embark-completing-read-prompter-map
              (let ((map (make-sparse-keymap)))
                (define-key map (kbd "<tab>") 'abort-recursive-edit)
                map))

            (advice-add 'embark-completing-read-prompter :around
                        (with-minibuffer-keymap embark-completing-read-prompter-map))
            (define-key vertico-map (kbd "<tab>") 'embark-act-with-completing-read)

              (defun embark-act-with-completing-read (&optional arg)
                (interactive "P")
                (let* ((embark-prompter 'embark-completing-read-prompter)
                       (act (propertize "Act" 'face 'highlight))
                       (embark-indicator (lambda (_keymap targets) nil)))
                  (embark-act arg)))

            ; Show the current Embark target types in the modeline
            (defvar embark--target-mode-timer nil)
            (defvar embark--target-mode-string "")

            (defun embark--target-mode-update ()
              (setq embark--target-mode-string
                    (if-let (targets (embark--targets))
                        (format "[%s%s] "
                                (propertize (symbol-name (plist-get (car targets) :type)) 'face 'bold)
                                (mapconcat (lambda (x) (format ", %s" (plist-get x :type)))
                                           (cdr targets)
                                           ""))
                      "")))

            (define-minor-mode embark-target-mode
              "Shows the current targets in the modeline."
              :global t
              (setq mode-line-misc-info (assq-delete-all 'embark-target-mode mode-line-misc-info))
              (when embark--target-mode-timer
                (cancel-timer embark--target-mode-timer)
                (setq embark--target-mode-timer nil))
              (when embark-target-mode
                (push '(embark-target-mode (:eval embark--target-mode-string)) mode-line-misc-info)
                (setq embark--target-mode-timer
                      (run-with-idle-timer 0.1 t #'embark--target-mode-update))))
          '';

          bindLocal = {
            minibuffer-local-completion-map = {
              "M-o" = "embark-act";
            };
            embark-file-map = {
              "s" = "sudo-edit";
              "l" = "vlf";
            };
          };
        };

        sudo-edit.enable = true;
        vlf.enable = true;

        embark-consult = {
          enable = true;
          after = [ "embark" "consult" ];
          hook = [
            "(embark-collect-mode . consult-preview-at-point-mode)"
            # "(prog-mode . lsp)"
          ];
        };

        string-inflection = {
          enable = true;
          bind = {
            "C-c C-u" = "string-inflection-all-cycle";
          };
        };

        # Configure magit, a nice mode for the git SCM.
        magit = {
          enable = true;
          bind = {
            "C-x g" = "magit-status";
          };
          config = ''
            (add-to-list 'git-commit-style-convention-checks
                         'overlong-summary-line)
            (setq magit-repolist-columns
                  '(("Name"    25 magit-repolist-column-ident ())
                    ("Version" 25 magit-repolist-column-version ())
                    ("D"        1 magit-repolist-column-dirty ())
                    ("⇣"      3 magit-repolist-column-unpulled-from-upstream
                     ((:right-align t)
                      (:help-echo "Upstream changes not in branch")))
                    ("⇡"        3 magit-repolist-column-unpushed-to-upstream
                     ((:right-align t)
                      (:help-echo "Local changes not in upstream")))
                    ("Path"    99 magit-repolist-column-path ())))
          '';
        };

        magit-todos = {
          enable = true;
          defer = 1;
        };

        forge = {
          enable = true;
          after = [ "magit" ];
        };

        git-messenger = {
          enable = true;
          bind = {
            "C-x v p" = "git-messenger:popup-message";
          };
        };

        multiple-cursors = {
          enable = true;
          bind = {
            "C-S-c C-S-c" = "mc/edit-lines";
            "C-c m" = "mc/mark-all-like-this";
            "C->" = "mc/mark-next-like-this";
            "C-<" = "mc/mark-previous-like-this";
          };
        };

        nix-sandbox = {
          enable = true;
          command = [ "nix-current-sandbox" "nix-shell-command" ];
        };

        avy = {
          enable = true;
          # avy-org-goto-heading-timer
          # avy-goto-char-timer
          # avy-org-refile-as-child
          # avy-goto-word-or-subword-1
          bind = {
            "C-:" = "avy-goto-char";
            "C-'" = "avy-goto-char-2";
            "M-g f" = "avy-goto-line";
            "M-g w" = "avy-goto-word-1";
            "M-g e" = "avy-goto-word-0";
            "C-c C-j" = "avy-resume";
          };
          command = [ "avy-process" ];
          config = ''
            (setq avy-all-windows t)
          '';
        };

        undo-tree = {
          enable = true;
          defer = 1;
          command = [ "global-undo-tree-mode" ];
          config = ''
            (setq undo-tree-visualizer-relative-timestamps t
                  undo-tree-visualizer-timestamps t
                  undo-tree-enable-undo-in-region t
                  undo-tree-visualizer-diff t)
            (setq undo-tree-history-directory-alist '(("." . "~/.config/emacs/backups/undo-tree")))
            (global-undo-tree-mode)
          '';
        };

        hammy = {
          enable = true;
          config = ''
            (hammy-mode 1)
          '';
        };

        literate-calc-mode = {
          enable = false;
        };

        expand-region = {
          enable = true;
          config = ''
            (global-set-key (kbd "C-=") 'er/expand-region)
          '';
        };

        frog-jump-buffer = {
          enable = true;
        };

        markdown-mode = {
          enable = true;
          config = ''
            (setq markdown-command "${pkgs.pandoc}/bin/pandoc")
          '';
        };

        pandoc-mode = {
          enable = true;
          after = [ "markdown-mode" ];
          hook = [ "markdown-mode" ];
          bindLocal = {
            markdown-mode-map = {
              "C-c C-c" = "pandoc-run-pandoc";
            };
          };
        };

        nix-mode = {
          enable = true;
          hook = [ "(nix-mode . subword-mode)" ];
        };

        #notmuch = {
        #  enable = true;
        #  command = [ "notmuch" "notmuch-show-tag" "notmuch-search-tag" "notmuch-tree-tag" ];
        #  config = ''
        #    (setq notmuch-search-oldest-first nil)
        #  '';
        #};

        # Use ripgrep for fast text search in projects. I usually use
        # this through Projectile.
        ripgrep = {
          enable = true;
          command = [ "ripgrep-regexp" ];
        };

        wgrep.enable = true;

        org-modern = {
          enable = true;
          config = ''
            (global-org-modern-mode)
          '';
        };
        org = {
          enable = true;
          bind = {
            "C-c c" = "org-capture";
            "C-c a" = "org-agenda";
            "C-c l" = "org-store-link";
            "C-c b" = "org-switchb";
          };
          hook = [
            ''
              (org-mode
               . (lambda ()
                   (add-hook 'completion-at-point-functions
                             'pcomplete-completions-at-point nil t)))
            ''
          ];
          config = ''
            ;; Some general stuff.
            (setq org-reverse-note-order t
                  org-use-fast-todo-selection t
                  org-adapt-indentation nil
                  org-hide-emphasis-markers t)

            ;;(setq org-tag-alist rah-org-tag-alist)

            ;; Add some todo keywords.
            (setq org-todo-keywords
                  '((sequence "TODO(t)"
                              "NEXT"
                              "STARTED(s!)"
                              "WAITING(w@/!)"
                              "DELEGATED(@!)"
                              "|"
                              "DONE(d!)"
                              "CANCELED(c@!)")))

            ;; Setup org capture.
            ;; (setq org-default-notes-file (rah-org-file "capture"))
            (setq org-default-notes-file (concat org-directory "/inbox.org"))

            ;; Active Org-babel languages
            (org-babel-do-load-languages 'org-babel-load-languages
                                         '((plantuml . t)
                                           (http . t)
                                           (dot . t)
                                           (restclient . t)
                                           (R . t)
                                           (sql . t)
                                           (shell . t)))

            ;; Unfortunately org-mode tends to take over keybindings that
            ;; start with C-c.
            (unbind-key "C-c SPC" org-mode-map)
            (unbind-key "C-c w" org-mode-map)

            (setq org-image-actual-width 400)
            (setq org-extend-today-until 4)
            (setq org-export-backends (quote (ascii html icalendar latex md odt)))

            ;; https://old.reddit.com/r/orgmode/comments/hg8qik/weird_joined_lines_bug/fw73kml/
            (add-hook 'org-capture-prepare-finalize-hook 'add-newline-at-end-if-none)
          '';
        };

        ol-notmuch = {
          enable = pcfg.org.enable && pcfg.notmuch.enable;
          after = [ "notmuch" "org" ];
        };

        rego-mode.enable = true;

        org-ql.enable = true;
        org-sidebar.enable = true;

        nginx-mode.enable = true;

        # org-super-agenda = {
        #   enable = true;
        #   after = [ "org" ];
        #   config = ''
        #     (org-super-agenda-mode t)
        #     (setq org-super-agenda-groups '((:auto-parent t)))
        #   '';
        # };

        org-habit = {
          enable = true;
          after = [ "org" ];
          # defer = true;
          config = ''
            ;; for using with Orgzly
            (setq org-log-into-drawer "LOGBOOK")
          '';
        };

        org-agenda = {
          enable = true;
          after = [ "org" ];
          defer = true;
          config = ''
            ;; Set up agenda view.
            ;; org-agenda-files (rah-all-org-files)
            (setq org-agenda-files
                  (list
                   (concat org-directory "/inbox.org")
                   (concat org-directory "/luxor.org")
                   (concat org-directory "/gtd.org")))
            (setq org-agenda-span 5
                  org-deadline-warning-days 14
                  org-agenda-show-all-dates t
                  org-agenda-skip-deadline-if-done t
                  org-agenda-skip-scheduled-if-done t
                  org-agenda-start-on-weekday nil)

            (setq org-agenda-custom-commands
                  '(("p" tags "PROJECT-MAYBE-DONE" nil)
                    ("m" tags "PROJECT&MAYBE" nil)
                    ("a" "My agenda"
                     ((org-agenda-list)
                      (org-agenda-list-stuck-projects)          ;; (1)
                      (tags "PROJECT-MAYBE-DONE")))
                    ;; ... put your other custom commands here
                   ))

            (setq org-stuck-projects
                  '("+PROJECT/-MAYBE-DONE" ("TODO" "STARTED") nil "\\<IGNORE\\>"))
          '';
        };

        ob-http = {
          enable = true;
          after = [ "org" ];
          defer = true;
        };

        ob-plantuml = {
          enable = true;
          after = [ "org" ];
          defer = true;
        };

        org-table = {
          enable = true;
          after = [ "org" ];
          command = [ "orgtbl-to-generic" ];
          hook = [
            # For orgtbl mode, add a radio table translator function for
            # taking a table to a psql internal variable.
            ''
              (orgtbl-mode
               . (lambda ()
                   (defun rah-orgtbl-to-psqlvar (table params)
                     "Converts an org table to an SQL list inside a psql internal variable"
                     (let* ((params2
                             (list
                              :tstart (concat "\\set " (plist-get params :var-name) " '(")
                              :tend ")'"
                              :lstart "("
                              :lend "),"
                              :sep ","
                              :hline ""))
                            (res (orgtbl-to-generic table (org-combine-plists params2 params))))
                       (replace-regexp-in-string ",)'$"
                                                 ")'"
                                                 (replace-regexp-in-string "\n" "" res))))))
            ''
          ];
          config = ''
            (unbind-key "C-c SPC" orgtbl-mode-map)
            (unbind-key "C-c w" orgtbl-mode-map)
          '';
          extraConfig = ''
            :functions org-combine-plists
          '';
        };

        org-capture = {
          enable = true;
          after = [ "org" ];
          config = ''
            (setq org-capture-templates `(("t" "Todo [inbox]" entry
                                           (file+headline ,(concat org-directory "/inbox.org") "Tasks")
                                           "* TODO %i%?")
                                          ("T" "Tickler" entry
                                           (file+headline ,(concat org-directory "/tickler.org") "Tickler")
                                           "* %i%? \n %U")))
          '';
        };

        org-clock = {
          enable = true;
          after = [ "org" ];
          config = ''
            (setq org-clock-rounding-minutes 5
                  org-clock-out-remove-zero-time-clocks t)
          '';
        };

        org-duration = {
          enable = true;
          after = [ "org" ];
          config = ''
            ;; I always want clock tables and such to be in hours, not days.
            (setq org-duration-format (quote h:mm))
          '';
        };

        org-refile = {
          enable = true;
          after = [ "org" ];
          config = ''
            ;; Refiling should include not only the current org buffer but
            ;; also the standard org files. Further, set up the refiling to
            ;; be convenient with IDO. Follows norang's setup quite closely.
            (setq org-refile-targets '((nil :maxlevel . 2)
                                       (org-agenda-files :maxlevel . 2))
                  org-refile-use-outline-path t
                  org-outline-path-complete-in-steps nil
                  org-refile-allow-creating-parent-nodes 'confirm)
          '';
        };

        org-superstar = {
          enable = true;
          hook = [ "(org-mode . org-superstar-mode)" ];
        };

        org-edna = {
          enable = true;
          defer = 1;
          config = "(org-edna-mode)";
        };

        hide-mode-line = {
          enable = true;
        };

        org-tree-slide = {
          enable = true;
          command = [ "org-tree-slide-mode" ];
          hook = [
            "(org-tree-slide-play . efs/presentation-setup)"
            "(org-tree-slide-stop . efs/presentation-end)"
          ];
        };

        # Set up yasnippet. Defer it for a while since I don't generally
        # need it immediately.
        yasnippet = {
          enable = true;
          defer = 3;
          command = [ "yas-global-mode" "yas-minor-mode" "yas-expand-snippet" ];
          hook = [
            # Yasnippet interferes with tab completion in ansi-term.
            "(term-mode . (lambda () (yas-minor-mode -1)))"
            "(yas-minor-mode-hook . (lambda () (yas-activate-extra-mode 'fundamental-mode)))"
          ];
          config = "(yas-global-mode 1)";
        };

        yasnippet-snippets = {
          enable = true;
          after = [ "yasnippet" ];
        };

        smartparens = {
          enable = true;
          defer = 3;
          command = [ "smartparens-global-mode" "show-smartparens-global-mode" ];
          bindLocal = {
            smartparens-mode-map = {
              "C-M-f" = "sp-forward-sexp";
              "C-M-b" = "sp-backward-sexp";
            };
          };
          config = ''
            (require 'smartparens-config)
            (smartparens-global-mode t)
            (show-smartparens-global-mode t)

            (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
            (sp-local-pair 'prog-mode "[" nil :post-handlers '((indent-between-pair "RET")))
            (sp-local-pair 'prog-mode "(" nil :post-handlers '((indent-between-pair "RET")))
          '';
        };

        fill-column-indicator = {
          enable = true;
          command = [ "fci-mode" ];
        };

        flycheck = {
          enable = true;
          command = [ "global-flycheck-mode" ];
          defer = 1;
          bind = {
            "M-n" = "flycheck-next-error";
            "M-p" = "flycheck-previous-error";
          };
          config = ''
            ;; Only check buffer when mode is enabled or buffer is saved.
            (setq flycheck-check-syntax-automatically '(mode-enabled save)
                flycheck-markdown-mdl-executable "${pkgs.mdl}/bin/mdl")

            ;; Enable flycheck in all eligible buffers.
            (global-flycheck-mode)

            (flycheck-add-mode 'javascript-eslint 'web-mode)
          '';
        };

        flycheck-plantuml = {
          enable = true;
          hook = [ "(flycheck-mode . flycheck-plantuml-setup)" ];
        };

        vertico = {
          enable = true;
          command = [ "vertico-mode" ];
          init = "(vertico-mode)";
        };

        orderless = {
          enable = true;
          init = ''
            (setq completion-styles '(orderless)
                  read-file-name-completion-ignore-case t)
          '';
        };

        savehist = {
          enable = true;
          init = "(savehist-mode)";
          config = ''
            (setq history-delete-duplicates t
                  history-length 100)
          '';
        };

        kubel = {
          enable = true;
        };

        kubernetes = {
          enable = true;
          command = [ "kubernetes-overview" ];
        };

        emacs = {
          enable = true;
          init = ''
            ;; Add prompt indicator to `completing-read-multiple'.
            (defun crm-indicator (args)
              (cons (concat "[CRM] " (car args)) (cdr args)))
            (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

            ;; Grow and shrink minibuffer
            ;;(setq resize-mini-windows t)

            ;; Do not allow the cursor in the minibuffer prompt
            (setq minibuffer-prompt-properties
                  '(read-only t cursor-intangible t face minibuffer-prompt))
            (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

            ;; Enable recursive minibuffers
            (setq enable-recursive-minibuffers t)
          '';
        };

        prescient = {
          enable = true;
          config = ''
            ;; to save your command history on disk, so the sorting gets more
            ;; intelligent over time
            (prescient-persist-mode +1)
          '';
        };

        company-prescient = {
          enable = true;
          after = [ "company" ];
          config = ''
            (company-prescient-mode +1)
          '';
        };

        ctrlf = {
          enable = true;
          config = ''
            (ctrlf-mode +1)
          '';
        };

        popper = {
          enable = true;
          bind = {
            "C-`" = "popper-toggle-latest";
            "M-`" = "popper-cycle";
            "C-M-`" = "popper-toggle-type";
          };
          command = [ "popper-mode" "popper-group-by-projectile" ];
          config = ''
            (setq popper-reference-buffers
                    '("Output\\*$"
                      "\\*Async Shell Command\\*"
                      "\\*Buffer List\\*"
                      "\\*Flycheck errors\\*"
                      "\\*Messages\\*"
                      compilation-mode
                      help-mode)
                  popper-group-function #'popper-group-by-projectile)
            (popper-mode)
          '';
        };

        projectile = {
          enable = true;
          command = [ "projectile-mode" "projectile-project-root" ];
          bindKeyMap = {
            "C-c p" = "projectile-command-map";
          };
          config = ''
            (setq projectile-completion-system 'default)
            (setq projectile-enable-caching t)
            (push "vendor" projectile-globally-ignored-directories)
            (push ".yarn" projectile-globally-ignored-directories)
            (push ".direnv" projectile-globally-ignored-directories)
            (push "node_modules" projectile-globally-ignored-directories)
            (push ".cargo" projectile-globally-ignored-directories)
            (push ".idea" projectile-globally-ignored-directories)
            (push "~/" projectile-ignored-projects)

            ;;(setq projectile-ignored-projects
            ;;'("~/" "test"))

            (projectile-mode 1)
          '';

          init = ''
            (when (file-directory-p "~/dev")
            (setq projectile-project-search-path '("~/dev")))
            ;;(setq projectile-switch-project-action #'projectile-dired)
          '';
        };

        plantuml-mode.enable = true;

        ace-window = {
          enable = true;
          config = ''
            (setq aw-dispatch-always t)
          '';
          extraConfig = ''
            :bind* (("C-c w" . ace-window)
                    ("M-o" . ace-window))
          '';
        };

        company = {
          enable = true;
          command = [ "company-mode" "company-doc-buffer" "global-company-mode" ];
          defer = 1;
          extraConfig = ''
            :bind (:map company-mode-map
                        ([remap completion-at-point] . company-complete-common)
                        ([remap complete-symbol] . company-complete-common))
          '';
          config = ''
            (setq company-idle-delay 0.2
                  company-minimum-prefix-length 3
                  company-show-quick-access t
                  company-tooltip-maximum-width 100
                  company-tooltip-minimum-width 20
                  ; Allow me to keep typing even if company disapproves.
                  company-require-match nil)

            (global-company-mode)
          '';
        };

        company-posframe = {
          enable = true;
          hook = [ "(company-mode . company-posframe-mode)" ];
        };

        company-yasnippet = {
          enable = true;
          after = [ "company" "yasnippet" ];
          bind = {
            "M-/" = "company-yasnippet";
          };
        };

        company-dabbrev = {
          enable = true;
          after = [ "company" ];
          bind = {
            "C-M-/" = "company-dabbrev";
          };
          config = ''
            (setq company-dabbrev-downcase nil
                  company-dabbrev-ignore-case t)
          '';
        };

        company-quickhelp = {
          enable = true;
          after = [ "company" ];
          command = [ "company-quickhelp-mode" ];
          config = ''
            (company-quickhelp-mode 1)
          '';
        };

        company-restclient = {
          enable = true;
          after = [ "company" "restclient" ];
          command = [ "company-restclient" ];
          config = ''
            (add-to-list 'company-backends 'company-restclient)
          '';
        };

        protobuf-mode = {
          enable = true;
          mode = [ ''"'\\.proto\\'"'' ];
        };

        restclient = {
          enable = true;
          mode = [ ''("\\.http\\'" . restclient-mode)'' ];
        };

        ob-restclient = {
          enable = true;
          mode = [ ''("\\.http\\'" . restclient-mode)'' ];
        };

        transpose-frame = {
          enable = true;
          bind = {
            "C-c f t" = "transpose-frame";
          };
        };

        smart-tabs-mode = {
          enable = false;
          config = ''
            (smart-tabs-insinuate 'c 'c++ 'cperl 'java)
          '';
        };

        yaml-mode.enable = true;

        wc-mode = {
          enable = true;
          command = [ "wc-mode" ];
        };

        web-mode = {
          enable = true;
          mode = [
            ''"\\.html\\'"''
            ''"\\.jsx?\\'"''
            ''"\\.tsx\\'"''
            ''"\\.ts\\'"''
          ];
          config = ''
            (setq web-mode-attr-indent-offset 4
                  web-mode-code-indent-offset 2
                  web-mode-markup-indent-offset 2)

            (add-to-list 'web-mode-content-types '("jsx" . "\\.jsx?\\'"))
          '';
        };

        dirvish = {
          enable = true;
          config = ''
            (require 'dirvish-quick-access)
            (require 'dirvish-history)
            (require 'dirvish-ls)
            (require 'dirvish-extras)
            (require 'dirvish-emerge)
            (require 'dirvish-subtree)
            (require 'dirvish-vc)
            (require 'dirvish-yank)
            (require 'dirvish-fd)
            (require 'dirvish-narrow)
            (dirvish-override-dired-mode)

            (setq dirvish-emerge-groups '(("Recent" (predicate . ‘recent-files-2h’))
              ("README" (regex . "README"))
              ("PDF"    (extensions "pdf"))
              ("Documents" (extensions "pdf" "tex" "bib" "epub"))
              ("Video" (extensions "mp4" "mkv" "webm"))
              ("Pictures" (extensions "jpg" "png" "svg" "gif"))
              ("Audio" (extensions "mp3" "flac" "wav" "ape" "aac"))
              ("Archives" (extensions "gz" "rar" "zip"))
              ("LaTeX"  (extensions "tex" "bib"))))
          '';
        };

        dired = {
          enable = true;
          command = [ "dired" "dired-jump" ];
          config = ''
            (put 'dired-find-alternate-file 'disabled nil)

            ;; Be smart about choosing file targets.
            (setq dired-dwim-target t)

            ;; Use the system trash can.
            (setq delete-by-moving-to-trash t)
            (setq dired-dwim-target t)
            (setq dired-listing-switches "-agho --group-directories-first")

            (defun ora-ediff-files ()
              (interactive)
              (let ((files (dired-get-marked-files))
                    (wnd (current-window-configuration)))
                (if (<= (length files) 2)
                    (let ((file1 (car files))
                          (file2 (if (cdr files)
                                     (cadr files)
                                   (read-file-name
                                    "file: "
                                    (dired-dwim-target-directory)))))
                      (if (file-newer-than-file-p file1 file2)
                          (ediff-files file2 file1)
                        (ediff-files file1 file2))
                      (add-hook 'ediff-after-quit-hook-internal
                                (lambda ()
                                  (setq ediff-after-quit-hook-internal nil)
                                  (set-window-configuration wnd))))
                  (error "no more than 2 files should be marked"))))

            (define-key dired-mode-map "e" 'ora-ediff-files)
          '';
        };

        wdired = {
          enable = true;
          bindLocal = {
            dired-mode-map = {
              "C-c C-w" = "wdired-change-to-wdired-mode";
            };
          };
          config = ''
            ;; I use wdired quite often and this setting allows editing file
            ;; permissions as well.
            (setq wdired-allow-to-change-permissions t)
          '';
        };

        dired-single = {
          enable = true;
          after = [ "dired" ];
        };

        # Hide hidden files when opening a dired buffer. But allow showing them by
        # pressing `.`.
        dired-x = {
          enable = true;
          # after = [ "dired" ];
          hook = [ "(dired-mode . dired-omit-mode)" ];
          bindLocal.dired-mode-map = {
            "." = "dired-omit-mode";
          };
          config = ''
            (setq dired-omit-verbose nil
                  dired-omit-files (concat dired-omit-files "\\|^\\..+$"))
          '';
        };

        recentf = {
          enable = true;
          command = [ "recentf-mode" ];
          config = ''
            (setq recentf-save-file (locate-user-emacs-file "recentf")
                  recentf-max-menu-items 20
                  recentf-max-saved-items 500
                  recentf-exclude '("COMMIT_MSG" "COMMIT_EDITMSG"))

            ;; Save the file list every 10 minutes.
            (run-at-time nil (* 10 60) 'recentf-save-list)

            (recentf-mode)
          '';
        };

        nxml-mode = {
          enable = true;
          mode = [ ''"\\.xml\\'"'' ];
          config = ''
            (setq nxml-child-indent 4
                  nxml-attribute-indent 4
                  nxml-slash-auto-complete-flag t)
            (add-to-list 'rng-schema-locating-files
                         "~/.emacs.d/nxml-schemas/schemas.xml")
          '';
        };

        rustic = {
          enable = true;
          config = ''
            (setq rustic-lsp-server 'rust-analyzer)
            (setq rustic-cargo-bin "cargo")
            (setq rustic-lsp-client 'eglot)
          '';
        };

        go-mode = {
          enable = true;
        };

        # sendmail = {
        #   enable = false;
        #   mode = [
        #     ''("mutt-" . mail-mode)''
        #     ''("\\.article" . mail-mode))''
        #   ];
        #   hook = [
        #     ''
        #       (lambda ()
        #             (auto-fill-mode)     ; Avoid having to M-q all the time.
        #             (rah-mail-flyspell)  ; I spel funily soemtijms.
        #             (rah-mail-reftex)    ; Make it easy to include references.
        #             (mail-text))         ; Jump to the actual text.
        #     ''
        #   ];
        # };

        # sqlformat = {
        #   enable = true;
        #   hook = [
        #     "(sql-mode-hook . sqlformat-on-save-mode)"
        #   ];
        #   config = ''
        #     (setq sqlformat-command "${pkgs.sqlfluff}/bin/sqlfluff")
        #     (setq sqlformat-args '("fix" "-f" "-"))
        #   '';
        # };

        systemd = {
          enable = true;
          defer = true;
        };

        terraform-mode.enable = true;

        eglot = {
          enable = true;
        };

        tree-sitter = {
          enable = true;
          config = ''
            (global-tree-sitter-mode)
            (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)
          '';
        };

        tree-sitter-langs.enable = true;

        treemacs = {
          enable = true;
          bind = {
            "C-c t f" = "treemacs-find-file";
            "C-c t t" = "treemacs";
          };
        };

        inheritenv.enable = true;

        treemacs-projectile = {
          enable = true;
          after = [ "treemacs" "projectile" ];
        };

        verb = {
          enable = true;
          defer = true;
          after = [ "org" ];
          config = ''
            (define-key org-mode-map (kbd "C-c C-r") verb-command-map)
            (setq verb-trim-body-end "[ \t\n\r]+")
          '';
        };

        visual-fill-column = {
          enable = true;
          command = [ "visual-fill-column-mode" ];
        };

        vterm = {
          enable = true;
          command = [ "vterm" ];
        };

        whole-line-or-region = {
          enable = true;
          config = ''
            (whole-line-or-region-global-mode t)
          '';
        };

      };

    };

  };
}
