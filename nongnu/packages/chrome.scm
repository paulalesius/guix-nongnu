;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2022 Giacomo Leidi <goodoldpaul@autistici.org>
;;; Copyright © 2022 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2022 Jonathan Brielmaier <jonathan.brielmaier@web.de>
;;;
;;; This file is not part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (nongnu packages chrome)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (nonguix build-system binary)
  #:use-module (nonguix licenses)
  #:use-module (ice-9 string-fun))

(define-public (make-google-chrome repo version hash)
  (let* ((name (string-append "google-chrome-" repo))
         (appname (if (string=? repo "stable")
                      "chrome"
                      (string-replace-substring name "google-" ""))))
    (package
     (name name)
     (version version)
     (source (origin
               (method url-fetch)
               (uri
                (string-append
                 "https://dl.google.com/linux/chrome/deb/pool/main/g/"
                 name "/" name "_" version "-1_amd64.deb"))
               (sha256
                (base32 hash))))
     (build-system binary-build-system)
     (arguments
      (list
        ;; almost 300MB, faster to download and build from Google servers
        #:substitutable? #f
        #:patchelf-plan
         #~(let ((patchelf-inputs
                   '("alsa-lib" "at-spi2-atk" "at-spi2-core" "atk" "cairo" "cups"
                     "dbus" "expat" "fontconfig-minimal" "gcc" "gdk-pixbuf" "glib"
                     "gtk" "libdrm" "libnotify" "libsecret" "libx11" "libxcb"
                     "libxcomposite" "libxcursor" "libxdamage" "libxext" "libxfixes"
                     "libxi" "libxkbcommon" "libxkbfile" "libxrandr" "libxrender"
                     "libxtst" "mesa" "nspr" "pango" "zlib"))
                 (path (string-append "opt/google/" #$appname "/")))
             (map (lambda (file)
                    (cons (string-append path file) (list patchelf-inputs)))
                  '("chrome"
                    "chrome-sandbox"
                    "chrome_crashpad_handler"
                    "nacl_helper"
                    "libEGL.so"
                    "libGLESv2.so")))
        #:install-plan
         #~'(("opt/" "/share")
             ("usr/share/" "/share"))
        #:phases
         #~(modify-phases %standard-phases
             (add-after 'unpack 'unpack-deb
               (lambda* (#:key inputs #:allow-other-keys)
                 (invoke "ar" "x" #$source)
                 (invoke "rm" "-v" "control.tar.xz"
                                   "debian-binary"
                                   (string-append "google-chrome-" #$repo "_"
                                                  #$version
                                                  "-1_amd64.deb"))
                 (invoke "tar" "xf" "data.tar.xz")
                 (invoke "rm" "-vrf" "data.tar.xz" "etc")))
             (add-before 'install 'patch-assets
               ;; Many thanks to
               ;; https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/browsers/google-chrome/default.nix
               (lambda _
                 (let* ((bin (string-append #$output "/bin"))
                        (share (string-append #$output "/share"))
                        (opt "./opt")
                        (usr/share "./usr/share")
                        (old-exe (string-append "/opt/google/" #$appname "/google-" #$appname))
                        (exe (string-append bin "/google-" #$appname)))
                   ;; This allows us to override CHROME_WRAPPER later.
                   (substitute* (string-append opt "/google/" #$appname "/google-" #$appname)
                     (("CHROME_WRAPPER") "WRAPPER"))
                   (substitute* (string-append usr/share "/applications/google-" #$appname ".desktop")
                     (("^Exec=.*") (string-append "Exec=" exe "\n")))
                   (substitute* (string-append usr/share "/gnome-control-center/default-apps/google-" #$appname ".xml")
                     ((old-exe) exe))
                   (substitute* (string-append usr/share "/menu/google-" #$appname ".menu")
                     (("/opt") share)
                     ((old-exe) exe))
                   #t)))
             (add-after 'install 'install-wrapper
              (lambda _
                (let* ((bin (string-append #$output "/bin"))
                       (exe (string-append bin "/google-" #$appname))
                       (share (string-append #$output "/share"))
                       (chrome-target (string-append share "/google/" #$appname "/google-" #$appname)))
                  (mkdir-p bin)
                  (symlink chrome-target exe)
                  (wrap-program exe
                    `("FONTCONFIG_PATH" ":" prefix
                      (,(string-join
                         (list
                          (string-append #$(this-package-input "fontconfig-minimal") "/etc/fonts")
                          #$output)
                         ":")))
                    `("LD_LIBRARY_PATH" ":" prefix
                      (,(string-join
                         (list
                          (string-append #$(this-package-input "nss") "/lib/nss")
                          (string-append #$(this-package-input "eudev") "/lib")
                          (string-append #$(this-package-input "gcc") "/lib")
                          (string-append #$(this-package-input "mesa") "/lib")
                          (string-append #$(this-package-input "libxkbfile") "/lib")
                          (string-append #$(this-package-input "zlib") "/lib")
                          (string-append #$(this-package-input "libsecret") "/lib")
                          (string-append #$(this-package-input "sqlcipher") "/lib")
                          (string-append #$(this-package-input "libnotify") "/lib")
                          (string-append #$(this-package-input "libdrm") "/lib")
                          (string-append #$(this-package-input "pipewire") "/lib")
                          #$output)
                         ":")))
                    '("CHROME_WRAPPER" = (#$appname)))))))))
     (native-inputs (list tar))
     (inputs
      (list alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            eudev
            expat
            fontconfig
            `(,gcc "lib")
            glib
            gtk
            libdrm
            libnotify
            librsvg
            libsecret
            libx11
            libxcb
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxkbcommon
            libxkbfile
            libxrandr
            libxrender
            libxtst
            mesa
            nspr
            nss
            pango
            pipewire-0.3
            sqlcipher
            zlib))
     (synopsis  "Freeware web browser")
     (supported-systems '("x86_64-linux"))
     (description "Google Chrome is a cross-platform web browser developed by Google.")
     (home-page "https://www.google.com/chrome/")
     (license (nonfree "https://www.google.com/intl/en/chrome/terms/")))))

(define-public google-chrome-stable
  (make-google-chrome "stable" "107.0.5304.68" "1x9svz5s8fm2zhnpzjpqckzfp37hjni3nf3pm63rwnvbd06y48ja"))

(define-public google-chrome-beta
  (make-google-chrome "beta" "108.0.5359.40" "1zd8dbs5w2vdnck91pqiymwa2bnz53jgjbg89cr96y6jwab3i4b0"))

(define-public google-chrome-unstable
  (make-google-chrome "unstable" "109.0.5410.0" "0ljhc5lqdy01apzyj96xzl931d904i37x62257s1h35w0j78mps0"))
