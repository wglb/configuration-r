;;;; configuration-r-test.asd

(asdf:defsystem #:configuration-r-test
  :description "Tests for the configuration-r library"
  :author "wgl@ciex-security.com"
  :license  "GPL"
  :version "1.2.4"
  :serial t
  :depends-on (#:configuration-r #:fiveam)
  :components ((:file "configuration-r-test-pkg")
               (:module "tests"
                :components ((:file "main-config-r-test"))))
  :perform (asdf:test-op (o c)
             (uiop:symbol-call :configuration-r-test :run-tests-with-cleanup)))


