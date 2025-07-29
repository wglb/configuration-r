;;;; configuration-r-test.asd

(asdf:defsystem #:configuration-r-test ;; Changed system name from #:configuration-r/test
  :description "Tests for the configuration-r library"
  :author "Your Name <your.name@example.com>" ;; Update with your name
  :license "Specify license here" ;; Update with your license
  :version "0.1.0"
  :depends-on (#:configuration-r #:fiveam) ;; Depends on your library and FiveAM
  :components ((:module "tests"
                :components ((:file "main"))))
  :perform (asdf:test-op (op c) (uiop:symbol-call :fiveam :run! :configuration-r-tests)))

