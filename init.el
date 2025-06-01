(cl-pushnew "/Library/TeX/texbin" exec-path :test #'equal)
(cl-pushnew "/usr/bin/" exec-path :test #'equal)
(setq latex-run-command "pdflatex")
(setq latex-run-command "languagetool")
(setq package-enable-at-startup nil)

(use-package org
  :ensure t
  :demand t
  :config
  (add-hook 'org-mode-hook #'org-indent-mode))
(with-eval-after-load 'org
  (org-babel-load-file (expand-file-name "~/.emacs.d/settings.org")))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("e8ceeba381ba723b59a9abc4961f41583112fc7dc0e886d9fc36fa1dc37b4079"
     "e1f4f0158cd5a01a9d96f1f7cdcca8d6724d7d33267623cc433fe1c196848554"
     "7964b513f8a2bb14803e717e0ac0123f100fb92160dcf4a467f530868ebaae3e"
     "6a5584ee8de384f2d8b1a1c30ed5b8af1d00adcbdcd70ba1967898c265878acf"
     "c5878086e65614424a84ad5c758b07e9edcf4c513e08a1c5b1533f313d1b17f1"
     "8d3ef5ff6273f2a552152c7febc40eabca26bae05bd12bc85062e2dc224cde9a"
     "691d671429fa6c6d73098fc6ff05d4a14a323ea0a18787daeb93fde0e48ab18b"
     "7c28419e963b04bf7ad14f3d8f6655c078de75e4944843ef9522dbecfcd8717d"
     "3c08da65265d80a7c8fc99fe51df3697d0fa6786a58a477a1b22887b4f116f62"
     "e14884c30d875c64f6a9cdd68fe87ef94385550cab4890182197b95d53a7cf40"
     "9e36779f5244f7d715d206158a3dade839d4ccb17f6a2f0108bf8d476160a221"
     "d6b934330450d9de1112cbb7617eaf929244d192c4ffb1b9e6b63ad574784aad"
     default))
 '(package-selected-packages
   '(all-the-icons avy blacken doom-themes eat ef-themes ekg elpy
                   embark-consult evil-nerd-commenter expand-region
                   flycheck-languagetool flycheck-pyflakes helpful
                   hl-todo iter2 languagetool lsp-ivy lsp-jedi
                   lsp-mode lsp-pyright lsp-ui magit marginalia
                   multiple-cursors orderless org-download org-fragtog
                   projectile promise python-lsp-server python-mode
                   pyvenv-auto rainbow-delimiters tempel-collection
                   tree-sitter-langs vertico))
 '(package-vc-selected-packages
   '((copilot :url "https://github.com/copilot-emacs/copilot.el" :branch
              "main"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
