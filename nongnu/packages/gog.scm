;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2019, 2020 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2021-2022 Timotej Lazar <timotej.lazar@araneo.si>
;;; Copyright © 2023 Eidvilas Markevičius <markeviciuseidvilas@gmail.com>

(define-module (nongnu packages gog)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages man)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system qt)
  #:use-module ((guix licenses) #:prefix license:))

(define-public lgogdownloader
  (package
    (name "lgogdownloader")
    (version "3.11")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Sude-/lgogdownloader.git")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0mcwl6vfyy91sq1816j4v3lhf06dz1rr58hsq8hqx217z102s86d"))))
    (build-system qt-build-system)
    (arguments
     `(#:configure-flags '("-DUSE_QT_GUI=ON")
       #:tests? #f))                    ; no tests
    (inputs
     (list boost
           curl
           htmlcxx
           jsoncpp
           liboauth
           qtbase-5
           qtdeclarative-5
           qtwebchannel-5
           qtwebengine-5
           rhash
           tinyxml2
           zlib))
    (native-inputs
     (list help2man
           pkg-config))
    (home-page "https://sites.google.com/site/gogdownloader/")
    (synopsis "Downloader for GOG.com files")
    (description "LGOGDownloader is a client for the GOG.com download API,
allowing simple downloads and updates of games and other files from GOG.com.")
    (license license:wtfpl2)))
