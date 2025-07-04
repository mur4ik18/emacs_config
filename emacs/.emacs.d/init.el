;;; -*- lexical-binding: t; -*-
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;Compat is the Elisp forwards compatibility library, which provides
;definitions introduced in newer Emacs versions.  The definitions
;are only installed if necessary for your current Emacs version.  If
;Compat is compiled on a recent version of Emacs, all of the
;definitions are disabled at compile time, such that no negative
;performance impact is incurred.
(use-package compat :ensure t)

; Very important for mac-os
(setq ns-right-alternate-modifier nil)



(use-package emacs :ensure nil
  :bind (("M-o" . other-window)
         ("M-l" . downcase-dwim)
         ("M-u" . upcase-dwim)
         ("M-c" . capitalize-dwim)
         ("C-h '" . describe-char)
         ;; ("C-c C-j" . recompile)
         ;; ("C-c C-;" . compile)
         )
  :init
  ;; Configure backups. Put all of them in the separate directory.
  ;; Copied from the emacs wiki.
  (setq backup-by-copying t     ; don't clobber symlinks
        backup-directory-alist '(("." . "~/.saves/")) ; don't litter my fs tree
        delete-old-versions t
        kept-new-versions 6
        kept-old-versions 2
        version-control t)      ; use versioned backups
  ;; Disable audio bell on error
  (setq ring-bell-function 'ignore)

  ;; Emacs 28 and newer: Hide commands in M-x which do not work in the current
  ;; mode.  Vertico commands are hidden in normal buffers. This setting is
  ;; useful beyond Vertico.
  (setq read-extended-command-predicate #'command-completion-default-include-p)
  
  ;; Support opening new minibuffers from inside existing minibuffers.
  (setq enable-recursive-minibuffers t)

  ;; Spaces > tabs.
  ;; Use 4 spaces for tabs whenever possible.
  ;; Remember that there's `untabify' command which helps you convert tabs to spaces.
  (setq-default indent-tabs-mode nil)
  (setq-default tab-width 4)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (setq tab-always-indent 'complete)

  ;; Delete selection on typing
  (delete-selection-mode)

  ;; Enable clipboard synchronization on wayland.
  
  (when (= 0 (shell-command "wl-copy -v"))
    ;; credit: yorickvP on Github
    (setq wl-copy-process nil)
    (defun wl-copy (text)
      (setq wl-copy-process (make-process :name "wl-copy"
                                          :buffer nil
                                          :command '("wl-copy" "-f" "-n")
                                          :connection-type 'pipe
                                          :noquery t))
      (process-send-string wl-copy-process text)
      (process-send-eof wl-copy-process))
    (defun wl-paste ()
      (if (and wl-copy-process (process-live-p wl-copy-process))
          nil     ; should return nil if we're the current paste owner
        (shell-command-to-string "wl-paste -n | tr -d \r")))
    (setq interprogram-cut-function 'wl-copy)
    (setq interprogram-paste-function 'wl-paste))
  ;; Don't show the splash screen
  (setq inhibit-startup-message t)

  ;; Turn off some unneeded UI elements
  (menu-bar-mode -1)  ; Leave this one on if you're a beginner!
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (blink-cursor-mode -1)

  ;; Allow short answers
  (setopt use-short-answers t)

  ;; Ask confirmation on emacs exit
  (setq confirm-kill-emacs #'y-or-n-p))



(use-package term :ensure nil
  :config
  ;; Allow switching windows in ansi-term char mode
  (define-key term-raw-map (kbd "M-o") 'other-window))

(use-package multiple-cursors :ensure t :demand t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click))
  :config
  ;; Don't ask to allow running command on all cursors.
  ;; If you want to disable this behavior for some functions
  ;; just add those in `mc/cmds-to-run-once'.
  (setq mc/always-run-for-all t))

(use-package expand-region :ensure t :demand t
  :bind ("C-=" . er/expand-region))

;;; Completions and other general must-have stuff.

;; Better completion for M-x
(use-package vertico :ensure t :demand t
  :init
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

;; Fuzzy search for vertico
(use-package orderless :ensure t :demand t
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;; Useful annotations for vertico
(use-package marginalia :ensure t :demand t
  :init
  (marginalia-mode))

(defun corfu-enable-in-minibuffer ()
  "Enable Corfu in the minibuffer."
  (when (local-variable-p 'completion-at-point-functions)
    ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
    (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
                corfu-popupinfo-delay nil)
    (corfu-mode 1)))


;; General in-place auto completion
;; If you want more context-related completions consider `cape' package
(use-package corfu :ensure t :demand t
  :hook (minibuffer-setup-hook . corfu-enable-in-minibuffer)
  :init
  (global-corfu-mode))

;; Use Dabbrev with Corfu!
(use-package dabbrev
  ;; Swap M-/ and C-M-/
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  ;; Since 29.1, use `dabbrev-ignored-buffer-regexps' on older.
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))

;; Example configuration for Consult
(use-package consult :ensure t :demand t
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ("C-h t" . consult-theme)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer) ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab) ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)         ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer) ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store) ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop) ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake) ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)   ;; orig. goto-line
         ("M-g M-g" . consult-goto-line) ;; orig. goto-line
         ("M-g o" . consult-outline) ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-fd) ;; Alternative: consult-find
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history) ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history) ;; orig. isearch-edit-string
         ("M-s l" . consult-line) ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi) ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history) ;; orig. next-matching-history-element
         ("M-r" . consult-history)) ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

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
        xref-show-definitions-function #'consult-xref))

(use-package embark :ensure t :demand t
  :bind
  (;("C-;" . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-act)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'
  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))
(use-package embark-consult :ensure t :demand t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Show more useful information in eldoc
(use-package helpful :ensure t :demand t
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-h ." . helpful-at-point)))

(use-package treesit
  :config
  (setq treesit-language-source-alist
   '((bash "https://github.com/tree-sitter/tree-sitter-bash")
     (css "https://github.com/tree-sitter/tree-sitter-css")
     (elisp "https://github.com/Wilfred/tree-sitter-elisp")
     (html "https://github.com/tree-sitter/tree-sitter-html")
     (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
     (json "https://github.com/tree-sitter/tree-sitter-json")
     (make "https://github.com/alemuller/tree-sitter-make")
     (markdown "https://github.com/ikatyang/tree-sitter-markdown")
     (python "https://github.com/tree-sitter/tree-sitter-python")
     (toml "https://github.com/tree-sitter/tree-sitter-toml")
     (yaml "https://github.com/ikatyang/tree-sitter-yaml")
     (nix "https://github.com/nix-community/tree-sitter-nix")
     (typst "https://github.com/uben0/tree-sitter-typst")))
  (setq major-mode-remap-alist
        '((yaml-mode . yaml-ts-mode)
          (bash-mode . bash-ts-mode)
          ;; (js2-mode . js-ts-mode)
          (json-mode . json-ts-mode)
          (css-mode . css-ts-mode)
          (nix-mode . nix-ts-mode)
          (python-mode . python-ts-mode)))
  ;; ;; Run to install languages
  ;;(mapc #'treesit-install-language-grammar (mapcar #'car treesit-language-source-alist))
  )

;;; More opinionated packages
(use-package rainbow-delimiters :ensure t :demand t
  :hook prog-mode)

;; Snippets!
(use-package tempel
  :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
         ("M-*" . tempel-insert))
  :init
  ;; Setup completion at point
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))

  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf))
(use-package tempel-collection :ensure t)



;; Lovely themes


(use-package modus-themes :ensure t :demand t
  :config
  (fringe-mode 0)                       ;
  (load-theme 'modus-operandi t)
  )

;; Trim unnecessary whitespace.
(use-package ws-butler :ensure t
  :hook (prog-mode typst-ts-mode))

(use-package hl-todo :ensure t :demand t
  :init
  (global-hl-todo-mode))

;; Newer version of transient package required for magit.
(use-package transient :ensure t)

(use-package magit :ensure t :demand t)

(use-package avy :ensure t :demand t
  :bind ("M-j" . avy-goto-char-timer)
  :config
  (setq avy-all-windows t
        avy-all-windows-alt nil
        avy-background t
        avy-single-candidate-jump nil))

(use-package eat
  :ensure (:type git :host codeberg :repo "akib/emacs-eat"
           :files ("*.el" ("term" "term/*.el") "*.texi"
                   "*.ti" ("terminfo/e" "terminfo/e/*")
                   ("terminfo/65" "terminfo/65/*")
                   ("integration" "integration/*")
                   (:exclude ".dir-locals.el" "*-tests.el")))
  :demand t
  :config
  ;; I want to switch windows when command is running too...
  (keymap-set eat-eshell-semi-char-mode-map "M-o" #'other-window)

  ;; For `eat-eshell-mode'.
  (add-hook 'eshell-load-hook #'eat-eshell-mode)

  ;; For `eat-eshell-visual-command-mode'.
  (add-hook 'eshell-load-hook #'eat-eshell-visual-command-mode))

(use-package org-modern :ensure t :demand t
  :init
  (setq org-hide-emphasis-markers t
        org-pretty-entities t)
  (global-org-modern-mode))

(use-package pdf-tools :ensure t :demand t
  :hook (pdf-view-mode . auto-revert-mode)
  :config (pdf-tools-install))

(use-package eglot
  :after embark
  :bind ("C-," . eglot-code-actions)
  :hook ((python-mode . eglot-ensure)
         (nix-mode . eglot-ensure))
  :config
  (setq eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
  (keymap-set embark-identifier-map "r" #'eglot-rename)
  (push 'embark--allow-edit
      (alist-get 'eglot-rename embark-target-injection-hooks)))

(use-package eglot-booster :ensure (:type git :host github :repo "jdtsmith/eglot-booster" :files (:defaults "*.el")) :demand t
  :after eglot
  :config	(eglot-booster-mode))

(use-package command-log-mode :ensure t :demand t)

;; (use-package ekg :ensure t :demand t
;;   :bind (([f11] . ekg-capture))
;;   :config
;;   (require 'ekg-auto-save)
;;   (add-hook 'ekg-capture-mode-hook #'ekg-auto-save-mode)
;;   (add-hook 'ekg-edit-mode-hook #'ekg-auto-save-mode))

;;; Language-specific packages
(use-package typst-ts-mode
  :ensure (:type git :host sourcehut :repo "meow_king/typst-ts-mode" :files (:defaults "*.el")) :demand t
  :hook ((typst-ts-mode . electric-pair-mode)
         (typst-ts-mode . smerge-mode))
  :init
  (setq typst-ts-mode-enable-raw-blocks-highlight t)
  :custom
  ;; (optional) If you want to ensure your typst tree sitter grammar version is greater than the minimum requirement
  (typst-ts-mode-grammar-location (expand-file-name "tree-sitter/libtree-sitter-typst.so" user-emacs-directory)))

(use-package nix-mode :ensure t :demand t
  )

(use-package rustic :ensure t :demand t
  :hook (rustic-mode . electric-pair-mode)
  :config
  (setq rustic-lsp-client 'eglot
        rustic-format-on-save t))

(use-package python-mode
  :config
  (define-key python-mode-map (kbd "C-c C-b")
    #'python-shell-send-block-by-markers)
  :bind* (("C-c C-b" . python-shell-send-block-by-markers)
          ("C-c C-d" . duplicate-dwim)
          ("C-c d" . stop-yobaniy-repl)))

(use-package pyvenv
  :ensure t
  :config
  ;(add-hook 'python-mode-hook 'pyvenv-activate)
  (pyvenv-mode 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package paredit :ensure t :demand t)

(use-package julia-snail
  :ensure t
  :custom
  (julia-snail-terminal-type :eat)
  :hook
  (julia-mode . julia-snail-mode))

(use-package glsl-mode
  :ensure t
  :demand t)




;; (use-package combobulate
;;    :custom
;;    ;; You can customize Combobulate's key prefix here.
;;    ;; Note that you may have to restart Emacs for this to take effect!
;;    (combobulate-key-prefix "C-c o")
;;    :hook ((prog-mode . combobulate-mode))
;;    ;; Amend this to the directory where you keep Combobulate's source
;;    ;; code.
;;    :load-path ("path-to-git-checkout-of-combobulate"))

;;; ORG
;;; very cool org plugin
(use-package org-download
  :ensure t
  :demand t
  :after org
  :defer nil
  :custom
  (org-image-actual-width 800)
  :bind
  ("C-M-y" . org-download-clipboard)
  :config
    (require 'org-download))

(setq-default org-download-image-dir "/home/alex/Notes/pngs/")

(setq org-image-actual-width (list 720))


;; Define function to insert a src block
(defun org-insert-src-block ()
    "Insert an Org-mode src block at cursor."
    (interactive)
    (insert "#+begin_src\n\n#+end_src")
    (forward-line -1))  ; Move cursor to the empty line between begin/end

  ;; Bind to a key (e.g., C-c s) in Org mode
(use-package org
    :bind (:map org-mode-map
           ("C-c s" . org-insert-src-block)))

(use-package org-fragtog
    :ensure t)
(add-hook 'org-mode-hook 'org-fragtog-mode)
(setq org-startup-with-latex-preview t)

(setq org-latex-preview-numbered t)

(use-package blacken
  :ensure t
  :hook (python-mode . blacken-mode)
  :custom
  (blacken-line-length 120))

;;; Custom functions
(defun sudo-find-file (file-name)
  "Like find file, but opens the file as root."
  (interactive "FSudo Find File: ")
  (let ((tramp-file-name (concat "/sudo::" (expand-file-name file-name))))
    (find-file tramp-file-name)))


(defun hs-python-custom-setup ()
  (setq hs-block-start-regexp "# start"
      hs-block-end-regexp "# end")
  (hs-minor-mode 1))

(add-hook 'python-mode-hook 'hs-python-custom-setup)

;;; Stop REPL ipython
(defun stop-yobaniy-repl ()
  "Send an interrupt signal to python process"
  (interactive)
  (let ((proc (ignore-errors
                (python-shell-get-process-or-error))))
    (when proc
      (interrupt-process proc))))

(with-eval-after-load 'python
  (define-key python-mode-map (kbd "C-c d")
    #'stop-yobaniy-repl))

(defun python_go_to_up_marker ()
  (list "# start" "# end")
  )


(defun python-shell-send-block-by-markers (start-marker end-marker)
  "Отправить в Python-контейнер код между строками START-MARKER и END-MARKER."
  (interactive
   (list (read-string "Start marker (regex): " "# start")
         (read-string "End marker (regex): "   "# end")))
  (let (beg end)
    (save-excursion
      ;; ищем вверх от курсора START-MARKER
      (unless (search-backward-regexp start-marker nil t)
        (error "Не найден маркер START (%s)" start-marker))
      (forward-line 1)            ; переходим на строку после маркера
      (setq beg (point))
      ;; ищем вниз от beg END-MARKER
      (unless (search-forward-regexp end-marker nil t)
        (error "Не найден маркер END (%s)" end-marker))
      (beginning-of-line)         ; конец блока — перед строкой с END
      (setq end (point)))
    ;; наконец, шлём регион
    (python-shell-send-region beg end)
    (message "Sent region %d…%d to Python" beg end)))


(setq dabbrev-case-fold-search nil)

;; Install all uninstalled packages
(elpaca-process-queues)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files nil)
 '(warning-suppress-log-types '((undo discard-info)))
 '(warning-suppress-types '((emacs))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
