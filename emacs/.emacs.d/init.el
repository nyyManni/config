;; init.el --- Emacs configuration
;; Copyright (c) 2016 - 2017 Henrik Nyman

;; Author     : Henrik Nyman <henrikjohannesnyman@gmail.com>
;; Created    : 10 Aug 2016
;; Modified   : 18 Mar 2018
;; Version    : 1.0

;; The MIT License

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to
;; deal in the Software without restriction, including without limitation the
;; rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
;; sell copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
;; IN THE SOFTWARE.


;;; Commentary:

;; nyyManni's configuration for Emacs.
;;
;; Main packages:
;; - evil for movement
;; - general for keybindings
;; - helm for searching and narrowing
;; - company for completion
;; - flycheck for syntax-checking
;; - IDE configuration for:
;;   * Python
;;   * C/C++
;;   * Java
;;   * JavaScript


;;; Code:

;; Global settings
(setq user-full-name                       "Henrik Nyman"
      user-login-name                      "nyman"
      user-mail-address                    "henrikjohannesnyman@gmail.com"
      user-emacs-directory                 "~/.emacs.d"
      vc-follow-symlinks                   t

      inhibit-startup-screen               t
      inhibit-startup-message              t
      sentence-end-double-space            nil

      ;; Disable custom-set-variable by pointing it's output to a file that is
      ;; never executed.
      custom-file                          (concat user-emacs-directory
                                                   "/customize-ignored.el")

      initial-scratch-message              ""
      ad-redefinition-action               'accept
      backup-directory-alist               '(("." . "~/.emacs.d/backups"))
      auto-save-file-name-transforms       '((".*" "~/.emacs.d/auto-save-list" t))
      delete-old-versions                  -1
      version-control                      t
      vc-make-backup-files                 t
      tab-width                            2
      show-paren-delay                     0
      frame-title-format                   '("" "Emacs v" emacs-version))

(setq-default indent-tabs-mode             nil
              fill-column                  80
              comint-process-echoes        t)


(when window-system
  ;; Allow me to accidentally hit C-x C-c when using graphical Emacs.
  (setq confirm-kill-emacs 'y-or-n-p))

;; Required by evil-collection to be set before loading evil.
(setq evil-want-integration nil)

;; OS X specific settings
(when (eq system-type 'darwin)
  (setq exec-path                          (append exec-path '("/usr/local/bin"))
        default-input-method               "MacOSX"
        flycheck-sh-bash-executable        "/usr/local/bin/bash"
        mac-command-modifier               'meta
        mac-option-modifier                nil
        mac-allow-anti-aliasing            t
        frame-resize-pixelwise             t
        ns-use-srgb-colorspace             nil
        mouse-wheel-scroll-amount          '(5 ((shift) . 5) ((control)))
        mouse-wheel-progressive-speed      nil)

  ;; Environment variables
  (setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
  (setenv "SHELL" "/bin/zsh")
  (setenv "LC_CTYPE" "UTF-8")
  (setenv "LC_ALL" "en_US.UTF-8")
  (setenv "LANG" "en_US.UTF-8")

  ;; Transparent frames. On Linux the same is achieved with compton.
  (defun set-frame-unfocused ()
    (set-frame-parameter (selected-frame) 'alpha '(85 85)))
  (defun set-frame-focused ()
    (set-frame-parameter (selected-frame) 'alpha '(90 90)))

  (add-hook 'focus-in-hook #'set-frame-focused)
  (add-hook 'focus-out-hook #'set-frame-unfocused)
  (set-frame-focused)
  (add-to-list 'default-frame-alist '(alpha 90 90)))


;; Enable disabled commands
(put 'narrow-to-region 'disabled nil)

;; Setup use-package
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(unless (package-installed-p 'diminish)
  (package-refresh-contents)
  (package-install 'diminish))


(eval-when-compile
  (require 'use-package)
  (setq use-package-always-ensure     t
        use-package-check-before-init t))

(require 'diminish)
(require 'bind-key)

;; Load customizations that cannot be put under public VCS. Do not die if the
;; file does not exist.
(let ((work-config (concat user-emacs-directory "/work-config.el")))
  (when (file-exists-p work-config)
    (load-file (concat user-emacs-directory "/work-config.el"))))

(blink-cursor-mode 0)
(global-hl-line-mode 1)

(fset 'yes-or-no-p 'y-or-n-p)

(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

(function-put #'add-hook 'lisp-indent-function 'defun)

;; Package configurations

(use-package gotham-theme
  :demand
  :if (or (daemonp) window-system)
  :init
  (global-unset-key (kbd "C-z"))
  :config
  (load-theme 'gotham t)
  (add-hook 'after-make-frame-functions
    (lambda (frame)
      (load-theme 'gotham t)
      (scroll-bar-mode -1)
      (powerline-reset))))


(defvar re-dbl-quote-str "\"[^\\\\\"]+\\(?:\\\\.[^\\\\\"]*\\)*\""
  "A regular expression matching a double-quoted string.")

(defvar re-sgl-quote-str "'[^\\\\']+\\(?:\\\\.[^\\\\']*\\)*'"
  "A regular expression matching a single-quoted string.")

(defun my-sudo-at-point ()
  "Reopen current file as sudo, preserving location of point."
  (interactive)
  (let ((p (point)))
    (find-alternate-file (concat "/sudo::" buffer-file-name))
    (goto-char p)))

(defun my-reload-file ()
  "Reopen current file, preserving location of point."
  (interactive)
  (let ((p (point)))
    (find-alternate-file buffer-file-name)
    (goto-char p)))

(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))

(defmacro append-to-list (l1 l2)
  "Modify list L1 by appending L2 to it."
  `(setq ,l1 (append ,l1 ,l2)))

(defmacro setq-mode-local (mode &rest args)
  "Add a hook to MODE and set mode-local values for ARGS.

Allows for setting mode-local variables like:
   (setq-mode-local mode-name
                    (variable  . value)
                    (variable2 . value2)
                     ...
                    (variableN . valueN))"
  ;; TODO: use make-symbol for arg.
  `(add-hook ',(intern (concat (symbol-name mode) "-hook"))
     (lambda ()
       ,@(mapcar
          #'(lambda (arg) `(set (make-local-variable ',(car arg)) ,(cdr arg)))
          args))))

(defun is-current-file-tramp ()
  "Check if the file is a remote tramp file."
  (require 'tramp)
  (tramp-tramp-file-p (buffer-file-name (current-buffer))))

(defun my-line-empty-p ()
  "Return t if line containing point has only whitespace."
  (string-match-p "^[[:space:]]*$"
                  (buffer-substring (line-beginning-position)
                                    (line-end-position))))

(defun my-inside-range-p (value lower-bound upper-bound)
  "Check if VALUE is between LOWER-BOUND and UPPER-BOUND.
VALUE being equal to either of the bounds is considered inside."
  (and (<= value upper-bound) (>= value lower-bound)))

(defun my-detect-quotes ()
  "Detects whether point is inside a quoted string.
If it is, then the type of the quotes is returned (double|single)."
  ;; Verify that we are inside a quoted string.
  (when (nth 3 (syntax-ppss))
    (let* ((line (buffer-substring (line-beginning-position) (line-end-position)))
           (dbl-match (string-match re-dbl-quote-str line))
           (dbl-begin (if dbl-match (match-beginning 0) nil))
           (dbl-end (if dbl-match (match-end 0) nil))
           (sgl-match (string-match re-sgl-quote-str line))
           (sgl-begin (if sgl-match (match-beginning 0) nil))
           (sgl-end (if sgl-match (match-end 0) nil))
           (point-pos (- (point) (line-beginning-position))))

      (cond ((and dbl-match sgl-match)
             ;; The line contains both double- and single-quotes, need to
             ;; further analyze.
             (cond ((and (my-inside-range-p point-pos dbl-begin dbl-end)
                         (not (my-inside-range-p point-pos sgl-begin sgl-end)))
                    ;; Point is inside double-quotes, but not inside single-
                    ;; quotes.
                    ;;         " |  "     '    '
                    'double)
                   ((and (my-inside-range-p point-pos sgl-begin sgl-end)
                         (not (my-inside-range-p point-pos dbl-begin dbl-end)))

                    ;; Point is inside single-quotes, but not inside double-
                    ;; quotes.
                    ;;         "    "     ' |  '
                    'single)
                   ((and (my-inside-range-p sgl-begin dbl-begin dbl-end)
                         (my-inside-range-p sgl-end dbl-begin dbl-end))
                    ;; Single-quotes nested inside double-quotes.
                    ;;          "    '  |  '    "
                    'double)
                   ((and (my-inside-range-p dbl-begin sgl-begin sgl-end)
                         (my-inside-range-p dbl-end sgl-begin sgl-end))
                    ;; Double-quotes nested inside single-quotes.
                    ;;          '    "  |  "    '
                    'double)
                   (t
                    ;; Quotations are too complex to be analyzed.
                    nil)))
            (dbl-match
             ;; Line contains only double quotes.
             'double)
            (sgl-match
             ;; Line contains only single quotes.
             'single)
            (t nil)))))

(defun my-split-string (invert)
  "Split a string delimited with single or double quotes at point.
When INVERT equals to t, the return value is set to the other type of quote.
That is for situations where the function detects wrong quotes, and thus the
user can manually override it to use the correct ones."
  (interactive "P")
  (let ((quote-type (my-detect-quotes)))
    (when (not quote-type) (error "Point is not inside a string"))
    (progn
      (insert (if (or (and (equal quote-type 'double) (not invert))
                      (and (equal quote-type 'single) invert))
                  "\"\"" "''"))
      (backward-char)
      (when (commandp 'evil-insert-state)
        (evil-insert-state)))))

(defun my-kwd-list (l kwd)
  "Extract arguments from L that are after KWD but before other keywords."
  (let ((begin (cl-position kwd l)))
    (when begin
      (let ((end (let ((p (cl-position-if #'keywordp (cdr (subseq l begin)))))
                   (when p (+ begin 1 p)))))
        (cdr (subseq l begin end))))))

(defun my-open-lower-third (command &rest args)
  "Open a buffer and run a COMMAND with ARGS in the lower third of the window."
  (interactive)
  (let* ((parent (if (buffer-file-name)
                     (file-name-directory (buffer-file-name))
                   default-directory))
         (height (/ (window-total-height) 3))
         (name   (car (last (split-string parent "/" t)))))
    (split-window-vertically (- height))
    (other-window 1)
    (apply command args)
    (rename-buffer (concat (symbol-name command) " " name "*"))))

;; Disable backup's with tramp files.
(add-hook 'find-file-hook
  (lambda ()
    (if (is-current-file-tramp) (setq-local make-backup-files nil))))

(use-package general
  :functions (space-leader)
  :config
  ;; Fix auto indentation
  (function-put #'general-define-key 'lisp-indent-function 'defun)
  (function-put #'general-create-definer 'lisp-indent-function 'defun)

  (general-create-definer space-leader
    :states '(normal visual insert emacs)
    :global-prefix "C-c"
    :non-normal-prefix "M-SPC"
    :prefix "SPC")

  (function-put #'space-leader 'lisp-indent-function 'defun)

  ; Disable toggling fullscreen with f11
  (general-define-key "<f11>" nil)

  (global-set-key (kbd "C-S-u") 'universal-argument)

  (when (eq system-type 'darwin)
    (general-define-key "<M-f10>"
      (lambda () (interactive)
        (call-process "/Users/hnyman/bin/run-term.applescript"))))

  ;; Global keybindings
  (general-define-key
    :prefix "SPC"
    :states '(normal visual)
    "x"    'helm-M-x
    "b"    'helm-mini
    "c"    'comment-dwim-2
    "O"    'helm-occur
    "A"    'helm-apropos
    "y"    'helm-show-kill-ring
    "H s"  'helm-swop
    "H S"  'helm-multi-swoop-projectile
    "u"    'undo-tree-visualize
    "e"    'eval-last-sexp
    "l p"  'package-list-packages
    "m h"  'mark-whole-buffer
    "w"    'save-buffer
    "D"    'kill-this-buffer
    "h"    'evil-ex-nohighlight
    "a a"  'align-regexp
    "s u"  'my-sudo-at-point
    "s e"  'my-eshell-here
    "s h"  'my-shell-here
    "s '"  'my-split-string
    "s l"  'sort-lines
    "s w"  'whitespace-mode
    "r"    'my-reload-file
    "f"    'helm-imenu
    "g g"  'magit-status
    "S"    'delete-trailing-whitespace
    "i"    'indent-region
    "0"    'delete-window
    "1"    'delete-other-windows
    "2"    'split-window-below
    "3"    'split-window-right))

(use-package org
  :ensure nil
  :defines org-capture-templates
  :init

  (add-hook 'org-capture-mode-hook 'evil-insert-state)

  :general
  (general-define-key
    :keymaps '(org-agenda-mode-map)
    "j"   'evil-next-line
    "k"   'evil-previous-line
    "SPC" nil)

  (space-leader
    :keymaps '(org-mode-map)
    "o t c" 'org-table-create

    ;; Task management keybindings.
    "o t i" 'org-clock-in
    "o s"   'org-todo
    "o e"   'org-edit-special
    "o r f" 'org-refile
    "o t s" 'org-clock-display
    "o n s" 'org-narrow-to-subtree
    "o n w" 'widen)
  (space-leader
    :keymaps '(org-src-mode-map)
    "o e"   'org-edit-src-exit)

  ;; Global org bindings
  (space-leader
    "o a"   'org-agenda
    "o c"   'org-capture
    "o t r" 'org-clock-in-last
    "o p i" 'my-punch-in
    "o t o" 'org-clock-out
    "o t t" 'org-clock-goto
    "o t i" 'org-clock-select-task
    "o p o" 'my-punch-out
    "o t e" 'my-org-export-hourlog))

(use-package adaptive-wrap
  :init
  (add-hook 'org-mode-hook #'adaptive-wrap-prefix-mode))

(use-package evil
  :after general
  :init
  (setq evil-search-module   'evil-search
        evil-want-C-d-scroll t
        evil-want-C-u-scroll t
        evil-want-C-i-jump   t)
  :config

  ;; Unbind M-. and M-, for use with xref
  (general-define-key
    :keymaps '(evil-normal-state-map)
    "M-." nil
    "M-," nil)

  ;; Make escape quit everything, whenever possible.
  (general-define-key
    :keymaps '(evil-normal-state-map evil-visual-state-map)
    "<escape>" 'keyboard-quit)
  (general-define-key
    :keymaps '(minibuffer-local-map
               minibuffer-local-ns-map
               minibuffer-local-must-match-map
               minibuffer-local-isearch-map)
    "<escape>" 'minibuffer-keyboard-quit)

  ;; Completely disable the mouse
  (dolist (key '([drag-mouse-1] [down-mouse-1] [mouse-1]
                 [drag-mouse-2] [down-mouse-2] [mouse-2]
                 [drag-mouse-3] [down-mouse-3] [mouse-3]))
    (global-unset-key key)
    (general-define-key
      :keymaps '(evil-motion-state-map evil-normal-state-map)
      key nil))

  ;; Disable arrow key movement
  (dolist (key '("<left>" "<right>" "<up>" "<down>"))
    (general-define-key :keymaps '(evil-motion-state-map) key nil)
    (global-unset-key (kbd key)))

  ;; Use up and down for scrolling instead
  (general-define-key
    "<up>"   (lambda () (interactive) (scroll-down 1))
    "<down>" (lambda () (interactive) (scroll-up 1)))

  ;; Map ctrl-H to backspace.
  (global-set-key (kbd "M-?") 'help-command)
  (global-set-key (kbd "C-h") 'delete-backward-char)
  (global-set-key (kbd "M-h") 'backward-kill-word)

  (general-define-key
    :states '(visual)
    "<"       'my-evil-shift-left-visual
    ">"       'my-evil-shift-right-visual
    "S-<tab>" 'my-evil-shift-left-visual
    "<tab>"   'my-evil-shift-right-visual)

  ;; Disable C-k, it conflicts with company selecting.
  (eval-after-load "evil-maps"
    (dolist (map '(evil-motion-state-map
       evil-insert-state-map
       evil-emacs-state-map))
      (define-key (eval map) (kbd "C-k") nil)))

  (defun my-evil-shift-left-visual ()
    "Shift left and keep region active."
    (interactive)
    (evil-shift-left (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))

  (defun my-evil-shift-right-visual ()
    "Shift right and keep region active."
    (interactive)
    (evil-shift-right (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))

  (evil-define-operator evil-yank-line-end (beg end type register)
    "Yank to end of line."
    :motion evil-end-of-line
    (interactive "<R><x>")
    (evil-yank beg end type register))

  (general-define-key
    :keymaps '(evil-normal-state-map)
    "Y" 'evil-yank-line-end)

  (evil-set-initial-state 'term-mode 'emacs)
  (evil-mode 1))

(use-package key-chord
  :after general
  :config
  (dolist (chord '("jk" "kj" "JK" "KJ" "jK" "kJ" "Jk" "Kj"))
    (general-define-key
      :keymaps '(evil-insert-state-map evil-visual-state-map)
      (general-chord chord) 'evil-normal-state))
  (key-chord-mode t))

(use-package which-key
  :after evil
  :diminish which-key-mode
  :config
  (which-key-mode))

(use-package company
  :after evil
  :functions (is-empty-line-p my-complete-or-indent)
  :diminish company-mode
  :init
  (add-hook 'prog-mode-hook #'company-mode)
  (setq company-tooltip-align-annotations t)
  :config
  (general-define-key
    :states '(insert)
    "<tab>" 'my-complete-or-indent)
  (defun is-empty-line-p ()
    (string-match "^[[:blank:]]*$"
                  (buffer-substring (line-beginning-position)
                                    (point))))

  (defun my-complete-or-indent ()
    "On an empty (only whitespace) line, do an indent, otherwise auto-complete."
    (interactive)
    (if (is-empty-line-p)
        (indent-for-tab-command)
      (company-complete)))
  :general
  (general-define-key
    :keymaps '(company-template-nav-map)
    "<tab>"   nil
    "C-<tab>" 'company-template-forward-field)
  :bind
  (:map company-active-map
        ("C-j" . company-select-next)
        ("C-k" . company-select-previous)))

(use-package company-childframe
  :disabled t  ;; Not ready yet for everyday use.
  :after 'company
  :config
  (company-childframe-mode -1))

(use-package company-quickhelp
  :after company
  :preface
  (use-package tips
    :ensure nil
    :commands (tips-tooltip-at-point)
    :load-path "~/projects/elisp/tips")

  :config
  ;; Remove all of the formatting in manual pages for eshell.
  (defun my-company-quickhelp-delete-backspaces (orig-fun &rest args)
    (let ((raw-doc (apply orig-fun args)))
      (when raw-doc (replace-regexp-in-string "." "" raw-doc))))

  (advice-add 'company-quickhelp--doc :around
              #'my-company-quickhelp-delete-backspaces)

  (company-quickhelp-mode 1)
  :bind
  (:map company-active-map
   ("C-S-h" . company-quickhelp-manual-begin)))

(use-package yasnippet
  :diminish yas-minor-mode
  :commands (yas-reload-all snippet-mode yas-minor-mode)
  :mode ("\\.yasnippet" . snippet-mode)
  :init
  (add-hook 'prog-mode-hook #'yas-minor-mode)
  :config
  (yas-reload-all)

  ;; Disable tab key for yasnippet, so that it does not cause confusion with
  ;; company-mode.
  (dolist (keymap '(yas-minor-mode-map yas-keymap))
    (define-key (eval keymap) (kbd "<tab>") nil)
    (define-key (eval keymap) [(tab)] nil)
    (define-key (eval keymap) (kbd "S-<tab>") nil)
    (define-key (eval keymap) [(shift tab)] nil)
    (define-key (eval keymap) [backtab] nil))

  (defvar my-yas-expanding nil
    "A flag that is t when a yasnippet expansion is in progress. It is used to
    not load fci-mode with yasnippet expansion.")

  ;; Add hooks for disabling fill-column-indicator while expanding a snippet.
  (defun my-yas-begin-hook ()
    (setq my-yas-expanding t)
    (message "enabling yas-expand-mode")
    (when (and (derived-mode-p 'prog-mode)
               (functionp 'turn-off-fci-mode))
      (turn-off-fci-mode)))
  (defun my-yas-end-hook ()
    (setq my-yas-expanding nil)
    (when (and (derived-mode-p 'prog-mode)
               (functionp 'turn-off-fci-mode))
      (turn-on-fci-mode)))

  ;; (add-hook 'yas-before-expand-snippet-hook 'my-yas-begin-hook)
  ;; (add-hook 'yas-after-exit-snippet-hook 'my-yas-end-hook)

  ;; Use C-& and C-* for going through the fields, since they are positioned
  ;; nicely on a US keyboard.
  (general-define-key
    :states '(insert)
    "C-&" 'yas-expand)
  (general-define-key
    :keymaps '(yas-keymap)
    "C-&" 'yas-next-field-or-maybe-expand
    "C-*" 'yas-prev-field))

(use-package expand-region
  :after evil
  :init
  (general-define-key
    :states '(normal visual)
    "C-+" 'er/expand-region))

(use-package flycheck
  :diminish
  :init
  (add-hook 'prog-mode-hook #'flycheck-mode)
  :config
  (defun my-flycheck-version-advice (orig-fun &rest args)
    "FIXME: Flycheck version broken currently")

  (advice-add 'flycheck-version :around
              #'my-flycheck-version-advice)
  (general-define-key
    :states '(normal visual)
    "[ e" 'flycheck-previous-error
    "] e" 'flycheck-next-error))

(use-package elpy
  :mode ("\\.py\\'" . python-mode)
  :init
  (add-hook 'python-mode-hook (lambda () (elpy-mode 1)))

  (setq jedi:doc-display-buffer 'my-jedi-show-doc
        jedi:tooltip-method     nil
        jedi:use-shortcuts      t)

  (when (executable-find "ipython")
    (setq python-shell-interpreter      "ipython"
          python-shell-interpreter-args (concat "--simple-prompt "
                                                "--no-banner "
                                                "-i --no-confirm-exit "
                                                "--colors=NoColor")))
  :general
  (general-define-key
    :states '(insert)
    :keymaps '(python-mode-map)
    "C-<tab>" 'jedi:get-in-function-call)
  (general-define-key
    :states '(normal)
    :keymaps '(python-mode-map)
    "C-<tab>" 'jedi:show-doc)

  (general-define-key
    :keymaps '(python-mode-map)
    "C->" 'sp-forward-slurp-sexp
    "C-<" 'sp-forward-barf-sexp)

  (general-define-key
    :keymaps '(python-mode-map)
    :states '(normal visual)
    "[ f" 'python-nav-backward-defun
    "] f" 'python-nav-forward-defun
    "[ b" 'python-nav-backward-block
    "] b" 'python-nav-forward-block)
  (space-leader
    :keymaps '(python-mode-map realgud-mode-map)
    "p v"   'my-python-change-venv
    "p d"   'jedi:goto-definition
    "p b a" 'realgud-short-key-mode
    "p u"   'helm-jedi-related-names
    "p ?"   'jedi:show-doc
    "p r"   'run-python
    "p t"   'my-run-unittests
    "m f"   'python-mark-defun
    "e"     'my-python-send-region-or-buffer)
  (general-define-key
    :states '(normal)
    :keymaps '(python-mode-map realgud-mode-map)
    "M-."  'elpy-goto-definition
    "M-,"  'xref-pop-marker-stack)

  ;; :bind
  ;; (:map python-mode-map
  ;;       ("M-." . elpy-goto-definition)
  ;;       ("M-," . xref-pop-marker-stack))
  :config
  (elpy-enable)

  (defun my-python-change-venv ()
    "Switches to a new virtualenv, and reloads flycheck and company."
    (interactive)
    (call-interactively 'pyvenv-workon)
    (when (eq major-mode 'python-mode)
      ;; Reset flycheck and company to new venv.
      (flycheck-buffer)
      (jedi:stop-server)
      (pyvenv-restart-python)))

  (defun my-jedi-show-doc (buffer)
    (with-current-buffer buffer
      (tips-tooltip-at-point (buffer-string) 0 1 300)))

  (defun my-python-send-region-or-buffer ()
    "Send buffer contents to an inferior Python process."
    (interactive)
    (if (evil-visual-state-p)
        (let ((r (evil-visual-range)))
          (python-shell-send-region (car r) (cadr r)))
      (python-shell-send-buffer t)))

  (define-key inferior-python-mode-map
    [(control return)] 'my-ipython-follow-traceback)

  (defun my-ipython-follow-traceback ()
    "Open the file at the line where the exception was rised."
    (interactive)
    (backward-paragraph)
    (forward-line)
    (re-search-forward "^\\(.*\\) in .*$")
    (let ((filename (match-string 1)))
      (re-search-forward "^-+> \\([0-9]+\\)")
      (let ((lineno (match-string 1)))
        (forward-whitespace 1)
        (find-file-existing filename)
        (goto-char (point-min))
        (forward-line (- (string-to-number lineno) 1))
        (forward-whitespace 1)
        (recenter))))

  (defun my-run-unittests (arg)
    "Run unittests in the current project. Use prefix-argument ARG to specify
the command to run the tests with."
    (interactive "P")
    (let ((compilation-read-command arg))
      (call-interactively 'projectile-test-project)))

  (add-hook 'inferior-python-mode-hook #'company-mode)
  ;; (add-hook 'python-mode-hook #'my-python-hook)

  ;; (function-put #'font-lock-add-keywords 'lisp-indent-function 'defun)

  ;; Syntax highlighting for ipython tracebacks.
  (font-lock-add-keywords 'inferior-python-mode
    '(("^-\\{3\\}-+$" . font-lock-comment-face)
      ("^\\([a-zA-Z_0-9]+\\) +\\(Traceback (most recent call last)\\)$"
       (1 font-lock-warning-face)
       (2 font-lock-constant-face))
      ("^\\(.*\\) in \\(<?[a-zA-Z_0-9]+>?\\)(.*)$"
       (1 font-lock-constant-face)
       (2 font-lock-function-name-face))
      ("^-*> +[[:digit:]]+ .*$" . font-lock-builtin-face)
      ("^   +[[:digit:]]+ " . font-lock-comment-face)))

  ;; Recenter the buffer after following the symbol under cursor.
  (defun my-recenter (&rest args) (recenter))
  (advice-add #'jedi:goto-definition--nth :after #'my-recenter)



  ;; Function and class text objects
  (evil-define-text-object my-python-a-function (count &optional beg end type)
    :type line
    (save-excursion
      (end-of-line)
      (re-search-backward "^\\([[:space:]]*\\)def[[:space:]]+")
      (let ((defun-begin (point)))

        (forward-line -1)
        ;; Include decorators
        (while (string-match-p "^[[:space:]]*@"
                               (buffer-substring (line-beginning-position)
                                                 (line-end-position)))
          (forward-line -1))
        (unless (my-line-empty-p)
          (forward-line 1))
        (let* ((dec-begin (point))
               (match (match-string 1))
               (whitespace-level (number-to-string (length match))))
          (goto-char defun-begin)

          (forward-line 1)

          (if (re-search-forward (concat "^[[:space:]]\\{0," whitespace-level
                                         "\\}[^[:space:]\n]")
                                 nil t)
              (forward-line -1)
            (goto-char (point-max)))

          (while (my-line-empty-p)
            (forward-line -1))
          (forward-line 1)
          (evil-range dec-begin (point) type :expanded t)))))

  (evil-define-text-object my-python-inner-function (count &optional beg end type)
    (save-excursion
      (python-mark-defun)
      (re-search-forward "(")
      (evil-jump-item)
      (evil-next-line-first-non-blank)
      (evil-range (region-beginning) (region-end) type :expanded t)))

  (evil-define-text-object my-python-a-class (count &optional beg end type)
    :type line
    (save-excursion
      (let ((start-pos (point)))
        (re-search-backward "^\\([[:space:]]*\\)class[[:space:]]+")
        (let* ((cls-begin (point-at-bol))
               (match (match-string 1))
               (whitespace-level (number-to-string (length match))))
          (forward-line 1)

          (if (re-search-forward (concat "^[[:space:]]\\{0," whitespace-level
                                         "\\}[^[:space:]\n]")
                                 nil t)
              (forward-line -1)
            (goto-char (point-max)))

          (while (my-line-empty-p)
            (forward-line -1))
          (forward-line 1)
          (message "point: %s start-pos: %s" (point) start-pos)
          ;; (when (> (point) start-pos)
          ;;   (error "Not inside a class"))
          (evil-range cls-begin (point) type :expanded t)))))

  (evil-define-text-object my-python-inner-class (count &optional beg end type)
    (save-excursion
      (let ((start-pos (point)))
        (re-search-backward "^\\([[:space:]]*\\)class[[:space:]]+")
        (forward-line 1)
        (let* ((cls-begin (point-at-bol))
               (match (match-string 1))
               (whitespace-level (number-to-string (length match))))
          (forward-line 1)

          (if (re-search-forward (concat "^[[:space:]]\\{0," whitespace-level
                                         "\\}[^[:space:]\n]")
                                 nil t)
              (forward-line -1)
            (goto-char (point-max)))

          (while (my-line-empty-p)
            (forward-line -1))
          (forward-line 1)
          (when (> (point) start-pos)
            (error "Not inside a class"))
          (evil-range cls-begin (point) type :expanded t)))))

  (defun my-mark-inner-arg ()
    (interactive)
    (re-search-backward "[(,]")
    (evil-forward-char)
    (when (looking-at-p " ")
      (evil-forward-char))
    (when (looking-at-p "\n")
      (evil-next-line-first-non-blank))
    (set-mark (point))
    (re-search-forward (concat "\\(" re-dbl-quote-str "\\|" re-sgl-quote-str
                               "\\|([^=:)(]*)\\)?[),]"))
    (evil-backward-char))

  (defun my-mark-a-arg ()
    (interactive)
    (re-search-backward "[(,]")
    (evil-forward-char)
    (when (looking-at-p " ")
      (evil-forward-char))
    (when (looking-at-p "\n")
      (evil-next-line-first-non-blank))
    (set-mark (point))
    (re-search-forward (concat "\\(" re-dbl-quote-str "\\|" re-sgl-quote-str
                               "\\|([^=:)(]*)\\)?[),]"))
    (evil-backward-char)
    (if (looking-at-p ")")
        (progn
          (exchange-point-and-mark)
          (re-search-backward "[(,]")
          (when (looking-at-p "(")
            (evil-forward-char)))
      (evil-forward-char))
    (when (looking-at-p " ")
      (evil-forward-char)))

  (evil-define-text-object my-python-inner-arg (count &optional beg end type)
    (interactive)
    (save-excursion
      (my-mark-inner-arg)
      (evil-range (region-beginning) (region-end) type :expanded t)))

  (evil-define-text-object my-python-a-arg (count &optional beg end type)
    (interactive)
    (save-excursion
      (my-mark-a-arg)
      (evil-range (region-beginning) (region-end) type :expanded t)))


  (defun my-shift-arg-forwards ()
    (interactive)
    (let ((pos (point)))
      (let (b1 b2 e1 e2)
        (my-mark-inner-arg)
        (setq e1 (point-marker))
        (exchange-point-and-mark)
        (setq b1 (point-marker))
        (exchange-point-and-mark)

        (deactivate-mark)

        (unless (looking-at ",")
          (goto-char pos)
          (error "Last argument"))

        (forward-word)
        (my-mark-inner-arg)
        (setq e2 (point-marker))
        (exchange-point-and-mark)
        (setq b2 (point-marker))
        (exchange-point-and-mark)

        (deactivate-mark)

        (evil-exchange--do-swap (current-buffer) (current-buffer)
                                b2 e2 b1 e1
                                #'delete-and-extract-region #'insert
                                nil))))

  (defun my-shift-arg-backwards ()
    (interactive)
    (let ((pos (point)))
      (let (b1 b2 e1 e2)
        (my-mark-inner-arg)
        (setq e1 (point-marker))
        (exchange-point-and-mark)
        (setq b1 (point-marker))

        (deactivate-mark)

        (backward-char)
        (backward-char)

        (unless (looking-at ",")
          (goto-char pos)
          (error "First argument"))

        (my-mark-inner-arg)
        (setq e2 (point-marker))
        (exchange-point-and-mark)
        (setq b2 (point-marker))
        (exchange-point-and-mark)

        (deactivate-mark)

        (evil-exchange--do-swap (current-buffer) (current-buffer)
                                b2 e2 b1 e1
                                #'delete-and-extract-region #'insert
                                nil))))

  (space-leader
    :keymaps '(python-mode-map)
    "C->" 'my-shift-arg-forwards
    "C-<" 'my-shift-arg-backwards
    )

  (define-key evil-inner-text-objects-map "f" 'my-python-inner-function)
  (define-key evil-outer-text-objects-map "f" 'my-python-a-function)

  (define-key evil-inner-text-objects-map "C" 'my-python-inner-class)
  (define-key evil-outer-text-objects-map "C" 'my-python-a-class)

  (define-key evil-inner-text-objects-map "a" 'my-python-inner-arg)
  (define-key evil-outer-text-objects-map "a" 'my-python-a-arg))

(use-package realgud-pydev
  :ensure nil
  :load-path "~/projects/git/hnyman/pydev-client"
  :init
  (setq realgud-safe-mode nil)
  :config
  (add-hook 'realgud-short-key-mode-hook
    (lambda ()
      (local-set-key "\C-c" realgud:shortkey-mode-map)))
  (defun my-shortkey-mode-hook ()
    (evil-insert-state 1))
  (add-hook 'realgud-short-key-mode-hook #'my-shortkey-mode-hook)

  (add-to-list 'display-buffer-alist
               `(,(rx bos "*" "pydevc " (+? nonl) "*" eos)
                 (display-buffer-in-side-window)
                 (reusable-frames . visible)
                 (side            . right)
                 (slot            . 1)
                 (window-width    . 0.5)))

  (defun my-gud--setup-realgud-windows (&optional buffer)
    "Replacement function to realgud window arrangement.
Uses `current-buffer` or BUFFER."
    (interactive)
    (let* ((buffer (or buffer (current-buffer)))
           (src-buffer (realgud-get-srcbuf buffer))
           (cmd-buffer (realgud-get-cmdbuf buffer)))
      (display-buffer cmd-buffer)
      (select-window (display-buffer src-buffer))))

  (defalias 'realgud-window-src-undisturb-cmd #'my-gud--setup-realgud-windows)
  :general
  (space-leader
    :keymaps '(python-mode-map)
    "p b r" 'realgud:pydev-current-file
    "p b m" 'realgud:pydev-module
    "p b q" 'pydev-reset))

(use-package debian-changelog-mode
  :ensure nil
  :load-path "~/projects/elisp/debian-changelog-mode")


(use-package jedi-core
  :after python)

(use-package pyvenv
  :after python
  :commands (pyvenv-tracking-mode)
  :init
  (add-hook 'python-mode-hook #'pyvenv-tracking-mode))

(use-package py-autopep8
  :commands (py-autopep8-enable-on-save)
  :init
  ;; Set the line-length for autopep to something large so that it
  ;; does not touch too long lines, it usually cannot fix them properly
  (setq py-autopep8-options '("--max-line-length=200"))
  (add-hook 'python-mode-hook #'py-autopep8-enable-on-save)
  :general
  (space-leader
    :keymaps '(python-mode-map)
    "p f" 'py-autopep8-buffer))

(use-package py-yapf
  :disabled t
  :commands (py-yapf-enable-on-save)
  :init
  (remote-hook 'python-mode-hook 'py-yapf-enable-on-save))

(use-package ace-window
  :after general
  :defines (aw-dispatch-always)
  :init
  (setq aw-dispatch-always 1))

(use-package slime
  :init
  (setq inferior-lisp-program "sbcl"
        slime-default-lisp    'sbcl)
  :config
  (defun my-eval-sexp-or-region ()
    "Evaluate an s-expression or a region."
    (interactive)
    (if (evil-visual-state-p)
        (let ((r (evil-visual-range)))
          (eval-region (car r) (cadr r)))
      (eval-last-sexp nil)))
  (defun my-eval-and-replace ()
    "Replace the preceding sexp with its value."
    (interactive)
    (backward-kill-sexp)
    (condition-case nil
        (prin1 (eval (read (current-kill 0)))
               (current-buffer))
      (error (message "Invalid expression")
             (insert (current-kill 0)))))
  :general
  (general-define-key
    :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "C-c C-c" 'my-eval-sexp-or-region)
  (space-leader
    :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "m f" 'mark-defun
    "p d" 'find-function-at-point
    "E"   'my-eval-and-replace))

(use-package hlinum
  :config
  (hlinum-activate)
  (require 'show-fill-column-indicator)
  (require 'display-line-numbers)

  (add-hook 'prog-mode-hook #'show-fill-column-indicator-mode)
  (add-hook 'prog-mode-hook #'display-line-numbers-mode)

  (remove-hook 'post-command-hook 'hlinum-highlight-region)
  (set-face-attribute 'line-number-current-line nil
                      :inherit 'linum
                      :foreground "#CAE682"
                      :background "#444444"
                      :weight 'bold))

(use-package comment-dwim-2)

(use-package magit
  :commands (magit-status)
  :init
  (setq magit-branch-arguments nil)
  (when (eq system-type 'darwin)
    (setq magit-git-executable "/usr/local/bin/git"))
  :config
  ;; Start the commit window in insert mode
  (add-hook 'with-editor-mode-hook 'evil-insert-state)

  ;; Don't display Arev in the mode line.
  (diminish 'auto-revert-mode)
  :general
  (space-leader
    "g b"   'magit-blame
    "g f h" 'magit-log-buffer-file))

(use-package evil-magit
  :after magit)

(use-package powerline
  :config (powerline-center-evil-theme))

(use-package smooth-scrolling
  :disabled t
  :config
  (setq scroll-step              1
        scroll-conservatively    10000
        scroll-margin            1
        smooth-scroll-margin     1
        scroll-up-aggressively   0.0
        scroll-down-aggressively 0.0)
  (setq-default scroll-up-aggressively   0.0)
  (setq-default scroll-down-aggressively 0.0)
  (smooth-scrolling-mode 1))

(use-package helm
  :after evil
  :defines (helm-idle-delay
            helm-quick-update
            helm-M-x-requires-pattern
            helm-ff-skip-boring-files
            helm-ff-search-library-in-sexp
            helm-ff-file-name-history-use-recentf)
  :diminish helm-mode
  :init
  (setq helm-candidate-number-limit           100
        helm-idle-delay                       0.0
        helm-input-idle-delay                 0.01
        helm-quick-update                     t
        helm-M-x-requires-pattern             nil
        helm-ff-skip-boring-files             t
        helm-move-to-line-cycle-in-source     t
        helm-split-window-inside-p            t
        helm-ff-search-library-in-sexp        t
        helm-scroll-amount                    8
        helm-ff-file-name-history-use-recentf t)
  :config
  (require 'helm-config)
  (helm-mode 1)
  (helm-autoresize-mode t)

  (defun helm-skip-dots (old-func &rest args)
    "Skip . and .. initially in helm-find-files.  First call OLD-FUNC with ARGS."
    (apply old-func args)

    ;; When doing rgrepping, it is usually preferred to select '.'
    (when (not (equal (buffer-name) "*helm-mode-rgrep*"))
      (let ((sel (helm-get-selection)))
        (if (and (stringp sel) (string-match "/\\.$" sel))
            (helm-next-line 2)))
      (let ((sel (helm-get-selection))) ; if we reached .. move back
        (if (and (stringp sel) (string-match "/\\.\\.$" sel))
            (helm-previous-line 1)))))

  (advice-add #'helm-preselect :around #'helm-skip-dots)
  (advice-add #'helm-ff-move-to-first-real-candidate :around #'helm-skip-dots)
  :bind
  (("M-x" . helm-M-x)
   :map helm-map
   ("C-i"   . helm-execute-persistent-action)
   ("C-k"   . helm-previous-line)
   ("C-j"   . helm-next-line)
   ("C-l"   . helm-next-source))
  :general
  (space-leader
    ";" 'helm-find-files))

(use-package projectile
  ;; :after helm
  :defines (projectile-completion-system
            projectile-enable-caching
            projectile-use-git-grep)
  :diminish projectile-mode
  :init

  (setq safe-local-variable-values
        '((projectile-project-test-cmd . "pytest test.py")
          (projectile-project-test-cmd . "pytest")
          (projectile-project-compilation-cmd . "make")
          (projectile-project-compilation-cmd . "make ergodox_ez-allsp-nyymanni-all")
          (projectile-project-compilation-cmd . "make -j8")
          (projectile-project-compilation-cmd . "make -j8 && make install")))

  ;; Parse shell color escape codes in  compilation buffer.
  (require 'ansi-color)
  (defun endless/colorize-compilation ()
    "Colorize from `compilation-filter-start' to `point'."
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region
       compilation-filter-start (point))))

  (add-hook 'compilation-filter-hook
    #'endless/colorize-compilation)


  (setq projectile-completion-system 'default
        projectile-enable-caching    t
        projectile-use-git-grep      t)
  :config
  (projectile-register-project-type 'python '(".python")
                                    :compile "python setup.py bdist_wheel"
                                    :test "python test.py")
  (projectile-mode)
  (append-to-list projectile-globally-ignored-directories
                  '(".git" "venv" "build" "dist"))
  (append-to-list projectile-globally-ignored-file-suffixes
                  '("pyc" "jpeg" "jpg" "png"))
  (append-to-list projectile-globally-ignored-files
                  '(".DS_Store")))

(use-package helm-projectile
  :after projectile
  :general
  (space-leader
    "G p" 'projectile-grep
    "G P" 'helm-projectile-grep
    "G r" 'rgrep
    "'"   'projectile-switch-project
    ":"   'helm-projectile-find-file
    "\""  'helm-projectile))

(use-package windmove
  :config
  (defun my-frame-pos-x (frame)
    "Get the x position of the FRAME on display.
On multi-monitor systems the display spans across all the monitors."
    (+ (car (frame-position frame))
       (cadaar
        (display-monitor-attributes-list frame))))

  (defun my-frame-not-current-but-visible-p (frame)
    ;; TODO: frame-visible-p does not work on OS X, so this function returns
    ;;       also frames that are on other virtual desktops.
    (and (frame-visible-p frame)
         (not (eq frame (selected-frame)))))

  (defun my-frame-to (direction)
    "Find next frame to DIRECTION or nil."
    (let* ((current-frame-pos (my-frame-pos-x (selected-frame)))
           (frame-candidates
            (cl-remove-if-not #'my-frame-not-current-but-visible-p
                              (frame-list)))
           (frame-to-left
            (car
             (sort
              (cl-remove-if-not (lambda (frame) (< (my-frame-pos-x frame)
                                                   current-frame-pos))
                                frame-candidates)
              (lambda (a b) (> (my-frame-pos-x a) (my-frame-pos-x b))))))
           (frame-to-right
            (car
             (sort
              (cl-remove-if-not (lambda (frame) (> (my-frame-pos-x frame)
                                                   current-frame-pos))
                                frame-candidates)
              (lambda (a b) (< (my-frame-pos-x a) (my-frame-pos-x b)))))))

      (cond ((eq direction 'left)
             frame-to-left)
            ((eq direction 'right)
             frame-to-right)
            (t (error "Unknown direction")))))

  (defun my-frame-center-pos (&optional frame)
    `(,(/ (frame-pixel-width frame) 2)
      ,(/ (frame-pixel-height frame) 2)))

  (defun my-windmove-advice (orig-fun dir &rest args)
    "Extend the range of windmove to go to next and previous frames."
    (condition-case err
        (apply orig-fun dir (cons dir args))
      (user-error
       (if (or (eq dir 'left) (eq dir 'right))
           (progn
             (select-frame-set-input-focus
              (or (my-frame-to dir)
                  (signal (car err) (cdr err))))
             (condition-case err
                 (let ((inverted-dir (if (eq dir 'right) 'left 'right)))
                   (while t
                     ;; Switched frame, go as far as possible to the other
                     ;; direction, user-error is signaled when it hits the frame
                     ;; boundary.
                     (apply orig-fun inverted-dir (cons inverted-dir args))))
               (user-error nil))
             ;; Move the mouse to the middle of the new frame. The frame switch
             ;; may have moved the focus into a new monitor, but all of the
             ;; keyboard shortcuts work on the monitor that currently has the
             ;; mouse.
             (apply 'set-mouse-pixel-position (cons (selected-frame)
                                                    (my-frame-center-pos))))
         (signal (car err) (cdr err))))))

  (advice-add 'windmove-do-window-select :around #'my-windmove-advice)

  :bind
  (("C-S-j" . windmove-down)
   ("C-S-k" . windmove-up)
   ("C-S-h" . windmove-left)
   ("C-S-l" . windmove-right)))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode))

(use-package evil-indent-textobject
  :after evil)

(use-package evil-visualstar
  :after evil
  :defines (evil-visualstar/persistent)
  :init
  (setq evil-visualstar/persistent t)
  :config
  (global-evil-visualstar-mode 1))

(use-package evil-numbers
  :commands (evil-numbers/inc-at-pt evil-numbers/dec-at-pt)
  :after evil
  :general
  (space-leader
    "+" 'evil-numbers/inc-at-pt
    "-" 'evil-numbers/dec-at-pt))

(use-package evil-ediff
  :after evil
  :config
  (setq ediff-window-setup-function 'ediff-setup-windows-plain
        ediff-split-window-function 'split-window-horizontally))

(use-package evil-indent-plus
  :after evil
  :general
  (general-define-key
    :keymaps '(evil-inner-text-objects-map)
    "i" 'evil-indent-plus-i-indent
    "I" 'evil-indent-plus-i-indent-up
    "J" 'evil-indent-plus-i-indent-up-down)
  (general-define-key
    :keymaps '(evil-outer-text-objects-map)
    "i" 'evil-indent-plus-a-indent
    "I" 'evil-indent-plus-a-indent-up
    "J" 'evil-indent-plus-a-indent-up-down))

(use-package evil-nerd-commenter
  :after evil
  :config
  ;; Just using nerd-commenter for the text objects.
  (define-key evil-inner-text-objects-map "c" 'evilnc-inner-comment)
  (define-key evil-outer-text-objects-map "c" 'evilnc-outer-commenter))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

(use-package evil-exchange
  :after evil
  :config
  (evil-exchange-install))

(use-package evil-textobj-anyblock
  :after evil
  :config
  (define-key evil-inner-text-objects-map "b" 'evil-textobj-anyblock-inner-block)
  (define-key evil-outer-text-objects-map "b" 'evil-textobj-anyblock-a-block)

  (evil-define-text-object my-python-inner-docstring
    (count &optional beg end type)
    "Select the closest outer quote."
    (let ((evil-textobj-anyblock-blocks
           '(("'''" . "'''")
             ("\"\"\"" . "\"\"\""))))
      (evil-textobj-anyblock--make-textobj beg end type count nil)))
  (evil-define-text-object my-python-a-docstring
    (count &optional beg end type)
    (let ((evil-textobj-anyblock-blocks
           '(("'''" . "'''")
             ("\"\"\"" . "\"\"\""))))
      (evil-textobj-anyblock--make-textobj beg end type count t)))
  (define-key evil-inner-text-objects-map "D" 'my-python-inner-docstring)
  (define-key evil-outer-text-objects-map "D" 'my-python-a-docstring))

(use-package evil-args
  :after 'evil
  :config

  ;; bind evil-args text objects
  (define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
  (define-key evil-outer-text-objects-map "a" 'evil-outer-arg)

  ;; bind evil-forward/backward-args
  (define-key evil-normal-state-map "L" 'evil-forward-arg)
  (define-key evil-normal-state-map "H" 'evil-backward-arg)
  (define-key evil-motion-state-map "L" 'evil-forward-arg)
  (define-key evil-motion-state-map "H" 'evil-backward-arg)

  ;; bind evil-jump-out-args
  (define-key evil-normal-state-map "K" 'evil-jump-out-args))

;; Evilify some modes not evilified by evil.
(defmacro evilify (mode &optional module)
  "Apply evil-bindings to MODE with evil-collection.
If module name differs from MODE, a custom one can be given with MODULE."
  `(with-eval-after-load ',(or module mode)
     (require ',(intern (concat "evil-collection-" (symbol-name mode))))
     (,(intern (concat "evil-collection-" (symbol-name mode) "-setup")))))

(use-package evil-collection
  :after evil
  :config
  (evilify package-menu package)

  (evilify compile)
  (evilify calendar)
  (evilify dired)

  ;; (evilify term)

  ;; Do not use space for dired-next-line
  (general-define-key :keymaps '(dired-mode-map) :states '(normal) "SPC" nil)
  (evilify rtags))


(use-package smartparens
  :diminish smartparens-mode
  :after general
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (general-define-key
    :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "C->" 'sp-forward-slurp-sexp)
  (sp-pair "{%" "%}")
  (show-smartparens-global-mode 1))

(use-package org
  :functions (my-org-mode-hook)
  :defines (org-export-async-init-file)
  :init
  (setq org-export-async-init-file (concat user-emacs-directory
                                           "/org-async-init.el")
        org-confirm-babel-evaluate nil)
  (add-hook 'org-mode-hook #'my-org-mode-hook)
  :config
  (defun my-org-pdf-async ()
    "Perform an async pdf export."
    (interactive)
    (org-latex-export-to-pdf t))
  (defun my-org-mode-hook ()
    (visual-line-mode 1))
  :general
  (space-leader
    :keymaps '(org-mode-map)
    "E" 'my-org-pdf-async))

(use-package undo-tree
  :diminish undo-tree-mode)

;; Currently replaced with native fill column indicator, which does not conflict
;; with company-mode.
(use-package fill-column-indicator
  :disabled t
  :if (or (daemonp) window-system)
  :functions (on-off-fci-before-company)
  :commands (fci-mode)
  :init
  (setq fci-rule-column 80
        fci-rule-color "#195466"
        fci-rule-image-format 'pbm)
  (add-hook 'prog-mode-hook #'fci-mode)
  :config
  ;; fci-mode conflicts with company-dialogs. Temporarily disable fci when
  ;; company-dialog is visible.
  (defun on-off-fci-before-company (command)

    ;; While yasnippet is expanding, the fci-mode is already disabled, and it
    ;; should not be enabled before snippet expanding is done.
    (unless (and (boundp 'my-yas-expanding) my-yas-expanding)
      (when (derived-mode-p 'prog-mode)
        (when (string= "show" command)
          (turn-off-fci-mode))
        (when (string= "hide" command)
          (turn-on-fci-mode)))))
  (advice-add 'company-call-frontends :before #'on-off-fci-before-company))

(use-package term
  :ensure nil
  :functions (my-shell-here)
  :config
  (add-hook 'term-mode-hook (lambda () (setq-local global-hl-line-mode nil)))
  (defun my-shell-here ()
    "Open a ANSI term in the lower third."
    (interactive)
    (my-open-lower-third 'ansi-term "/bin/zsh"))

  (defun my-quit-shell ()
    "Kill the current shell."
    (interactive)
    (let ((kill-buffer-query-functions (delq 'process-kill-buffer-query-function
                                             kill-buffer-query-functions)))
      (kill-buffer)
      (delete-window)))

  (general-define-key
    :keymaps 'term-raw-map
    "M-y"   'term-paste
    "C-S-q" 'my-quit-shell))

(use-package eshell
  :commands (my-eshell-here)
  :functions (my-eshell-hook)
  :defines (eshell-banner-message eshell-cmpl-cycle-completions)
  :init
  (setq eshell-banner-message         ""
        eshell-cmpl-cycle-completions nil
        pcomplete-cycle-completions   nil)
  (add-hook 'eshell-mode-hook #'my-eshell-hook)

  :general
  (space-leader
    :keymaps '(eshell-mode-map)
    "h" 'helm-eshell-history)
  :config
  (require 'dash)
  (require 's)
  (require 'pyvenv)

  (defmacro with-face (STR &rest PROPS)
    "Return STR propertized with PROPS."
    `(propertize ,STR 'face (list ,@PROPS)))

  (defmacro esh-section (NAME ICON FORM &rest PROPS)
    "Build eshell section NAME with ICON prepended to evaled FORM with PROPS."
    `(setq ,NAME
           (lambda () (when ,FORM
                        (-> ,ICON
                            (concat esh-section-delim ,FORM)
                            (with-face ,@PROPS))))))

  (defun esh-acc (acc x)
    "Accumulator for evaluating and concatenating esh-sections."
    (--if-let (funcall x)
        (if (s-blank? acc)
            it
          (concat acc esh-sep it))
      acc))

  (defun esh-prompt-func ()
    "Build `eshell-prompt-function'"
    (concat esh-header
            (-reduce-from 'esh-acc "" eshell-funcs)
            "\n"
            eshell-prompt-string))




  ;; Separator between esh-sections
  (setq esh-sep " | ")  ; or " | "

  ;; Separator between an esh-section icon and form
  (setq esh-section-delim " ")

  ;; Eshell prompt header
  (setq esh-header "\n┌─")  ; or "\n┌─"

  ;; Eshell prompt regexp and string. Unless you are varying the prompt by eg.
  ;; your login, these can be the same.
  (setq eshell-prompt-regexp "└─> ")   ; or "└─> "
  (setq eshell-prompt-string "└─> ")   ; or "└─> "


  (esh-section esh-dir
               "\xf07c"  ;  (faicon folder)
               (abbreviate-file-name (eshell/pwd))
               '(:foreground "gold" :bold ultra-bold :underline t))

  (esh-section esh-git
               ;; "\xe907"  ;  (git icon)
               "⎇"
               (magit-get-current-branch)
               `(:foreground ,(face-foreground font-lock-type-face)))

  (esh-section esh-python
               "\xe928"  ;  (python icon)
               pyvenv-virtual-env-name)

  (esh-section esh-clock
               "\xf017"  ;  (clock icon)
               (format-time-string "%H:%M" (current-time))
               `(:foreground ,(face-foreground font-lock-string-face)))


    ;; Below I implement a "prompt number" section
    (setq esh-prompt-num 0)
    (add-hook 'eshell-exit-hook (lambda () (setq esh-prompt-num 0)))
    (advice-add 'eshell-send-input :before
                (lambda (&rest args) (setq esh-prompt-num (incf esh-prompt-num))))

    (esh-section esh-num
                 "\xf0c9"  ;  (list icon)
                 (number-to-string esh-prompt-num)
                 '(:foreground "brown"))

    ;; Choose which eshell-funcs to enable
    (setq eshell-funcs (list esh-dir esh-python esh-git esh-clock esh-num))

    ;; Enable the new eshell prompt
    (setq eshell-prompt-function 'esh-prompt-func)
  ;; bug#18951: complete-at-point removes an asterisk when it tries to
  ;;            complete. Disable idle completion until resolved.
  (setq-mode-local eshell-mode
                   (company-idle-delay . nil)
                   (company-backends   . '((company-shell company-capf))))

  (defun my-eshell-history ()
    (interactive)
    (my-eshell-go-to-prompt)
    (eshell-bol)
    ;; If the line is not empty, kill the rest of the line.
    (when (not (looking-at "$"))
      (kill-line nil))
    (call-interactively 'helm-eshell-history))
  (defun my-eshell-hook ()
    (general-define-key
      :states '(normal)
      :keymaps '(eshell-mode-map)
      :prefix "SPC"
      "h" 'my-eshell-history)
    (general-define-key
      :keymaps 'eshell-mode-map
      "C-S-q" 'my-quit-eshell)
    (general-define-key
      :states '(normal)
      :keymaps '(eshell-mode-map)
      "i" 'my-eshell-go-to-prompt
      "I" 'my-eshell-insert-beginning-of-line
      "0" 'eshell-bol))

  (defun my-eshell-here ()
    "Opens up a new shell in the directory associated with the
  current buffer's file. The eshell is renamed to match that
  directory to make multiple eshell windows easier."
    (interactive)
    (my-open-lower-third 'eshell "new"))

  (defun my-quit-eshell ()
    (interactive)
    (eshell-life-is-too-much)
    (delete-window))

  (defun my-eshell-within-command-p ()
    "Check if point is at the command prompt."
    (interactive)
    (let ((p (point)))
      (eshell-bol)
      (let ((v (>= p (point))))
        (goto-char p)
        v)))

  (defun my-eshell-go-to-prompt ()
    "Puts point to the end of the prompt."
    (interactive)
    (if (my-eshell-within-command-p)
        (evil-insert-state)
      (progn
        (evil-goto-line)
        (evil-append-line 1))))

  (defun my-eshell-insert-beginning-of-line ()
    "Puts point to eshell-bol and enters insert mode."
    (interactive)
    (eshell-bol)
    (evil-insert-state t)))

(use-package company-shell
  :after eshell
  :config

  (add-hook 'eshell-mode-hook #'company-mode)
  (add-hook 'eshell-mode-hook #'my-eshell-hook))


;;   :init

(use-package rtags
  :functions (my-c-mode-hook)
  :defines (rtags-use-helm)
  :commands (my-c-mode-hook)
  :init
  (setq rtags-use-helm                 t
        rtags-display-result-backend   'helm
        rtags-enable-unsaved-reparsing t
        rtags-rc-log-enabled           t) ; Set to t to enable logging
  (setq-default c-basic-offset         4)

  ;; Use three hooks since c-mode-common-hook also applies to java-mode
  (add-hook 'c-mode-hook #'my-c-mode-hook)
  (add-hook 'c++-mode-common-hook #'my-c-mode-hook)
  (add-hook 'objc-mode-hook #'my-c-mode-hook)
  :config
  (use-package helm-rtags)
  (use-package flycheck-rtags)
  (defun my-c-mode-hook ()
    (flycheck-select-checker 'rtags))

  (defun my-rtags-switch-to-project ()
    "Set active project without finding a file."
    (interactive)
    (let ((projects nil)
          (project nil)
          (current ""))
      (with-temp-buffer
        (rtags-call-rc :path t "-w")
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (point-at-bol) (point-at-eol))))
            (cond ((string-match "^\\([^ ]+\\)[^<]*<=$" line)
                   (let ((name (match-string-no-properties 1 line)))
                     (setq projects (add-to-list 'projects name t))
                     (setq current name)))
                  ((string-match "^\\([^ ]+\\)[^<]*$" line)
                   (setq projects
                         (add-to-list 'projects
                                      (match-string-no-properties 1 line))))
                  (t)))
          (forward-line)))
      (setq project (completing-read
                     (format "RTags select project (current is %s): " current)
                     projects))
      (when project
        (with-temp-buffer
          (rtags-call-rc :path t "-w" project)))))

  (defun my-c-compile (arg)
    (interactive "P")
    (let ((compilation-read-command arg))
      (call-interactively 'projectile-compile-project)))

  (setq-mode-local c++-mode
                   (indent-tabs-mode                    . nil)
                   (tab-width                           . 4)
                   (flycheck-highlighting-mode          . nil)
                   (flycheck-check-syntax-automatically . nil)
                   (company-backends                    . '((company-rtags))))
  (setq-mode-local c-mode
                   (indent-tabs-mode                    . nil)
                   (tab-width                           . 4)
                   (flycheck-highlighting-mode          . nil)
                   (flycheck-check-syntax-automatically . nil))

  :general
  (general-define-key
    :states '(normal insert visual)
    :keymaps '(c++-mode-map c-mode-map)
    "M-." 'rtags-find-symbol-at-point
    "M-," 'rtags-location-stack-back)
  (space-leader
    :keymaps '(c++-mode-map c-mode-map)
    "p d"   'rtags-find-symbol-at-point
    "p b"   'rtags-location-stack-back
    "p r"   'rtags-rename-symbol
    "p u"   'rtags-find-references-at-point
    "p s t" 'rtags-symbol-type
    "p s i" 'rtags-symbol-info
    "p v"   'my-rtags-switch-to-project
    "p c"   'my-c-compile
    "m f"   'c-mark-function))

(use-package irony
  :init
  (add-hook 'c++-mode-hook 'irony-mode)
  (add-hook 'c-mode-hook 'irony-mode)
  (add-hook 'objc-mode-hook 'irony-mode)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options))

(use-package company-irony
  :after 'irony
  :config
  (setq-mode-local c++-mode
                   (company-backends . '((company-irony))))
  (setq-mode-local c-mode
                   (company-backends . '((company-irony)))))

(use-package lunchtime
  :ensure nil
  :load-path "~/projects/elisp/lunchtime"
  :commands (lunchtime-display-menus)
  :config

  ;; TTY
  (lunchtime-define-restaurant
   "https://api.ruoka.xyz/%Y-%m-%d"
   (mapcar
    (lambda (restaurant)
      `((name . ,(assoc-recursive restaurant 'name))
        (subrestaurants
         .
         ,(mapcar
           (lambda (subrestaurant)
             `((name . ,(assoc-recursive subrestaurant 'name))
               (menus . ,(mapcar
                          (lambda (meal)
                            `((name . ,(assoc-recursive meal 'name))
                              (prices . ,(assoc-recursive meal 'prices))
                              (menu . ,(mapcar
                                        (lambda (part)
                                          (assoc-recursive part 'name))
                                        (assoc-recursive meal 'contents)))))
                          (assoc-recursive subrestaurant 'meals)))))
           (assoc-recursive restaurant 'menus)))))

    (assoc-recursive lunchtime-response-data 'restaurants)))

  ;; Hermia 6
  (lunchtime-define-restaurant
   "https://www.sodexo.fi/ruokalistat/output/daily_json/9870/%Y/%m/%d/en"
   `(((name . ,(assoc-recursive lunchtime-response-data 'meta 'ref_title))
      (subrestaurants
       .
       (((name . "Lounas") ;; Sodexo has only one restaurant per menu item
         (menus . ,(mapcar
                    (lambda (item)
                      `((name . ,(assoc-recursive item 'category))
                        (prices . (,(assoc-recursive item 'price)))
                        (menu . (,(assoc-recursive item 'title_fi)))))
                    (assoc-recursive lunchtime-response-data 'courses)))))))))

  ;; Hermia 5
  (lunchtime-define-restaurant
   "https://www.sodexo.fi/ruokalistat/output/daily_json/134/%Y/%m/%d/en"
   `(((name . ,(assoc-recursive lunchtime-response-data 'meta 'ref_title))
      (subrestaurants
       .
       (((name . "Lounas") ;; Sodexo has only one restaurant per menu item
         (menus . ,(mapcar
                    (lambda (item)
                      `((name . ,(assoc-recursive item 'category))
                        (prices . (,(assoc-recursive item 'price)))
                        (menu . (,(assoc-recursive item 'title_fi)))))
                    (assoc-recursive lunchtime-response-data 'courses)))))))))
  
  :general
  (space-leader
    "l l" 'lunchtime-display-menus)
  (general-define-key
    :keymaps '(lunchtime-mode-map)
    :states '(normal)
    "l" 'lunchtime-next-day
    "h" 'lunchtime-previous-day
    "j" 'lunchtime-next-restaurant
    "k" 'lunchtime-previous-restaurant
    "q" 'lunchtime-close))

(use-package dired
  :ensure nil
  :init
  (setq wdired-allow-to-change-permissions t)
  :general
  (space-leader
    :keymaps '(dired-mode-map)
    "E" 'dired-toggle-read-only))

(use-package compilation
  :ensure nil
  :after helm
  :general
  (general-define-key
    :keymaps '(compilation-mode-map)
    "SPC" nil
    "h"   nil
    "g"   nil)

  ;; Compilation-mode maps need to be filled separately, since it overrides
  ;; most of the keybindings.
  (general-define-key
    :keymaps '(compilation-mode-map)
    ";" 'helm-find-files
    "'" 'helm-projectile-switch-project)
  (general-define-key
    :keymaps '(compilation-mode-map)
    :prefix "SPC"
    "b"   'helm-mini
    "x"   'helm-M-x
    "ö"   'helm-projectile
    "O"   'helm-occur
    "A"   'helm-apropos
    "w"   'save-buffer
    "SPC" 'ace-window
    "D"   'kill-this-buffer
    "s h" 'my-eshell-here
    "r"   'compilation-recompile
    "g"   'magit-status
    "0"   'delete-window
    "1"   'delete-other-windows
    "2"   'split-window-below
    "3"   'split-window-right))

(use-package json-mode)
(use-package gitignore-mode)
(use-package coffee-mode)
(use-package pug-mode
  :mode "\\.jade\\'")
(use-package stylus-mode)
(use-package markdown-mode)

(use-package neotree
  :general
  (space-leader
    "n t" 'neotree-projectile-action)
  :init
  (setq neo-window-width 45
        neo-theme 'ascii
        neo-hidden-regexp-list '("^\\.$" "^\\.\\.$" "\\.pyc$" "~$" "^#.*#$"
                                 "\\.elc$" "^\\.git"))
  :general
  (general-define-key
    :states '(normal)
    :keymaps '(neotree-mode-map)
    "C"        'neotree-change-root
    "U"        'neotree-select-up-node
    "r"        'neotree-refresh
    "o"        'neotree-enter
    "<return>" 'neotree-enter
    "i"        'neotree-enter-horizontal-split
    "s"        'neotree-enter-vertical-split
    "n"        'evil-search-next
    "N"        'evil-search-previous
    "m a"      'neotree-create-node
    "m c"      'neotree-copy-file
    "m d"      'neotree-delete-node
    "m m"      'neotree-rename-node
    "g g"      'evil-goto-first-line)
  :bind
  (("<f8>" . neotree-toggle)))

(use-package nxml-mode
  :mode "\\.xml\\'"
  :ensure nil
  :config
  (defun my-xml-format ()
    "Format an XML buffer with `xmllint'."
    (interactive)
    (shell-command-on-region (point-min) (point-max)
                             "xmllint -format -"
                             (current-buffer) t
                             "*Xmllint Error Buffer*" t))
  :general
  (space-leader
    :keymaps '(nxml-mode-map)
    "I" 'my-xml-format))

(use-package pdf-tools
  :defines (pdf-info-epdfinfo-program)
  :init
  (setq with-editor-emacsclient-executable (concat "/Applications/Emacs.app/"
                                                   "Contents/MacOS/bin/emacsclient")
        pdf-info-epdfinfo-program          "/usr/local/bin/epdfinfo"))

(use-package zoom-frm
  :init
  (define-key ctl-x-map [(control ?+)] 'zoom-in/out)
  (define-key ctl-x-map [(control ?-)] 'zoom-in/out)
  (define-key ctl-x-map [(control ?=)] 'zoom-in/out)
  (define-key ctl-x-map [(control ?0)] 'zoom-in/out))

(use-package pip-requirements
  :mode ("requirements.txt" . pip-requirements-mode))

;; Windows setup files.
(use-package iss-mode
  :mode ("\\.iss\\'" . iss-mode))

(use-package cmake-mode)

(use-package git-gutter
  :diminish git-gutter-mode
  :hook
  (prog-mode . git-gutter-mode)
  :config

  (set-face-attribute 'git-gutter:deleted nil
                      :height 10
                      :width 'ultra-condensed
                      :foreground (face-attribute 'error :foreground)
                      :background (face-attribute 'error :foreground))
  (set-face-attribute 'git-gutter:added nil
                      :height 10
                      :width 'ultra-condensed
                      :foreground
                      (face-attribute 'font-lock-string-face :foreground)
                      :background
                      (face-attribute 'font-lock-string-face :foreground))
  (set-face-attribute 'git-gutter:modified nil
                      :foreground "chocolate"
                      :background "chocolate")
  (set-face-attribute 'git-gutter:unchanged nil
                      :width 'ultra-condensed
                      :height 10)
  (set-face-attribute 'git-gutter:separator nil
                      :width 'ultra-condensed
                      :height 10)
  :general
  (space-leader
    "g d" 'git-gutter:popup-hunk
    "g u" 'git-gutter:revert-hunk))

(use-package js2-mode
  :mode "\\.js\\'"
  :init
  (setq js-indent-level               4
        js2-mode-show-parse-errors    nil
        js2-mode-show-strict-warnings nil)
  (setq-mode-local js2-mode
                   (indent-tabs-mode . nil)
                   (tab-width        . 4)
                   (company-backends . '((company-tern))))
  (add-hook 'js2-mode-hook #'js2-imenu-extras-mode)
  :general
  (space-leader
    :keymaps '(js2-mode-map)
    "p d" 'js2-jump-to-definition
    "p D" 'xref-find-definitions
    "p c" 'grunt-exec))

(use-package grunt
  :after js2-mode)

(use-package js2-refactor
  :after js2-mode
  :init
  (add-hook 'js2-mode-hook #'js2-refactor-mode)
  :config
  (space-leader
    :keymaps '(js2-mode-map)
    "p r r" 'js2r-rename-var)
  (general-define-key
    :keymaps '(js2-mode-map)
    "C->" 'js2r-forward-slurp
    "C-<" 'js2r-forward-barf))

(use-package ag)
(message "tes")

(use-package tern
  :after js2-mode
  :init
  (add-hook 'js2-mode-hook #'tern-mode))

(use-package xref-js2
  :after 'js2-mode
  :config
  (add-hook 'js2-mode-hook
    (lambda ()
      (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t))))

(use-package helm-xref
  :after xref-js2
  :init
  (setq xref-show-xrefs-function 'helm-xref-show-xrefs))


(use-package company-tern
  :after js2-mode
  :config
  (use-package tern))

;; Some fun, with vim bindings ofc.
(use-package 2048-game
  :config
  (general-define-key
    :keymaps '(2048-mode-map)
    :states '(normal)
    "h" '2048-left
    "j" '2048-down
    "k" '2048-up
    "l" '2048-right))


(with-eval-after-load 'gnus
  (add-hook 'gnus-group-mode-hook #'gnus-topic-mode)
  (general-define-key
    :keymaps '(gnus-group-mode-map
               gnus-summary-mode-map
               gnus-article-mode-map)
    "j" 'evil-next-line
    "k" 'evil-previous-line))

;; Eldoc, use in elisp buffers
(global-eldoc-mode -1)
(add-hook 'lisp-interaction-mode-hook (lambda () (eldoc-mode 1)))
(add-hook 'emacs-lisp-mode-hook (lambda () (eldoc-mode 1)))


(use-package swift-mode)
(use-package apples-mode
  :mode ("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))
(use-package flycheck-swift
  :after swift-mode)

(use-package request)
(use-package ox-jira)
(use-package language-detection)
(use-package ejira
  :load-path "~/projects/elisp/ejira"
  :after (org general helm)
  :defines (ejira-sprint-agenda)
  :ensure nil
  :defer nil
  :init
  (setq ejira-done-states                      '("Done")
        ejira-in-progress-states               '("In Progress" "In Review" "Testing")
        ejira-high-priorities                  '("High" "Highest")
        ejira-low-priorities                   '("Low" "Lowest")
        ejira-coding-system                    'utf-8

        epa-pinentry-mode                      'loopback
        org-tags-column                        -100
        org-clock-history-length               23
        org-agenda-restore-windows-after-quit  t
        org-clock-in-resume                    t
        org-drawers                            '("PROPERTIES" "LOGBOOK")
        org-clock-into-drawer                  t
        org-clock-out-remove-zero-time-clocks  t
        org-clock-out-when-done                t
        org-clock-persist                      t
        org-clock-persist-query-resume         nil
        org-clock-auto-clock-resolution        'when-no-clock-is-running
        org-clock-report-include-clocking-task t
        org-time-stamp-rounding-minutes        '(1 1)

        my-org-clock-title-length              10
        org-indirect-buffer-display            'other-window

        org-agenda-files                       '("~/projects/org")
        org-refile-targets                     '((nil              :maxlevel . 9)
                                                 (org-agenda-files :maxlevel . 9))

        org-use-fast-todo-selection t)

  :config
  (require 'ejira)
  (require 'org-agenda)
  (org-add-agenda-custom-command ejira-sprint-agenda)

  (defun my-guess-sprint-number ()
    "Guess the sprint number based on week number (assumes one week sprints)."
    (number-to-string (+ (string-to-number (format-time-string "%W")) 47)))

  (defun my-remove-empty-drawer-on-clock-out ()
    "Remove empty LOGBOOK drawers on clock out."
    (interactive)
    (save-excursion
      (beginning-of-line 0)
      (org-remove-empty-drawer-at (point))))

  (add-hook 'org-clock-out-hook 'my-remove-empty-drawer-on-clock-out 'append)
  (add-hook 'org-mode-hook #'org-indent-mode)
  :general
  (space-leader
    "j j"   'ejira-goto-issue
    "o j l" 'ejira-insert-link-to-current-issue
    "o j j" 'ejira-focus-on-clocked-issue
    "o j U" 'ejira-update-issues-in-active-sprint)
  (space-leader
    :keymaps '(org-mode-map)
    "o j c" 'ejira-add-comment
    "o j a" 'ejira-assign-issue
    "o j u" 'ejira-update-current-issue
    "o j n" 'ejira-focus-on-current-issue
    "o j p" 'ejira-progress-current-issue)

  ;; Some eviliation for agenda mode.
  (with-eval-after-load 'org-agenda
    (general-define-key
      :keymaps '(org-agenda-mode-map)
      "j"     'evil-next-line
      "k"     'evil-previous-line
      "g"     nil
      "g g"   'evil-goto-first-line
      "g r"   'org-agenda-redo-all
      "G"     'evil-goto-line)))

(use-package helm-ejira
  :load-path "~/projects/elisp/ejira"
  :ensure nil
  :after ejira
  :general
  (space-leader
    "J"     'helm-ejira
    "K"     'helm-ejira-sprint))

(use-package ejira-hourmarking
  :load-path "~/projects/elisp/ejira"
  :ensure nil
  :general
  (general-define-key
    :states '(normal)
    :keymaps '(ejira-hourlog-mode-map)
    "q" 'ejira-hourlog-quit)
  (space-leader
    "o j h" 'ejira-hourmarking-get-hourlog))


(use-package org-clock-convenience
  :ensure t
  :after (helm-ejira)
  :bind
  (:map org-agenda-mode-map
        ("<S-up>" . org-clock-convenience-timestamp-up)
        ("<S-down>" . org-clock-convenience-timestamp-down)
        ("F" . org-clock-convenience-fill-gap-both)))

(use-package org-clock-csv
  :config
  (defun my-row-format (plist)
    (mapconcat #'identity
                 `(,(plist-get plist ':start)
                   ,(plist-get plist ':end)
                   ,(plist-get plist ':key)
                   ,(org-clock-csv--escape (plist-get plist ':task)))
               ","))

  (setq org-clock-csv-header "start,end,key,task"
        org-clock-csv-row-fmt #'my-row-format))

(use-package org-bullets
  :after 'org
  :hook
  (org-mode . org-bullets-mode))

(use-package org-fancy-priorities
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("⬆" "-" "⬇")
        org-priority-faces        '((?A . (:foreground "#c23127" :weight "bold"))
                                    (?B . (:foreground "#d26937"))
                                    (?C . (:foreground "#2aa889")))))

(use-package lsp-intellij
  :ensure nil
  :load-path "~/projects/git/github/intellij-lsp-server")

(use-package company-lsp
  :init
  (add-hook 'prog-major-mode #'lsp-prog-major-mode-enable))

(use-package jinja2-mode)
(use-package yaml-mode)

(use-package clang-format
  :config
  (defun my-clang-format-region-or-buffer ()
    "Format active region, or the whole buffer if no region is active."
    (interactive)
    (if (region-active-p)
        (call-interactively #'clang-format-region)
      (clang-format-buffer)))
  :general
  (space-leader
    :keymaps '(c++-mode-map c-mode-map objc-mode-map)
    "p f" 'my-clang-format-region-or-buffer))

(use-package web-beautify
  :config
  ;; Set e4x support on.
  (setq web-beautify-args '("-f" "-" "-X"))

  (defun my-js-format-region-or-buffer ()
    "Format active region, or the whole buffer if no region is active."
    (interactive)
    (if (region-active-p)
        (call-interactively #'web-beautify-js)
      (web-beautify-js-buffer)))
  :general
  (space-leader
    :keymaps '(rjsx-mode-map js2-mode-map)
    "p f" 'my-js-format-region-or-buffer))


(use-package editorconfig
  :diminish editorconfig-mode
  :config
  (editorconfig-mode 1))

(use-package opencl-mode)
(use-package csharp-mode)
;; Local Variables:
;; byte-compile-warnings: (not free-vars noruntime unresolved)
;; End:
;;; init.el ends here
