;;;; configuration-r.asd

(asdf:defsystem #:configuration-r
  :description "Describe configuration-r here"
  :author "Your Name <your.name@example.com>"
  :license  "Specify license here"
  :version "0.1.1"
  :serial t
  :depends-on (#:xlog)
  :components ((:file "configuration-r-pkg")
               (:file "configuration-r")))
