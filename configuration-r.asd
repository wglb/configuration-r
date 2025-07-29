;;;; configuration-r.asd

(asdf:defsystem #:configuration-r
  :description "Describe configuration-r here"
  :author "wgl@ciex-security.com"
  :license  "GPL"
  :version "0.2.1"
  :serial t
  :depends-on (#:xlog)
  :components ((:file "configuration-r-pkg")
               (:file "configuration-r"))
  ;; Add this section for testing
  :defsystem-depends-on (#:fiveam) ;; Ensure FiveAM is available when defining the system
  :in-order-to ((asdf:test-op (asdf:test-op #:configuration-r-test)))) ;; Changed system name from #:configuration-r/test

