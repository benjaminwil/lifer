(use-modules (guix)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages ruby)
             (gnu packages serialization))

(package
 (name "ruby-lifer-dev")
 (version "0.12.4-git")
 (source #f)
 (build-system gnu-build-system)
 (inputs
  (append (list ruby libyaml)))
 (synopsis "Another Ruby-based static website generator")
 (description
  "A ruby-based static website generator focused on extensibility and having
  few dependencies.")
 (home-page "https://github.com/benjaminwil/lifer")
 (license license:expat))
