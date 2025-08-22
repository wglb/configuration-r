;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target)
  "Helper for FIND-FILE-IN-PARENT. Recursively searches for TARGET starting from PN and going up."
  (if pn
      (let ((tpn (merge-pathnames target pn)))
        (debugc 5 (xlogntf "ffip0: target ~s pn ~s -> tpn ~s" target pn tpn))
        (if (probe-file tpn)
            tpn
            (let ((npn (pathname-parent-directory-pathname pn)))
              (debugc 5 (xlogntf "ffip0: no file in ~s, trying parent ~s" pn npn))
              ;; Stop recursion if we've reached the root or an unchangeable parent (e.g., /)
              (if (pathname-equal npn pn)
                  nil
                  (find-file-in-parent0 npn target)))))))

(defun find-file-in-parent (pn target)
  "Searches for TARGET file in PN and its parent directories.
   Returns the pathname of the found file or NIL."
  (let* ((initial-pn (ensure-directory-pathname pn))
         (ans (find-file-in-parent0 initial-pn target)))
	(debugc 5 (xlogntf "ffip: pn ~s target ~s -> ~s" pn target ans))
	ans))

(defun read-config-file (filename &key (debug nil))
  "Reads a config file and returns its content as an alist.
   Returns NIL if the file doesn't exist or an error occurs."
  (debugc 5 (xlogntf "read-config-file: reading ~s" filename))
  (handler-case
      (with-open-file (stream filename :direction :input)
        (let ((data (read stream)))
          (if debug (xlogntf "read-config-file: read ~s" data))
          data))
    (error (e)
      (if debug (xlogntf "read-config-file: Error reading ~a: ~a" filename e))
      nil)))

(defun get-config0 (pn fn ty property &key (debug nil))
  "Internal helper to get a property from a configuration file.
   Searches for a file named FN.TY starting from directory PN and going up."
  (let* ((filename (make-pathname :name fn :type ty))
         (config-file (find-file-in-parent pn filename)))
    (if debug
        (xlogntf "gc0: pn ~s filename ~s config-file ~s" pn filename config-file))
    (when config-file
      (let ((alist (read-config-file config-file :debug debug)))
        (when alist
          (cdr (assoc property alist)))))))

(defun get-config (filename property &key (dir nil) (debug nil))
  "Gets a property from a configuration file named FILENAME.
   Searches up from the directory DIR (or current directory if DIR is nil)."
  (let* ((file-pathname (ensure-pathname filename :want-pathname t))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname))
         (initial-dir-pathname (cond
                                 (dir (ensure-directory-pathname dir))
                                 (t (getcwd)))))
    ;; Correctly create the full pathname and then check for its existence.
    (let ((full-path (merge-pathnames file-pathname initial-dir-pathname)))
        (if (and (probe-file full-path) fn ty)
            (handler-case
                (let ((canonical-dir (truename full-path)))
                  (get-config0 (pathname-directory-pathname canonical-dir) fn ty property :debug debug))
              (error (e)
                (xlogntf "get-config: error ~e in getting ~a from ~a" e property filename)
                nil))
            (progn
                (if debug (xlogntf "get-config: File does not exist or has no name/type: ~a" filename))
                nil)))))

(defun get-config1 (filename property &key (debug nil))
  "Gets a config property from a specific file path.
   This version is simplified to avoid the issues with get-config's directory handling."
  (let* ((file-pathname (ensure-pathname filename :want-pathname t))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname)))
    (if (and (probe-file file-pathname) fn ty)
        (let ((ans (get-config0 (pathname-directory-pathname file-pathname) fn ty property :debug debug)))
          (if debug
              (xlogntf "gc1: filename ~s fn ~s property ~s val ~s" filename fn property ans))
          ans)
        (progn
          (if debug
              (xlogntf "get-config1: File does not exist or has no name/type: ~a" filename))
          nil))))
