;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2022 Pierre Neidhardt <mail@ambrevar.xyz>
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

(define-module (nongnu packages chromium)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (nonguix build-system binary)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define-public chromium-embedded-framework
  (let ((git-revision "d0bbcbb")
        (chromium-version "103.0.5060.114")
        (arch (match (or (%current-target-system) (%current-system))
                ("aarch64-linux" "linuxarm64")
                ("armhf-linux" "linuxarm")
                (_ "linux64"))))
    (package
      (name "chromium-embedded-framework")
      (version "103.0.9")
      (source (origin
                (method url-fetch)
                (uri (string-append
                      "https://cef-builds.spotifycdn.com/cef_binary_"
                      version
                      "+g" git-revision
                      "+chromium-" chromium-version
                      "_" arch "_minimal.tar.bz2"))
                (sha256
                 (base32
                  "143x0jmasl4z16bkxlrbz874chd9x9xpc5qylb9h7j80gfcrzlsi"))))
      (build-system binary-build-system)
      (arguments
       `(#:patchelf-plan
         `(("Release/libcef.so" ("alsa-lib"
                                 "at-spi2-atk"
                                 "at-spi2-core"
                                 "atk"
                                 "cairo"
                                 "cups"
                                 "dbus"
                                 "expat"
                                 "gcc"
                                 "glib"
                                 "glibc"
                                 "gtk+"
                                 "libdrm"
                                 "libx11"
                                 "libxcb"
                                 "libxcomposite"
                                 "libxdamage"
                                 "libxext"
                                 "libxfixes"
                                 "libxkbcommon"
                                 "libxrandr"
                                 "libxshmfence"
                                 "mesa"
                                 "nspr"
                                 ("nss" "/lib/nss")
                                 "pango")))
         #:install-plan
         `(("Release/libcef.so" "lib/")
           ("libcef_dll_wrapper/libcef_dll_wrapper.a" "lib/")
           ("Release/" "share/cef/"
            #:include-regexp (".*.bin"))
           ("Resources/" "share/cef/")
           ("include" "./"))
         #:phases
         (modify-phases %standard-phases
           (add-before 'install 'build
             (lambda _
               (invoke "cmake" "-DCMAKE_BUILD_TYPE=Release" ".")
               (invoke "make" "libcef_dll_wrapper"))))))
      (inputs
       (list
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        `(,gcc "lib")
        glib
        gtk+
        libdrm
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libxshmfence
        mesa
        nspr
        nss
        pango))
      (native-inputs
       ;; FIXME: We specify glibc here so that Cmake does not pick the wrong
       ;; architecture (e.g. glibc32 while on a 64-bit system).
       ;; The build system could be smarter.
       (list glibc
             cmake))
      (synopsis "Embed Chromium-based browsers in other applications")
      (supported-systems '("armhf-linux" "aarch64-linux" "x86_64-linux"))
      (description "This library provides a simple framework for embedding
Chromium-based browsers in other applications.

Unlike the Chromium project itself, which focuses mainly on Google Chrome
application development, CEF focuses on facilitating embedded browser use
cases in third-party applications.  CEF insulates the user from the underlying
Chromium and Blink code complexity by offering production-quality stable
APIs.

Some use cases for CEF include:

@itemize
@item Embedding an HTML5-compliant Web browser control in an existing native
application.
@item Creating a light-weight native \"shell\" application that hosts a user
interface developed primarily using Web technologies.
@item Rendering Web content “off-screen” in applications that have their own
custom drawing frameworks.
@item Acting as a host for automated testing of existing Web properties and
applications.
@end itemize\n")
      (home-page "https://bitbucket.org/chromiumembedded/cef")
      (license license:bsd-3))))
